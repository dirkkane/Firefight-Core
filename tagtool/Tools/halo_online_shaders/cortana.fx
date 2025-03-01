#ifdef disable_register_reorder
// magic pragma given to us by the DX10 team
// to disable the register reordering pass that was
// causing a lot of pain on the PC side of the compiler
// with this pragma we get a massive speedup on compile times
// on the PC side
#pragma ruledisable 0x0a0c0101
#endif // #ifdef disable_register_reorder

// hardcoded options
#define calc_bumpmap_ps calc_bumpmap_default_ps
#define material_type cook_torrance
#define calc_self_illumination_ps calc_self_illumination_none_ps
#define calc_specular_mask_ps calc_specular_mask_from_diffuse_ps

//#define DISABLE_DYNAMIC_LIGHTS

#include "global.fx"
#include "hlsl_constant_mapping.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"
//#include "clip_plane.fx"

#include "misc_attr_animation.fx"
#include "albedo.fx"
#include "parallax.fx"
#include "bump_mapping.fx"
#include "self_illumination.fx"
#include "specular_mask.fx"
#include "material_models.fx"
#include "environment_mapping.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"

PARAM(float3, bloom_override);
//#define BLOOM_OVERRIDE bloom_override

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"
#include "albedo_pass.fx"

PARAM(float3, screen_constants); // _render_method_extern_screen_constants

#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target
#define BLEND_FOG_INSCATTER_SCALE 1.0
#define NO_ALPHA_TO_COVERAGE


#define ALPHA_OPTIMIZATION

#ifndef APPLY_OVERLAYS
#define APPLY_OVERLAYS(color, texcoord, view_dot_normal)
#endif // APPLY_OVERLAYS


float3 get_constant_analytical_light_dir_vs()			// ####ctchou pass this in - woot!
{
 	return -normalize(v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz);
}

float3 d3dSRGBInvGamma(float3 CSRGB)
{
   return (CSRGB <= .04045f) ? (CSRGB / 12.92f) : pow((CSRGB + 0.055f) / 1.055f, 2.4f);
}


PARAM(int, layer_count);
PARAM(float, layer_depth);
PARAM(float, layer_contrast);
PARAM(float, texcoord_aspect_ratio);			// how stretched your texcoords are
PARAM(float, depth_darken);
PARAM(float4, detail_color);

float4 calc_detail_multilayer_ps(
	in float2 texcoord,
	in float3 view_dir)
{
	texcoord= transform_texcoord(texcoord, detail_map_xform);				// transform texcoord first
	float2 offset= view_dir.xy * detail_map_xform.xy * float2(texcoord_aspect_ratio, 1.0f) * layer_depth / layer_count;
	
	float4 accum= float4(0.0f, 0.0f, 0.0f, 0.0f);
	float depth_intensity= 1.0f;
	for (int x= 0; x < layer_count; x++)
	{
		accum += depth_intensity * sample2D(detail_map, texcoord);
		texcoord -= offset;	depth_intensity *= depth_darken;
	}
	accum.rgba /= layer_count;
	
	float4 result;
	result.rgb= pow(accum.rgb, layer_contrast) * detail_color.rgb;
	result.a= accum.a * detail_color.a;
	return result;
}


PARAM_SAMPLER_2D(scanline_map);
PARAM(float4, scanline_map_xform);
PARAM(float, scanline_amount_opaque);
PARAM(float, scanline_amount_transparent);


