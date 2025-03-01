
float2 compute_detail_slope_reach(
			float2 base_texcoord,
			float4 base_texture_xform,
			float time_warp,
			float mipmap_level)
{
	float2 slope_detail= 0.0f;		
	
	// TODO: support in tags
	//if ( TEST_CATEGORY_OPTION(detail, repeat) )
    if (TEST_CATEGORY_OPTION(reach_compatibility, enabled_detail_repeat))
	{
		float4 wave_detail_xform= base_texture_xform * float4(detail_slope_scale_x, detail_slope_scale_y, 1, 1);
		float4 texcoord_detail= float4(transform_texcoord(base_texcoord, wave_detail_xform),  time_warp*detail_slope_scale_z, mipmap_level);	
		
		TFETCH_3D(slope_detail.xy, texcoord_detail.xyz, wave_slope_array, 0, 1);
        slope_detail.xy = BUMP_CONVERT(slope_detail.xy);
		slope_detail.xy *= detail_slope_steepness;
	}

	return slope_detail;
}

void compose_slope_original_reach(
			float4 texcoord_in,
			float height_scale,
			float height_aux_scale,
			out float2 slope_shading,
			out float wave_choppiness_ratio)
{
	float mipmap_level= texcoord_in.w;	
	float4 texcoord= float4(transform_texcoord(texcoord_in.xy, wave_displacement_array_xform),  time_warp, mipmap_level);
	float4 texcoord_aux= float4(transform_texcoord(texcoord_in.xy, wave_slope_array_xform),  time_warp_aux, mipmap_level);	

	float2 slope;
	float2 slope_aux;	

	TFETCH_3D(slope.xy, texcoord.xyz, wave_slope_array, 0, 1);
	slope.xy = BUMP_CONVERT(slope.xy);
	TFETCH_3D(slope_aux.xy, texcoord_aux.xyz, wave_slope_array, 0, 1);
	slope_aux.xy = BUMP_CONVERT(slope_aux.xy);


	float wave_choppiness_ratio_1= 1.0f - abs(slope.x) - abs(slope.y);
	float wave_choppiness_ratio_2= 1.0f - abs(slope_aux.x) - abs(slope_aux.y);
	wave_choppiness_ratio= max(wave_choppiness_ratio_1, wave_choppiness_ratio_2);

	float2 slope_detail= compute_detail_slope_reach(texcoord_in.xy, wave_displacement_array_xform, time_warp, mipmap_level+1);

	//	apply scale		
	slope_shading= 	slope + slope_aux + slope_detail;
}

float compute_fog_transparency_reach( 
			float murkiness,
			float negative_depth)
{
	return saturate(exp2(murkiness * negative_depth));
}

float compute_fog_factor_reach( 
			float murkiness,
			float depth)
{
    return 1.0f - compute_fog_transparency_reach(murkiness, -depth);
}

float compute_fresnel_reach(
			float3 incident,
			float3 normal,
			float r0,
			float r1)
{
 	float eye_dot_normal=	saturate(dot(incident, normal));
	eye_dot_normal=			saturate(r1 - eye_dot_normal);
	return saturate(r0 * eye_dot_normal * eye_dot_normal);			//pow(eye_dot_normal, 2.5);
}

// TODO: apply hack here? (+1.0f)
float3 decode_bpp16_luvw_reach(
	in float4 val0,
	in float4 val1,
	in float l_range)
{	
	float L = val0.a * val1.a * l_range;
	float3 uvw = val0.xyz + val1.xyz;
	return (uvw * 2.0f - 2.0f) * L;	
}

float sample_depth_reach(float2 texcoord)
{
	// fp32 depth buffer stores w, we need to convert to z
//#ifdef pc
	float depth = tex2D(depth_buffer, texcoord).r;
	return 1.0f - (k_ps_water_view_depth_constant.x / depth + k_ps_water_view_depth_constant.y); // Zbuf = -FN/(F-N) / z + F/(F-N)
//#else // xenon
//	float4 result;
//	asm
//	{
//		tfetch2D result, texcoord, depth_buffer, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= 0.5, OffsetY= 0.5
//	};
//	return result.r;
//#endif // xenon
}

