/*
PARTICLE_RENDER_FAST.HLSL
Copyright (c) Microsoft Corporation, 2009. all rights reserved.
2/20/2009 4:15:31 PM (ctchou)
*/


struct s_fast_particle_interpolators
{
	float4 m_position0	:SV_Position;		// xyz, ?
	float4 m_color0		:COLOR0;			// rgb tint, alpha
	float4 m_color1		:COLOR1;			// color offset, ?
	float4 m_misc0		:TEXCOORD0;		// uv, depth, black_point
};

#define M_DEPTH	m_misc0.z
#define M_TEXCOORD m_misc0.xy
#define M_COLOR m_color0.rgb
#define M_ALPHA m_color0.a
#define M_BLACK_POINT m_misc0.w
#define M_COLOR_ADD m_color1.rgb

#ifdef VERTEX_SHADER

s_fast_particle_interpolators static_default_vs(
#if DX_VERSION == 11
	in uint instance_id : SV_InstanceID,
	in uint vertex_id : SV_VertexID
#else
	int index : INDEX 
#endif	
	)
{
#if DX_VERSION == 11
	#if IS_VERTEX_TYPE(s_particle_vertex)
		uint quad_index = (vertex_id ^ ((vertex_id & 2) >> 1));	

		s_particle_vertex IN;
		int index = (instance_id * 4) + quad_index + particle_index_range.x;
		IN.address = 0;
	#elif IS_VERTEX_TYPE(s_particle_model_vertex)
		s_particle_vertex IN;
		int index = (instance_id * particle_index_range.y) + vertex_id + particle_index_range.x;
	#endif
#endif


	s_fast_particle_interpolators OUT;

	OUT.m_position0.xyzw=	float4(0.0f, 0.0f, 0.0f, 0.0f);
	OUT.m_color0=			float4(0.0f, 0.0f, 0.0f, 0.0f);
	OUT.m_color1=			float4(0.0f, 0.0f, 0.0f, 0.0f);
	OUT.m_misc0=			float4(0.0f, 0.0f, 0.0f, 0.0f);

#if (! defined(pc)) || (DX_VERSION == 11)
	// Break the input index into a instance index and a vert index within the primitive.
	int instance_index = round((index + 0.5f)/ g_render_state.m_vertex_count - 0.5f);	// This calculation is approximate (hence the 'round')
	int vertex_index = index - instance_index * g_render_state.m_vertex_count;	// This calculation is exact
	
	s_particle_state STATE= read_particle_state_fast(instance_index);
	
	// Kill timed-out particles...
	if (STATE.m_age >= 1.0f || STATE.m_color.w== 0.0f)		// early out if particle is dead or transparent.
	{
		OUT.m_position0.xyzw = hidden_from_compiler.xxxx;	// NaN
		OUT.m_color0= float4(0.0f, 0.0f, 0.0f, 0.0f);
		OUT.m_misc0= float4(0.0f, 0.0f, 0.0f, 0.0f);
	}
	else
	{
		// Precompute rotation value
		float rotation= STATE.m_physical_rotation + STATE.m_manual_rotation;
		
		// Compute vertex inputs which depend whether we are a billboard or a mesh particle
		float3 vertex_pos;
		float2 vertex_uv;
		float3 vertex_normal;
		float3x3 vertex_orientation;
		
#if	IS_VERTEX_TYPE(s_particle_model_vertex)		
		{
			// $TODO  remove animated frame?
			float variant= compute_variant(STATE.m_animated_frame + STATE.m_manual_frame, g_all_mesh_variants.m_mesh_variant_count, false, false);
//				TEST_BIT(g_render_state.m_animation_flags,_frame_animation_one_shot_bit), 
//				TEST_BIT(g_render_state.m_animation_flags,_can_animate_backwards_bit) && TEST_BIT(256*STATE.m_random.z,0));
			int variant_index0= floor(variant%g_all_mesh_variants.m_mesh_variant_count);
			vertex_index= min(	vertex_index, 
								g_all_mesh_variants.m_mesh_variants[variant_index0].m_mesh_variant_end_index - g_all_mesh_variants.m_mesh_variants[variant_index0].m_mesh_variant_start_index);
			vertex_index+= g_all_mesh_variants.m_mesh_variants[variant_index0].m_mesh_variant_start_index;
		
			float4 pos_sample;
			float4 uv_sample;
			float4 normal_sample;
#ifdef xenon			
			asm {
				vfetch pos_sample, vertex_index, position
				vfetch uv_sample, vertex_index, texcoord
				vfetch normal_sample, vertex_index, normal
			};
#elif DX_VERSION == 11
			uint offset = vertex_index * 32;

			pos_sample = float4(asfloat(mesh_vertices.Load3(offset)), 0);
			uv_sample = float4(asfloat(mesh_vertices.Load2(offset + 12)), 0, 0);
			normal_sample = float4(asfloat(mesh_vertices.Load3(offset + 20)), 0);			
#endif
			vertex_pos=		pos_sample.xyz * Position_Compression_Scale.xyz + Position_Compression_Offset.xyz;
			vertex_uv=		uv_sample.xy * UV_Compression_Scale_Offset.xy + UV_Compression_Scale_Offset.zw;
			vertex_normal=	normal_sample.xyz;
			vertex_orientation= matrix3x3_rotation_from_axis_and_angle(STATE.m_axis, _2pi*rotation);
		}
#else
		{
			float4x2 shift = {{0.0f, 0.0f}, {1.0f, 0.0f}, {1.0f, 1.0f}, {0.0f, 1.0f}, };
			vertex_pos= float3(shift[vertex_index] * g_sprite.m_corner.zw + g_sprite.m_corner.xy, 0.0f);			// WARNING: WATERFALL --- we can hack this instead
			vertex_uv= shift[vertex_index];
			vertex_normal= float3(0.0f, 0.0f, 1.0f);
			float rotsin, rotcos;
			sincos(_2pi*rotation, rotsin, rotcos);
			vertex_orientation=		float3x3(float3(rotcos, rotsin, 0.0f), float3(-rotsin, rotcos, 0.0f), float3(0.0f, 0.0f, 1.0f));
		}
#endif
	
		// Transform from local space to world space
		float3 position= mul(local_to_world, float4(STATE.m_position, 1.0f));
		
//		float3 velocity= mul((float3x3)local_to_world, STATE.m_velocity);
		
		// Compute the vertex position within the plane of the sprite
		float3 planar_pos= vertex_pos;
		float particle_scale= STATE.m_size;
//		float3 relative_velocity= velocity;
//		float aspect= STATE.m_aspect;	
//		planar_pos.x*= aspect;
		
		// Transform from sprite plane to world space.
		float3x3 plane_basis= mul(vertex_orientation, billboard_basis(position, float3(1.0f, 0.0f, 0.0f), true));	// in world space
		
		float3x3 vertex_basis= plane_basis;
		position.xyz += mul(planar_pos, plane_basis) * particle_scale;
		
		// Transform from world space to clip space. 
		OUT.m_position0= mul(float4(position, 1.0f), View_Projection);
		float depth= dot(Camera_Forward, position.xyz-Camera_Position);
		OUT.M_DEPTH= depth;
		float3 normal=	mul(vertex_normal, vertex_basis);			// corresponds to vertex normal
//		OUT.m_normal= mul(vertex_normal, vertex_basis);			// corresponds to vertex normal
		
		// Compute vertex texcoord
//		OUT.m_texcoord_billboard= vertex_uv;
		float2 uv_scroll= g_render_state.m_uv_scroll_rate * g_render_state.m_game_time;
		float uv_scale0= 1.0f;
		
		float frame= compute_variant(STATE.m_animated_frame + STATE.m_manual_frame, g_all_sprite_frames.m_sprite_frame_count, false, false);
//			TEST_BIT(g_render_state.m_animation_flags,_frame_animation_one_shot_bit), 
//			TEST_BIT(g_render_state.m_animation_flags,_can_animate_backwards_bit) && TEST_BIT(256*STATE.m_random.z,0));
		int frame_index0= floor(frame%g_all_sprite_frames.m_sprite_frame_count);

//		IF_CATEGORY_OPTION(frame_blend, off)
//		{
//			OUT.m_texcoord_sprite1= float2(0, 0);
//			OUT.m_frame_blend= 0;
//		}
//		else
//		{
//			int frame_index1= floor((frame+1)%g_all_sprite_frames.m_sprite_frame_count);
//			OUT.m_frame_blend= frac(frame);
//			uv_scale0= 1.0f/lerp(starting_uv_scale, ending_uv_scale, (1.0f + OUT.m_frame_blend)/2.0f);
//			float uv_scale1= 1.0f/lerp(starting_uv_scale, ending_uv_scale, (0.0f + OUT.m_frame_blend)/2.0f);
//			OUT.m_texcoord_sprite1= frame_texcoord(g_all_sprite_frames.m_sprite_frames[frame_index1], vertex_uv, uv_scroll, uv_scale1);
//		}
		OUT.M_TEXCOORD= vertex_uv;	// frame_texcoord(g_all_sprite_frames.m_sprite_frames[frame_index0], vertex_uv, uv_scroll, uv_scale0);

		// Compute particle color
		OUT.M_COLOR= STATE.m_color.xyz * STATE.m_initial_color.xyz * STATE.m_intensity * exp2(STATE.m_initial_color.w);
		OUT.M_COLOR_ADD= 0.0f;

		IF_CATEGORY_OPTION(blend_mode, multiply)
		{
		}
		else if (BLEND_MODE_SELF_ILLUM)
		{
			OUT.M_COLOR*= V_ILLUM_EXPOSURE;
		}
		else
		{
			OUT.M_COLOR*= v_exposure.x;
		}
		IF_CATEGORY_OPTION(self_illumination, constant_color)
		{
			OUT.M_COLOR_ADD += self_illum_color.xyz * V_ILLUM_EXPOSURE; 
		}
		IF_CATEGORY_OPTION(fog, on)	// fog
		{
			float3 extinction, inscatter;
			compute_scattering(Camera_Position, position.xyz, extinction, inscatter);
			OUT.M_COLOR*= extinction;
			OUT.M_COLOR_ADD+= inscatter * v_exposure.x;
		}
		IF_CATEGORY_OPTION(lighting, per_vertex_ravi_order_0)
		{
			float4 sh_lighting_coefficients[10]=
			{
				v_lighting_constant_0, 
				v_lighting_constant_1, 
				v_lighting_constant_2, 
				v_lighting_constant_3, 
				v_lighting_constant_4, 
				v_lighting_constant_5, 
				v_lighting_constant_6, 
				v_lighting_constant_7, 
				v_lighting_constant_8, 
				v_lighting_constant_9 
			}; 
			OUT.M_COLOR *= ravi_order_0(normal, sh_lighting_coefficients);
		}
		IF_CATEGORY_OPTION(lighting, per_vertex_ambient)
		{
			OUT.M_COLOR.rgb *= v_lighting_constant_3.rgb;
		}

		// Compute particle alpha
		OUT.M_ALPHA= STATE.m_color.w;
		if (TEST_BIT(g_render_state.m_appearance_flags,_intensity_affects_alpha_bit))
		{
			OUT.M_ALPHA *= STATE.m_intensity;
		}
		if (!g_render_state.m_first_person)		// near fade
		{
			OUT.M_ALPHA *= saturate(g_render_state.m_near_range * (depth - g_render_state.m_near_cutoff));
		}
		if (TEST_BIT(g_render_state.m_appearance_flags,_fade_near_edge_bit))
		{
			// Fade to transparent when billboard is edge-on ... but independent of camera orientation
			float3 camera_to_vertex= normalize(position.xyz-Camera_Position);
			float billboard_angle= _half_pi-acos(abs(dot(camera_to_vertex, normal)));
			OUT.M_ALPHA *= saturate(g_render_state.m_edge_range * (billboard_angle - g_render_state.m_edge_cutoff));
		}
		OUT.M_BLACK_POINT= saturate(STATE.m_black_point);
//		OUT.m_palette= TEST_CATEGORY_OPTION(albedo, diffuse_only)
//			? 0.0f 
//			: frac(STATE.m_palette_v);
			
		// extra kill test ... not strictly correct since other verts in the quad might be alive
		if (!IS_VERTEX_TYPE(s_particle_model_vertex))
		{
			if (OUT.M_ALPHA== 0.0f)
			{
				OUT.m_position0.xyzw = hidden_from_compiler.xxxx;	// NaN
			}
		}
	}
#else	//#ifndef pc
#endif	//#ifndef pc #else

    return OUT;
}
#endif	//#ifdef VERTEX_SHADER