void calc_albedo_cortana_ps(
	in float2 texcoord,
	in float3 normal,
	in float3 view_dir,
	in float2 fragment_position,
	out float4 albedo)
{
	float4	base=		sample2D(base_map,		transform_texcoord(texcoord, base_map_xform)) * albedo_color;
	
	// sample scanlines
	float2 scanline_texcoord = fragment_position;
    scanline_texcoord *= screen_constants.xy * float2(1152.0f, 640.0f); // scale from original H3 resolution
	float4 scanline= sample2D(scanline_map, transform_texcoord(scanline_texcoord, scanline_map_xform));
	float scanline_amount= lerp(scanline_amount_transparent, scanline_amount_opaque, base.w);
	scanline= lerp(float4(1.0f, 1.0f, 1.0f, 1.0f), scanline, scanline_amount);
	base.rgb *= scanline.rgb;		// * base.w

	// sampled detail	
	float4	detail=		calc_detail_multilayer_ps(texcoord, view_dir);			//  tex2D(detail_map,	transform_texcoord(texcoord, detail_map_xform));

	albedo.xyz= base.xyz + (1.0f - base.w) * detail.xyz;
	albedo.w= base.w * scanline.a + (1.0f - base.w) * detail.w;
}


float4 calc_output_color_with_explicit_light_quadratic(
	float2 fragment_position,
	float3x3 tangent_frame,				// = {tangent, binormal, normal};
	float4 sh_lighting_coefficients[10],
	float3 fragment_to_camera_world,	// direction to eye/camera, in world space
	float2 texcoord,
	float4 prt_ravi_diff,
	float3 light_direction,
	float3 light_intensity,
	float3 extinction,
	float3 inscatter,
	in float4 misc)
{
	float3 view_dir= normalize(fragment_to_camera_world);

	// convert view direction to tangent space
	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	
	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);

	// get diffuse albedo, specular mask and bump normal
	float3 bump_normal;
	float4 albedo;	
	{
		calc_bumpmap_ps(texcoord, fragment_to_camera_world, tangent_frame, bump_normal);
		calc_albedo_cortana_ps(texcoord, bump_normal, view_dir_in_tangent_space, fragment_position, albedo);
	}

	// compute a blended normal attenuation factor from the length squared of the normal vector
	// blended normal pixels are MSAA pixels that contained normal samples from two different polygons, therefore the lerped vector upon resolve does not have a length of 1.0
	float normal_lengthsq= dot(bump_normal.xyz, bump_normal.xyz);
#ifndef pc	
    float blended_normal_attenuate = pow(normal_lengthsq, 8);
    light_intensity *= blended_normal_attenuate;
#endif

	// normalize bump to make sure specular is smooth as a baby's bottom	
	bump_normal /= sqrt(normal_lengthsq);

	float3 specular_mask;
	calc_specular_mask_ps(texcoord, albedo.w, specular_mask);

	// calculate view reflection direction (in world space of course)
	float view_dot_normal=	dot(view_dir, bump_normal);
	///  DESC: 18 7 2007   13:57 BUNGIE\yaohhu :
	///    do not need normalize
	float3 view_reflect_dir= (view_dot_normal * bump_normal - view_dir) * 2 + view_dir;

	float4 envmap_specular_reflectance_and_roughness;
	float3 envmap_area_specular_only;
	float4 specular_radiance;
	float3 diffuse_radiance= ravi_order_3(bump_normal, sh_lighting_coefficients);
	float4 lightint_coefficients[10]= 
	{
		sh_lighting_coefficients[0], 
		sh_lighting_coefficients[1], 
		sh_lighting_coefficients[2], 
		sh_lighting_coefficients[3], 
		float4(0.0f, 0.0f, 0.0f, 0.0f),
		float4(0.0f, 0.0f, 0.0f, 0.0f),
		float4(0.0f, 0.0f, 0.0f, 0.0f),
		float4(0.0f, 0.0f, 0.0f, 0.0f),
		float4(0.0f, 0.0f, 0.0f, 0.0f),
		float4(0.0f, 0.0f, 0.0f, 0.0f)
	};
	
	calc_material_cook_torrance_ps(
		view_dir,						// normalized
		fragment_to_camera_world,		// actual vector, not normalized
		bump_normal,					// normalized
		view_reflect_dir,				// normalized
		
		lightint_coefficients,	
		light_direction,				// normalized
		light_intensity,
		
		albedo.xyz,					// diffuse_reflectance
		specular_mask,
		texcoord,
		prt_ravi_diff,

		tangent_frame,
		misc,

		envmap_specular_reflectance_and_roughness,
		envmap_area_specular_only,
		specular_radiance,
		diffuse_radiance);
		
	//compute environment map
	envmap_area_specular_only= max(envmap_area_specular_only, 0.001f);
    float4 ssr_color= 0.0f;
	float3 envmap_radiance= CALC_ENVMAP(envmap_type)(view_dir, bump_normal, view_reflect_dir, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, ssr_color);

	//compute self illumination	
	float3 self_illum_radiance= calc_self_illumination_ps(texcoord, albedo.xyz, view_dir_in_tangent_space, fragment_position, fragment_to_camera_world, view_dot_normal);	// * ILLUM_SCALE;
	
	// set color channels
	float4 out_color;
	out_color.xyz= (diffuse_radiance * albedo.xyz + specular_radiance + self_illum_radiance + envmap_radiance);
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= (out_color.xyz * extinction + inscatter * BLEND_FOG_INSCATTER_SCALE) * g_alt_exposure.ggg * 2.0f;
	out_color.w= 1.0f - albedo.w;

	return out_color;
}