accum_pixel water_shading_reach(s_water_interpolators INTERPOLATORS)
{    
	const bool alpha_blend_output = false; // we don't support alpha blended water

	// TODO: early out for performance
	// difficult with dx9 as we dont have code blocks in compiled shaders, and cannot branch on scalars
	// a clip() will work if we add support for alpha blended water
	
	// interaction
	float2 ripple_slope= 0.0f;		
	float ripple_foam_factor= 0.0f;

	[branch]
	if (k_is_water_interaction)
	{			
		float2 texcoord_ripple= INTERPOLATORS.lm_tex.zw;		
        float4 ripple= sample2Dlod(tex_ripple_buffer_slope_height, texcoord_ripple.xy, 0);
		ripple_slope= (ripple.gb - 0.5f) * 6.0f;	// hack		
		ripple_foam_factor= ripple.a;
	}	
    
    float ripple_slope_length = dot(abs(ripple_slope.xy), 2.0f) + 1.0f;
    
    float2 slope_shading= 0.0f;
	float wave_choppiness_ratio= 0.0f;
	if (TEST_CATEGORY_OPTION(waveshape, default))
	{
		compose_slope_original_reach(
			INTERPOLATORS.texcoord, 
			1.0f,
			1.0f,
			slope_shading,
			wave_choppiness_ratio);
	}
	else if (TEST_CATEGORY_OPTION(waveshape, bump) )
	{
		// grap code from calc_bumpmap_detail_ps in bump_mapping.fx
		float3 bump= sample_bumpmap(bump_map, transform_texcoord(INTERPOLATORS.texcoord, bump_map_xform));					// in tangent space
		float3 detail= sample_bumpmap(bump_detail_map, transform_texcoord(INTERPOLATORS.texcoord, bump_detail_map_xform));	// in tangent space	
		bump.xy+= detail.xy;

		// convert bump into slope
		slope_shading= bump.xy/max(bump.z, 0.01f);
	}
	slope_shading= slope_shading * slope_scaler + ripple_slope;
	
	float3 INTERPOLATORS_normal = -normalize(cross(INTERPOLATORS.binormal.xyz, INTERPOLATORS.tangent.xyz));
	float3x3 tangent_frame_matrix= { INTERPOLATORS.tangent.xyz, INTERPOLATORS.binormal.xyz, INTERPOLATORS_normal.xyz };
	float3 normal= mul(float3(slope_shading, 1.0f), tangent_frame_matrix);	
	normal= normalize(normal);	
	
	// we need to use h3 lighting here for compatibility
	// TODO: reproduce the reach water lighting hack
	
	// apply lightmap shadow
	float3 lightmap_intensity= 1.0f;
	[branch]
	if ( k_is_lightmap_exist )	
	{
		float4 sh_dxt_vector_0;
		float4 sh_dxt_vector_1;
		float3 lightmap_texcoord_bottom= float3(INTERPOLATORS.lm_tex.xy, 0.0f);
		
		TFETCH_3D(sh_dxt_vector_0, lightmap_texcoord_bottom, lightprobe_texture_array, 0.5, 8);
		TFETCH_3D(sh_dxt_vector_1, lightmap_texcoord_bottom, lightprobe_texture_array, 1.5, 8);
				
        float3 sh_coefficients_0 = decode_bpp16_luvw_reach(sh_dxt_vector_0, sh_dxt_vector_1, p_lightmap_compress_constant_0.x);
		
        const float3 intensity = float3(1.0f, 1.0f, 1.0f);
        const float visibility_mask = 1.0f;
		lightmap_intensity= saturate(sh_coefficients_0) * intensity.rgb + visibility_mask;		
	}
	// end H3 lighting
	
    float one_over_camera_distance = 1.0f / max(INTERPOLATORS.incident_ws.w, 0.01f);

	float4 water_color_from_texture= tex2D(watercolor_texture, transform_texcoord(INTERPOLATORS.base_tex.xy, watercolor_texture_xform));
	float4 global_shape_from_texture= tex2D(global_shape_texture, transform_texcoord(INTERPOLATORS.base_tex.xy, global_shape_texture_xform));

	float3 water_color;
	if (TEST_CATEGORY_OPTION(watercolor, pure))
	{
		water_color= water_color_pure;		
	}
	else if  (TEST_CATEGORY_OPTION(watercolor, texture))
	{
		water_color= water_color_from_texture.rgb * watercolor_coefficient;
	}
	water_color *= lightmap_intensity;

	float bank_alpha= 1.0f;
	if ( TEST_CATEGORY_OPTION(bankalpha, paint) )
	{
		bank_alpha= water_color_from_texture.w;
	}
	else if (TEST_CATEGORY_OPTION(bankalpha, from_shape_texture_alpha) )
	{
		bank_alpha= global_shape_from_texture.a;
	}
	
	float3 color_refraction;
	float3 color_refraction_bed;
	float4 color_refraction_blend;

	if (TEST_CATEGORY_OPTION(refraction, none))
	{
		color_refraction= water_color;
		color_refraction_bed= water_color;
		color_refraction_blend.rgb= water_color;
		color_refraction_blend.a=	0.0f;
	}
	else if (TEST_CATEGORY_OPTION(refraction, dynamic))
	{
		// calcuate texcoord in screen space
		//INTERPOLATORS.position_ss /= INTERPOLATORS.position_ss.w;
		//float2 texcoord_ss= INTERPOLATORS.position_ss.xy;
		INTERPOLATORS.position_ss /= INTERPOLATORS.position_ss.w;
		float2 texcoord_ss = INTERPOLATORS.position_ss.xy;
		texcoord_ss = texcoord_ss / 2 + 0.5;
		texcoord_ss.y = 1 - texcoord_ss.y;
		texcoord_ss = k_ps_water_player_view_constant.xy + texcoord_ss * k_ps_water_player_view_constant.zw;
	
		float2 texcoord_refraction;
		float refraction_depth;
				
		//if (alpha_blend_output)
		//{
		//	texcoord_refraction= texcoord_ss;
		//	refraction_depth= sample_depth_reach(texcoord_refraction);		
		//}
		//else
		{
			float2 bump= slope_shading.xy * refraction_texcoord_shift;
			bump *= saturate(2.0f*one_over_camera_distance);				// near bump fading -- could move to VS

			if (!TEST_CATEGORY_OPTION(bankalpha, none))
			{
				bump *= bank_alpha;
			}
		
			texcoord_refraction= saturate(texcoord_ss + bump);
			refraction_depth= sample_depth_reach(texcoord_refraction);

			//	###xwan this comparision need to some tolerance to avoid dirty boundary of refraction	
			texcoord_refraction= (refraction_depth<INTERPOLATORS.position_ss.z) ? texcoord_refraction : texcoord_ss;				// if point is actually closer to camera, drop refraction amount and revert to unrefracted
//			texcoord_refraction= saturate(texcoord_ss + saturate(500*(INTERPOLATORS.position_ss.z - refraction_depth)) * bump);		// approximate depth fade out
		
			color_refraction= tex2D(scene_ldr_texture, texcoord_refraction);		
//			asm 
//			{		// this is more accurate and eliminates the very slight halos around objects in the refracted water..  but doesn't give as nice of a blend because we drop bilinear sampling
//				tfetch2D color_refraction.rgb_, texcoord_refraction, scene_ldr_texture, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= 0.5, OffsetY= 0.5
//			};
			
			// ms23 ldr rt format is not biased this way. i think it is safe to remove completely.
			//color_refraction.rgb= (color_refraction.rgb < (1.0f/(16.0f*16.0f))) ? color_refraction.rgb : (exp2(color_refraction.rgb * (16 * 8) - 8));
            color_refraction /= g_exposure.r; // i'm not sure if this is correct either.
			color_refraction_bed= color_refraction;	//	pure color of under water stuff

			//	check real refraction -- we don't do this in the cheap shader because the apparent 'refraction' point doesn't move
			refraction_depth= sample_depth_reach(texcoord_refraction);
		}

		// reverting to h3 here
		//float4 point_refraction= float4(texcoord_refraction, refraction_depth, 1.0f);
		//point_refraction= mul(point_refraction, k_ps_texcoord_to_world_matrix);
		//point_refraction.xyz/= point_refraction.w;
		texcoord_refraction.y= 1.0 - texcoord_refraction.y;
		texcoord_refraction= texcoord_refraction*2 - 1.0f;
		float4 point_refraction= float4(texcoord_refraction, refraction_depth, 1.0f);
		point_refraction= mul(point_refraction, k_ps_water_view_xform_inverse);
		point_refraction.xyz/= point_refraction.w;

		// world space depth
//		float refraction_depth= INTERPOLATORS.position_ws.z - point_refraction.z;
		float negative_refraction_depth= point_refraction.z - INTERPOLATORS.position_ws.z;

		// compute refraction
//		float transparency= compute_fog_transparency(water_murkiness*ripple_slope_length, refraction_depth);		// what does ripple slope length accomplish?  attempt to darken ripple edges?
		float transparency= compute_fog_transparency_reach(water_murkiness, negative_refraction_depth);
		transparency *= saturate(refraction_extinct_distance * one_over_camera_distance);							// turns opaque at distance
		
		if (k_is_camera_underwater)
		{
			transparency*= 0.02f;
		}
		
		//if (alpha_blend_output)
		//{
		//	color_refraction_blend.rgb= water_color.rgb * (1.0f - transparency);
		//	color_refraction_blend.a=	transparency;
		//}
		//else
		//{
			color_refraction= lerp(water_color, color_refraction, transparency);
		//}
	}	
		
	// compute foam	
	float4 foam_color= 0.0f;
	float foam_factor= 0.0f;	
	{
		// calculate factor
		float foam_factor_auto= 0.0f;
		float foam_factor_paint= 0.0f;
		if (TEST_CATEGORY_OPTION(foam, auto) || TEST_CATEGORY_OPTION(foam, both))
		{
			if (INTERPOLATORS.base_tex.z < 0)
				wave_choppiness_ratio= 0;

			foam_factor_auto= saturate(wave_choppiness_ratio - foam_cut)/saturate(1.0f - foam_cut);
			foam_factor_auto= pow(foam_factor_auto, max(foam_pow, 1.0f));
		}

		if (TEST_CATEGORY_OPTION(foam, paint) || TEST_CATEGORY_OPTION(foam, both))
		{
			foam_factor_paint= global_shape_from_texture.b;
		}

		// output factor
		if (TEST_CATEGORY_OPTION(foam, auto))
		{
			foam_factor= foam_factor_auto;
		}
		else if (TEST_CATEGORY_OPTION(foam, paint))
		{
			foam_factor= foam_factor_paint;
		}
		else if (TEST_CATEGORY_OPTION(foam, both))
		{
			foam_factor= max(foam_factor_auto, foam_factor_paint);
		}

		if (!TEST_CATEGORY_OPTION(foam, none))
		{
			// add ripple foam
			foam_factor= max(ripple_foam_factor, foam_factor);
			foam_factor*= foam_coefficient;						// this value is undefined unless foam != NONE

			foam_factor*= saturate(20 * one_over_camera_distance);

			//[branch] // compiler restrictions :/
			if ( foam_factor > 0.002f )
			{
				// blend textures
				float4 foam= tex2D(foam_texture, transform_texcoord(INTERPOLATORS.texcoord.xy, foam_texture_xform));
				float4 foam_detail= tex2D(foam_texture_detail, transform_texcoord(INTERPOLATORS.texcoord.xy, foam_texture_detail_xform));
				foam_color.rgb= foam.rgb * foam_detail.rgb;
				foam_color.a= foam.a * foam_detail.a;		
				foam_factor= foam_color.w * foam_factor;
			}
		}
	}
		
	// compute diffuse by n dot l, really a hack!				// yeah yeah, this is basically just saying water_diffuse * normal.z
	float3 water_kd=		water_diffuse; 
	float3 sun_dir_ws=		float3(0.0, 0.0, 1.0);				//	sun direction up??
	//sun_dir_ws=			normalize(sun_dir_ws);
	float n_dot_l=			saturate(dot(sun_dir_ws, normal));	// == normal.z
	float3 color_diffuse=	water_kd * n_dot_l;
		
	// compute reflection
	float3 color_reflection= 0;		//float3(0.1, 0.1, 0.1) * reflection_coefficient;
	if (TEST_CATEGORY_OPTION(reflection, none))
	{
		color_reflection= float3(0, 0, 0);
	}
	else
	{
		float3 normal_reflect= lerp(normal, float3(0.0f, 0.0f, 1.0f), 1.0f - normal_variation_tweak);	// NOTE: uses inverted normal variation tweak -- if we invert ourselves we can save this op
		
		float3 reflect_dir= reflect(-INTERPOLATORS.incident_ws.xyz, normal_reflect);
		reflect_dir.y*= -1.0;

		// sample environment map
		float4 environment_sample;
		if (TEST_CATEGORY_OPTION(reflection, static))
		{         
			environment_sample= texCUBE(environment_map, reflect_dir);
			environment_sample.rgb *= 256;		// static cubemap doesn't have exponential bias
		}
		else if (TEST_CATEGORY_OPTION(reflection, dynamic))
        {
            const float exp_bias = 4.0f; // exponential bias of 2^2 for dynamic cubes
			float4 reflection_0= texCUBE(dynamic_environment_map_0, reflect_dir) * exp_bias;
//			float4 reflection_1= texCUBE(dynamic_environment_map_1, reflect_dir);
			environment_sample= reflection_0;//* dynamic_environment_blend.w;				//	reflection_1 * (1.0f-dynamic_environment_blend.w);
			environment_sample.rgb *= environment_sample.rgb * 4;
			environment_sample.a /= 4;
			// dynamnic cubempa has 2 exponent bias. so we need to restore the original value for the original math
        }

		// evualuate HDR color with considering of shadow
		float2 parts;
		parts.x= saturate(environment_sample.a - sunspot_cut);
		parts.y= min(environment_sample.a, sunspot_cut);

		float3 sun_light_rate= saturate(lightmap_intensity - shadow_intensity_mark);
		float sun_scale= dot(sun_light_rate, sun_light_rate);

		const float shadowed_alpha= parts.x*sun_scale + parts.y;
		color_reflection= 
			environment_sample.rgb * 
			shadowed_alpha * 
			reflection_coefficient;       
	}	
		
	// only apply lightmap_intensity on diffuse and reflection, watercolor of refrection has already considered
	color_diffuse*= lightmap_intensity;	
	foam_color.rgb*= lightmap_intensity;
		
	// add dynamic lighting
	[branch]
	if (!no_dynamic_lights)
	{
		float3 simple_light_diffuse_light; //= 0.0f;
		float3 simple_light_specular_light; //= 0.0f;
		
		calc_simple_lights_analytical(
			INTERPOLATORS.position_ws,
			normal,
			-INTERPOLATORS.incident_ws.xyz,
			20,
			simple_light_diffuse_light,
			simple_light_specular_light);

		color_diffuse		+= simple_light_diffuse_light * water_kd;
		color_reflection	+= simple_light_specular_light;
	}
		
	float3 fresnel_normal= normal;
	[branch]
	if (k_is_camera_underwater)
		fresnel_normal= -fresnel_normal;
		
	float fresnel= compute_fresnel_reach(INTERPOLATORS.incident_ws.xyz, fresnel_normal, fresnel_coefficient, fresnel_dark_spot);
		
	float4 output_color;	

	//if (alpha_blend_output)
	//{
	//	output_color=	color_refraction_blend;
	//	
	//	// reflection blends on top of refraction, with alpha == fresnel factor
	//	output_color.rgb=	output_color.rgb * (1.0f - fresnel) + color_reflection * fresnel;
	//	output_color.a *=	(1.0f - fresnel);
	//
	//	// diffuse is a glow layer
	//	output_color.rgb += color_diffuse;
	//
	//	if (!TEST_CATEGORY_OPTION(bankalpha, none))
	//	{
	//		// bank alpha blends towards background
	//		output_color.rgb *=		bank_alpha;
	//		output_color.a=			1.0f - (1.0f-output_color.a)*bank_alpha;
	//	}
	//
	//	if (!TEST_CATEGORY_OPTION(foam, none))
	//	{
	//		// opaque blend foam on top
	//		output_color.rgb=	output_color.rgb * (1.0f - foam_factor) + foam_color.rgb * foam_factor;
	//		output_color.a *=	(1.0f - foam_factor);
	//	}
	//
	//	output_color.a= 1.0f - output_color.a;
	//	// fog -- can we skip it for alpha-blend?
	//}
	//else
	{		
		output_color.rgb= lerp(color_refraction, color_reflection,  fresnel);
	
		// add diffuse
		output_color.rgb= output_color.rgb + color_diffuse; 

		// apply bank alpha
		if ( !TEST_CATEGORY_OPTION(bankalpha, none) )
		{
			output_color.rgb= lerp(color_refraction_bed, output_color.rgb, bank_alpha);
		}

		// apply foam
		if (!TEST_CATEGORY_OPTION(foam, none))
		{
			output_color.rgb= lerp(output_color.rgb, foam_color.rgb, foam_factor);
		}
	
		// apply under water fog
		[branch]
		if (k_is_camera_underwater)
		{
			float transparence= 0.5f * saturate(1.0f - compute_fog_factor_reach(k_ps_underwater_murkiness, INTERPOLATORS.incident_ws.w));
			output_color.rgb= lerp(k_ps_underwater_fog_color, output_color.rgb, transparence);
		}
		output_color.a= 1.0f;
	}
	
	// this needs to be figured out
    //output_color = output_color * INTERPOLATORS.fog_extinction + INTERPOLATORS.fog_inscatter * BLEND_FOG_INSCATTER_SCALE;
	output_color.rgb *= g_exposure.rrr;
		
	// this may not match reach, but we need to replicate rt write
	return convert_to_render_target(output_color, true, true, 0.0f);		
}