#ifdef PIXEL_SHADER

#if (! defined(pc)) || (DX_VERSION == 11)
float2 compute_fast_normalized_distortion(float2 screen_coords, float2 blended, float depth_fade, float depth, float alpha)
{
	blended.xy= -blended.xy;

	float2 displacement= blended.xy*screen_constants.z*alpha*depth_fade;
//	float2x2 billboard_basis= float2x2(IN.m_tangent.xy, IN.m_binormal.xy);
//	float2 frame_displacement= mul(billboard_basis, displacement)/depth;
	float2 frame_displacement= displacement / depth;
	
	// At this point, displacement is in units of frame widths/heights.  I don't think pixel kill gains anything here.
	// We now require pixel kill for correctness, because we don't use depth test.
//	clip(dot(frame_displacement, frame_displacement)==0.0f ? -1 : 1);

	// Now use full positive range of render target [0.0,32.0)
	float2 distortion= distortion_scale * frame_displacement;
#ifdef pc
	distortion = distortion * 1024.0f / 32767.0f; // on PC use [0, 1] range instead [6/12/2012 paul.smirnov]
#endif // pc
	
	if (TEST_CATEGORY_OPTION(specialized_rendering, distortion_expensive))
	{
		static float fudge_scale= 1.0f;
		clip(compute_depth_fade(screen_coords + distortion * fudge_scale / 64.0f, depth, 1.0f)== 0 ? -1 : 1);
	}
	
	static float max_displacement= 1.0f;	// if used, keep in sync with displacement.hlsl
	return distortion * screen_constants / max_displacement;
}
#endif // pc