PARAM_SAMPLER_2D(fade_noise_map);
PARAM(float4, fade_noise_map_xform);
PARAM(float, noise_amount);
PARAM(float, fade_offset);
PARAM(float, warp_fade_offset);

struct static_prt_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
	float4 texcoord					: TEXCOORD0;
	float3 normal					: TEXCOORD1;
	float3 binormal					: TEXCOORD2;
	float3 tangent					: TEXCOORD3;
	float3 fragment_to_camera_world : TEXCOORD4;
	float4 prt_ravi_diff			: TEXCOORD5;
	float3 extinction				: COLOR0;
	float4 inscatter				: COLOR1;
	float4 perturb					: TEXCOORD6;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

static_prt_vsout static_prt_ambient_vs(
	in vertex_type vertex,
#ifdef pc
	in float prt_c0_c3 : BLENDWEIGHT1
#else // xenon
	in float vertex_index : SV_VertexID
#endif // xenon
	)
{
	static_prt_vsout vsout;

#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
#ifdef pc
//	float prt_c0= PRT_C0_DEFAULT;
	float prt_c0= prt_c0_c3;
#else // xenon
	// fetch PRT data from compressed 
	float prt_c0;

	float prt_fetch_index= vertex_index * 0.25f;								// divide vertex index by 4
	float prt_fetch_fraction= frac(prt_fetch_index);							// grab fractional part of index (should be 0, 0.25, 0.5, or 0.75) 

	float4 prt_values, prt_component;
	float4 prt_component_match= float4(0.75f, 0.5f, 0.25f, 0.0f);				// bytes are 4-byte swapped (each dword is stored in reverse order)
	asm
	{
		vfetch	prt_values, prt_fetch_index, blendweight1						// grab four PRT samples
		seq		prt_component, prt_fetch_fraction.xxxx, prt_component_match		// set the component that matches to one		
	};
	prt_c0= dot(prt_component, prt_values);
#endif // xenon

	vsout.perturb.x= dot(vertex.normal, Camera_Left);
 	vsout.perturb.y= dot(vertex.normal, Camera_Up);
   	
   	// Spherical texture projection 
   	vsout.perturb.z= atan2((vertex.position.x - 0.5f) * Position_Compression_Scale.x, (vertex.position.y - 0.5f) * Position_Compression_Scale.y);
   	float aspect= Position_Compression_Scale.z / length(Position_Compression_Scale.xy);
   	vsout.perturb.w= acos(vertex.position.z - 0.5f) * aspect;

 	//output to pixel shader
	float4 local_to_world_transform[3];
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal= vertex.normal;
	vsout.texcoord.xy= vertex.texcoord;
	vsout.texcoord.zw = 0.0f;
	vsout.tangent= vertex.tangent;
	vsout.binormal= vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world= Camera_Position-vertex.position;
	
	float ambient_occlusion= prt_c0;
	float lighting_c0= 	dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));			// ###ctchou $PERF convert to monochrome before passing in!
	float ravi_mono= (0.886227f * lighting_c0)/3.1415926535f;
	float prt_mono= ambient_occlusion * lighting_c0;
		
	prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
	ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
	float prt_ravi_ratio= prt_mono /ravi_mono;
	vsout.prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
	vsout.prt_ravi_diff.y= prt_mono;														// unused
	vsout.prt_ravi_diff.z= (ambient_occlusion * 3.1415926535f)/0.886227f;					// specular occlusion % (ambient occlusion)
	vsout.prt_ravi_diff.w= min(dot(vsout.normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
		
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter.xyz);
	
	float4 vertex_transparency= 1.0f;
#ifndef pc
	float2 vt_texcoord= transform_texcoord(vsout.position.xy, fade_noise_map_xform);
	asm {
		tfetch2D vertex_transparency, vt_texcoord, fade_noise_map, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, UseComputedLOD= false
	};
#else
	float2 vt_texcoord= transform_texcoord(vsout.position.xy, fade_noise_map_xform);
	vertex_transparency = sample2Dlod(fade_noise_map, vt_texcoord, 0.0f);
#endif // !pc
	vsout.inscatter.w= fade_offset + (vertex_transparency.r * (2 * noise_amount) - noise_amount);

	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

accum_pixel static_prt_ps(
	in static_prt_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	// normalize interpolated values
	vsout.normal= normalize(vsout.normal);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
	
	// setup tangent frame
	float3x3 tangent_frame = {vsout.tangent, vsout.binormal, vsout.normal};

	// build sh_lighting_coefficients
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
	
	float4 out_color= calc_output_color_with_explicit_light_quadratic(
		vsout.position,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord.xy,
		vsout.prt_ravi_diff,
		k_ps_dominant_light_direction,
		k_ps_dominant_light_intensity,
		vsout.extinction,
		vsout.inscatter,
		misc);
			
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}
	
struct static_sh_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
	float3 texcoord_and_vertexNdotL : TEXCOORD0;
	float3 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 tangent					: TEXCOORD5;
	float3 fragment_to_camera_world : TEXCOORD6;
	float3 extinction				: COLOR0;
	float4 inscatter				: COLOR1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

///constant to do order 2 SH convolution
static_sh_vsout static_sh_vs(
	in vertex_type vertex)
{
	static_sh_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif

	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal = vertex.normal;
	vsout.texcoord_and_vertexNdotL.xy = vertex.texcoord;
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;
	
	vsout.texcoord_and_vertexNdotL.z = dot(vsout.normal, get_constant_analytical_light_dir_vs());
		
	// world space direction to eye/camera
	vsout.fragment_to_camera_world.rgb = Camera_Position - vertex.position;
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter.xyz);
    vsout.inscatter.w = 0.0f;
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}