accum_pixel static_default_ps(s_fast_particle_interpolators IN, SCREEN_POSITION_INPUT(screen_coords))
{
#if (! defined(pc)) || (DX_VERSION == 11)
	float depth_fade= ((TEST_CATEGORY_OPTION(depth_fade, on) || TEST_CATEGORY_OPTION(depth_fade, low_res) || TEST_CATEGORY_OPTION(depth_fade, palette_shift)) && !TEST_CATEGORY_OPTION(blend_mode, opaque))
		? compute_depth_fade(screen_coords, IN.M_DEPTH, depth_fade_range)
		: 1.0f;

	float4 blended= 
//		TEST_CATEGORY_OPTION(frame_blend, on)
//		? lerp(sample_diffuse(IN.m_texcoord_sprite0, IN.m_texcoord_billboard, IN.m_palette, IN.m_color.a * depth_fade), 
//				sample_diffuse(IN.m_texcoord_sprite1, IN.m_texcoord_billboard, IN.m_palette, IN.m_color.a * depth_fade), IN.m_frame_blend) :
//		  sample_diffuse(IN.M_TEXCOORD, IN.M_TEXCOORD, IN.m_palette, IN.m_color.a * depth_fade);
		  sample_diffuse(IN.M_TEXCOORD, IN.M_TEXCOORD, 0.5f, IN.M_ALPHA * depth_fade);
	
	if (IS_DISTORTION_PARTICLE)
	{
		float2 normalized_displacement= compute_fast_normalized_distortion(screen_coords, blended, depth_fade, IN.M_DEPTH, IN.M_ALPHA);
		accum_pixel distorted_pixel;
		distorted_pixel.color= float4(normalized_displacement, 0.0f, 1.0f);
#ifndef LDR_ONLY
		distorted_pixel.dark_color= float4(0.0f, 0.0f, 0.0f, 0.0f);;
#endif
		return distorted_pixel;
	}
	else
	{
		blended.w*= depth_fade;
		
		IF_CATEGORY_OPTION(black_point, on)
		{
			blended.w= remap_alpha(IN.M_BLACK_POINT, blended.w);
		}

		blended*= IN.m_color0;
		
//		IN.m_normal= normalize(IN.m_normal);	// I think cross is fewer instructions, with no interpolator
		IF_CATEGORY_OPTION(lighting, per_pixel_ravi_order_3)
		{
			// do some lighting
			float4 sh_lighting_coefficients[10]=
			{
				p_lighting_constant_0, 
				p_lighting_constant_1, 
				p_lighting_constant_2, 
				p_lighting_constant_3, 
				p_lighting_constant_4, 
				p_lighting_constant_5, 
				p_lighting_constant_6, 
				p_lighting_constant_7, 
				p_lighting_constant_8, 
				p_lighting_constant_9 
			}; 
#define MODULATE_LIGHTING_BY_ALPHA 1
//#ifdef MODULATE_LIGHTING_BY_ALPHA
//			blended.xyz*= lerp(
//				ravi_order_0(IN.m_normal, sh_lighting_coefficients), 
//				ravi_order_3(IN.m_normal, sh_lighting_coefficients), 
//				blended.w);
//#else
//			blended.xyz*= ravi_order_3(IN.m_normal, sh_lighting_coefficients);
//#endif
		}

		// Non-linear blend modes don't work under the normal framework...
		IF_CATEGORY_OPTION(blend_mode, multiply)
		{
			blended.xyz= lerp(float3(1.0f, 1.0f, 1.0f), blended.xyz, blended.w);
		}
		else
		{
			blended.xyz+= IN.M_COLOR_ADD;
		}
	}
#else	//#ifndef pc
	float4 blended= float4(0.0f, 0.0f, 0.0f, 0.0f);
#endif	//#ifndef pc #else
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(blended, false, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}
#endif	//#ifdef PIXEL_SHADER