accum_pixel static_sh_ps(
	in static_sh_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	// normalize interpolated values
	vsout.normal = normalize(vsout.normal);
	vsout.binormal = normalize(vsout.binormal);
	vsout.tangent = normalize(vsout.tangent);
	
	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal };

	// build sh_lighting_coefficients
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
	
	float4 prt_ravi_diff= float4(1.0f, 0.0f, 1.0f, dot(tangent_frame[2], k_ps_dominant_light_direction));
	float4 out_color= calc_output_color_with_explicit_light_quadratic(
		vsout.position,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord_and_vertexNdotL.xy,
		prt_ravi_diff,
		k_ps_dominant_light_direction,
		k_ps_dominant_light_intensity,
		vsout.extinction,
		vsout.inscatter,
		misc);
			
    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}

static_prt_vsout active_camo_vs(
	in vertex_type vertex,
#ifdef pc
	in float prt_c0_c3 : BLENDWEIGHT1
#else // xenon
	in float vertex_index : SV_VertexID
#endif // xenon
	)
{
	static_prt_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	vsout = static_prt_ambient_vs(
		vertex,
#ifdef pc
   	prt_c0_c3
#else // xenon		
		vertex_index
#endif // xenon
	);   	
		
	vsout.texcoord.z = 0.0f;
	vsout.texcoord.w = length(vertex.position - Camera_Position);

	return vsout;
}


PARAM_SAMPLER_2D(active_camo_distortion_texture);
PARAM(float, warp_amount);

PARAM_SAMPLER_2D(fade_gradient_map);
PARAM(float4, fade_gradient_map_xform);
PARAM(float, fade_gradient_scale);

accum_pixel active_camo_ps(
	in static_prt_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	
	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal= normalize(vsout.normal);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal };

	// build sh_lighting_coefficients
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
	
	float4 color_transparency= calc_output_color_with_explicit_light_quadratic(
		vsout.position,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord.xy,
		vsout.prt_ravi_diff,
		k_ps_dominant_light_direction,
		k_ps_dominant_light_intensity,
		vsout.extinction,
		vsout.inscatter,
		misc);

	// grab screen position
	float2 uv = float2((vsout.position.x + 0.5f) / texture_size.x, (vsout.position.y + 0.5f) / texture_size.y);
	
	float transparency = sample2D(fade_gradient_map, transform_texcoord(vsout.texcoord.xy, fade_gradient_map_xform)).a * fade_gradient_scale + vsout.inscatter.w;
	
	float2 uvdelta = vsout.perturb.xy * warp_amount * saturate(transparency + warp_fade_offset) * float2(1.0f / 16.0f, 1.0f / 9.0f);
	
	// Perspective correction so we don't distort too much in the distance
	// (and clamp the amount we distort in the foreground too)
	uv.xy += uvdelta / max(0.5f, vsout.texcoord.w);
	uv.xy= clamp(uv.xy, k_ps_distort_bounds.xy, k_ps_distort_bounds.zw);
	
	// HDR texture is currently not used
	//float4 hdr_color= sample2D(scene_hdr_texture, uv.xy);	
	float4 ldr_color= sample2D(scene_ldr_texture, uv.xy);

#ifdef pc
  ldr_color.rgb = d3dSRGBInvGamma(ldr_color.rgb);
#endif
	
	float3 true_scene_color= lerp(color_transparency.rgb, ldr_color.rgb, saturate(color_transparency.a + saturate(1.0f-transparency)));
	float4 result= float4(true_scene_color, 1.0f);
	
    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(result, false, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}

struct albedo_vsout
{
    float4 position						: VS_POS_OUTPUT;
	//float clip_distance				  : SV_ClipDistance;
	float2 texcoord						: TEXCOORD0;
	float4 normal						: TEXCOORD1;
	float3 binormal						: TEXCOORD2;
	float3 tangent						: TEXCOORD3;
	float3 fragment_to_camera_world		: TEXCOORD4;
#ifdef misc_attr_define
	float4 misc							: TEXCOORD9;
#endif
};

albedo_vsout albedo_vs(
	in vertex_type vertex)
{
	albedo_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	// normal, tangent and binormal are all in world space
	vsout.normal.xyz = vertex.normal;
	vsout.normal.w = vsout.position.w;
	vsout.texcoord = vertex.texcoord;
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;

	// world space vector from vertex to eye/camera
	vsout.fragment_to_camera_world = Camera_Position - vertex.position;
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}


albedo_pixel albedo_ps(
	in albedo_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(vsout.texcoord, output_alpha);

	float4 base = sample2D(base_map, transform_texcoord(vsout.texcoord, base_map_xform)) * albedo_color;
	return convert_to_albedo_target(base, vsout.normal.xyz, vsout.normal.w, vsout.normal.xyz);
}
