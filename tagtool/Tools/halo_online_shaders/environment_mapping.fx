#include "hlsl_constant_mapping.fx"
#include "utilities.fx"

#define ENVMAP_TYPE(env_map_type) ENVMAP_TYPE_##env_map_type
#define ENVMAP_TYPE_none 0
#define ENVMAP_TYPE_per_pixel 1
#define ENVMAP_TYPE_dynamic 2
#define ENVMAP_TYPE_from_flat_texture 3
#define ENVMAP_TYPE_custom_map 4
#define ENVMAP_TYPE_dynamic_reach 5
#define ENVMAP_TYPE_from_flat_texture_as_cubemap 6
#define ENVMAP_TYPE_per_pixel_mip 7

#define CALC_ENVMAP(env_map_type) calc_environment_map_##env_map_type##_ps



PARAM(float3, env_tint_color);
//PARAM(float3, env_glancing_tint_color);
PARAM(float, env_bias);								// ###ctchou $TODO replace this - use roughness instead

PARAM(float3, env_topcoat_color);
PARAM(float, env_topcoat_bias);
PARAM(float, env_roughness_scale);

PARAM(float, env_roughness_offset);
float offset_env_reflection_lod(float base_roughness)
{
    return (base_roughness + (env_roughness_offset - 0.5) * 2) * 4;
}

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_none
float3 calc_environment_map_none_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	ssr_color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	return float3(0.0f, 0.0f, 0.0f);
}
#endif // ENVMAP_TYPE_none

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_per_pixel
#if DX_VERSION == 9
samplerCUBE environment_map : register(s1);		// test
#elif DX_VERSION == 11
PARAM_SAMPLER_CUBE(environment_map);
#endif
float3 calc_environment_map_per_pixel_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	reflect_dir.y= -reflect_dir.y;
	
	float4 reflection;
//#ifdef pc	
//	reflection= sampleCUBE(environment_map, reflect_dir);
//#else
	reflection= sampleCUBElod(environment_map, reflect_dir, 0.0f);
//#endif

	ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
	ssr_color.a = specular_reflectance_and_roughness.w * env_roughness_scale;

	return reflection.rgb * specular_reflectance_and_roughness.xyz * low_frequency_specular_color * env_tint_color * reflection.a;
}
#endif // ENVMAP_TYPE_per_pixel

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_per_pixel_mip
#if DX_VERSION == 9
samplerCUBE environment_map : register(s1);		// test
#elif DX_VERSION == 11
PARAM_SAMPLER_CUBE(environment_map);
#endif
float3 calc_environment_map_per_pixel_mip_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
    reflect_dir.y = -reflect_dir.y;
	
    float4 reflection;

    reflection = sampleCUBE(environment_map, reflect_dir);

    ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
    ssr_color.a = specular_reflectance_and_roughness.w * env_roughness_scale;

    return reflection.rgb * specular_reflectance_and_roughness.xyz * low_frequency_specular_color * env_tint_color * reflection.a;
}
#endif // ENVMAP_TYPE_per_pixel_mip

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_dynamic

#ifndef pc
	samplerCUBE dynamic_environment_map_0 : register(s1);		// declared by shaders\shader_options\env_map_dynamic.render_method_option
	samplerCUBE dynamic_environment_map_1 : register(s2);		// declared by shaders\shader_options\env_map_dynamic.render_method_option
#elif DX_VERSION == 11
	PARAM_SAMPLER_CUBE(dynamic_environment_map_0);		// declared by shaders\shader_options\env_map_dynamic.render_method_option
	PARAM_SAMPLER_CUBE(dynamic_environment_map_1);		// declared by shaders\shader_options\env_map_dynamic.render_method_option
#else
	samplerCUBE dynamic_environment_map_0;		// declared by shaders\shader_options\env_map_dynamic.render_method_option
	samplerCUBE dynamic_environment_map_1;		// declared by shaders\shader_options\env_map_dynamic.render_method_option
#endif 

float3 calc_environment_map_dynamic_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	reflect_dir.y= -reflect_dir.y;
	
	float4 reflection_0, reflection_1;
	
#ifdef pc
	float grad_x= length(ddx(reflect_dir));
	float grad_y= length(ddy(reflect_dir));
	float base_lod= 6.0f * sqrt(max(grad_x, grad_y)) - 0.6f;
	float lod= max(0.0f, specular_reflectance_and_roughness.w * env_roughness_scale * 4);
	
	reflection_0= sampleCUBElod(dynamic_environment_map_0, reflect_dir, lod);
	reflection_1= sampleCUBElod(dynamic_environment_map_1, reflect_dir, lod);
	
#else	// xenon
	float grad_x= 0.0f;
	float grad_y= 0.0f;
	float base_lod= 0.0f;
	float lod= max(base_lod, specular_reflectance_and_roughness.w * env_roughness_scale * 4);
	
	reflection_0= sampleCUBElod(dynamic_environment_map_0, reflect_dir, lod);
	reflection_1= sampleCUBElod(dynamic_environment_map_1, reflect_dir, lod);
#endif

	ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
	ssr_color.a = specular_reflectance_and_roughness.w * env_roughness_scale;

	float3 reflection=  (reflection_0.rgb * reflection_0.a * 256) * dynamic_environment_blend.rgb + 
						(reflection_1.rgb * reflection_1.a * 256) * (1.0f-dynamic_environment_blend.rgb);
	return reflection * specular_reflectance_and_roughness.xyz * env_tint_color * low_frequency_specular_color;
	
//	return float3(lod, lod, lod) / 6.0f;
}
#endif // ENVMAP_TYPE_dynamic

/*
float3 calc_environment_map_dynamic_two_coat_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	reflect_dir.y= -reflect_dir.y;
	
	float4 reflection_0= texCUBEbias(dynamic_environment_map_0, float4(reflect_dir, specular_reflectance_and_roughness.w + env_bias)); 
	float4 reflection_1= texCUBEbias(dynamic_environment_map_1, float4(reflect_dir, specular_reflectance_and_roughness.w + env_bias)); 
	
	float3 reflection=  (reflection_0.rgb * reflection_0.a * 255) * dynamic_environment_blend + 
						(reflection_1.rgb * reflection_1.a * 255) * (1.0f-dynamic_environment_blend);

	float4 topcoat_0= texCUBEbias(dynamic_environment_map_0, float4(reflect_dir, env_topcoat_bias)); 
	float4 topcoat_1= texCUBEbias(dynamic_environment_map_1, float4(reflect_dir, env_topcoat_bias)); 
	
	float3 topcoat= (topcoat_0.rgb * topcoat_0.a * 255) * dynamic_environment_blend + 
					(topcoat_1.rgb * topcoat_1.a * 255) * (1.0f-dynamic_environment_blend);

	ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
	ssr_color.a = specular_reflectance_and_roughness.w;
	
	return ((reflection * specular_reflectance_and_roughness.xyz * env_tint_color) + (topcoat * env_topcoat_color)) * low_frequency_specular_color;
}
*/

#if (ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_from_flat_texture) || (ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_from_flat_texture_as_cubemap)

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_from_flat_texture_as_cubemap
PARAM_SAMPLER_CUBE(flat_environment_map);
#else
PARAM_SAMPLER_2D(flat_environment_map);
#endif
PARAM(float4, flat_envmap_matrix_x);		// envmap rotation matrix, dot xyz with world direction returns envmap.X					w component ignored
PARAM(float4, flat_envmap_matrix_y);		// envmap rotation matrix, dot xyz with world direction returns envmap.Y					w component ignored
PARAM(float4, flat_envmap_matrix_z);		// envmap rotation matrix, dot xyz with world direction returns envmap.Z (-1 = forward)		w component ignored
PARAM(float, hemisphere_percentage);

// ###ctchou $HACK $E3 bloom override
PARAM(float4, env_bloom_override);		// input		[R, G, B tint, alpha = percentage]
PARAM(float, env_bloom_override_intensity);		// input
PARAM(float3, env_bloom_override_output);				// output
#ifndef pc
#define BLOOM_OVERRIDE env_bloom_override_output
#endif

float3 calc_environment_map_from_flat_texture_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,								// normalized
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	float3 reflection= float3(1.0f, 0.0f, 0.0f);

	// fisheye projection	
	float3 envmap_dir;
	envmap_dir.x= dot(reflect_dir, flat_envmap_matrix_x.xyz);
	envmap_dir.y= dot(reflect_dir, flat_envmap_matrix_y.xyz);
	envmap_dir.z= dot(reflect_dir, flat_envmap_matrix_z.xyz);
	
	float radius= sqrt((envmap_dir.z+1.0f)/hemisphere_percentage);							// 1.0 = radius of texture (along X/Y axis)
																							// ###ctchou $PERF we could put the (+1.0f)/hemisphere percentage into the dot product with Z by modifying flat_envmap_matrix_z - but would require combining shader parameters
	
	float2 texcoord= envmap_dir.xy * radius / sqrt(dot(envmap_dir.xy, envmap_dir.xy));		// normalize x/y vector, and scale by radius to get fisheye projection
	texcoord= (1.0f+texcoord)*0.5f;															// convert to texture coordinate space (0..1)

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_from_flat_texture_as_cubemap
	float3 cube_texcoord = float3(
		1.0f,
		-((texcoord.y * 2.0f) - 1.0f),
		-((texcoord.x * 2.0f) - 1.0f));
	reflection = sampleCUBE(flat_environment_map, cube_texcoord);
#else
	reflection= sample2D(flat_environment_map, texcoord);
#endif

	ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
	ssr_color.a = specular_reflectance_and_roughness.w;
	
	// ###ctchou $HACK $E3 bloom override
#if (! defined(pc)) || (DX_VERSION == 11)
	BLOOM_OVERRIDE= max(color_to_intensity(reflection.rgb)-env_bloom_override.a, 0.0f) * env_bloom_override.rgb * env_bloom_override_intensity * g_exposure.rrr;
#endif
/*	// perspective projection
	float3 texcoord;
	texcoord.z= dot(reflect_dir, flat_envmap_matrix_w.xyz);					// ###ctchou $TODO $PERF pass the transformed point from the vertex shader
	if (texcoord.z < -0.001f)
	{
		texcoord.x= dot(reflect_dir, flat_envmap_matrix_x.xyz);
		texcoord.y= dot(reflect_dir, flat_envmap_matrix_y.xyz);
		reflection= sample2D(flat_environment_map, texcoord.xy / texcoord.z);
	}
*/
	return reflection * specular_reflectance_and_roughness.xyz * env_tint_color;
}

float3 calc_environment_map_from_flat_texture_as_cubemap_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,								// normalized
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	return calc_environment_map_from_flat_texture_ps(
		view_dir,
		normal,
		reflect_dir,
		specular_reflectance_and_roughness,
		low_frequency_specular_color,
		ssr_color);
}

#endif // ENVMAP_TYPE_from_flat_texture

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_custom_map
//PARAM_SAMPLER_CUBE(environment_map);
samplerCUBE environment_map : register(s1); // test

float calc_cubemap_lod(in float3 reflect_dir, in float roughness)
{
	float3 gradX = ddx(reflect_dir);
	float3 gradY = ddy(reflect_dir);
	float grad_x = dot(gradX, gradX);
	float grad_y = dot(gradY, gradY);
	float base_lod = 6.0f * sqrt(sqrt(max(grad_x, grad_y))) - 0.6f; // May be strange calculation?
	return max(base_lod, roughness * env_roughness_scale * 4);
}

float3 calc_environment_map_custom_map_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	reflect_dir.y = -reflect_dir.y;

	//float lod = calc_cubemap_lod(reflect_dir, specular_reflectance_and_roughness.w);
	
	
    float grad_x = length(ddx(reflect_dir));
    float grad_y = length(ddy(reflect_dir));
    float base_lod = 6.0f * sqrt(max(grad_x, grad_y)) - 0.6f;
    float lod = max(0.0f, specular_reflectance_and_roughness.w * env_roughness_scale * 4);

    float4 reflection = sampleCUBElod(environment_map, reflect_dir, lod);

    ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
    ssr_color.a = specular_reflectance_and_roughness.w * env_roughness_scale;

//#ifdef USE_SSR
//	float4 ibr = get_ssr(global_screen_uv, normal);
//	reflection.rgb = lerp(reflection.rgb, ibr.rgb, ibr.a);
//#endif

    return reflection.rgb * specular_reflectance_and_roughness.xyz * low_frequency_specular_color * env_tint_color * reflection.a * 256.0f;
}
float3 sample_environment_map_custom_map_ps(in float3 reflect_dir)
{
	reflect_dir.y = -reflect_dir.y;

	float4 reflection;
#ifdef pc

	float grad_x = length(ddx(reflect_dir));
	float grad_y = length(ddy(reflect_dir));
	float base_lod = 6.0f * sqrt(max(grad_x, grad_y)) - 0.6f;

	reflection = sampleCUBElod(environment_map, reflect_dir, 0.0f);
#else
	reflection = sampleCUBElod(environment_map, reflect_dir, 0.0f);
#endif

	return reflection.rgb;
}
#endif // ENVMAP_TYPE_custom_map

#if ENVMAP_TYPE(envmap_type) == ENVMAP_TYPE_dynamic_reach

	samplerCUBE dynamic_environment_map_0;		// declared by shaders\shader_options\env_map_dynamic.render_method_option
	samplerCUBE dynamic_environment_map_1;		// declared by shaders\shader_options\env_map_dynamic.render_method_option

float3 calc_environment_map_dynamic_reach_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir,
	in float4 specular_reflectance_and_roughness,
	in float3 low_frequency_specular_color,
	out float4 ssr_color)
{
	reflect_dir.y= -reflect_dir.y;

	float4 reflection_0, reflection_1;

#if defined(pc) && (DX_VERSION == 9)
	float grad_x= length(ddx(reflect_dir));
	float grad_y= length(ddy(reflect_dir));
	float base_lod= 6.0f * sqrt(max(grad_x, grad_y)) - 0.6f;
	float lod= max(0.0f, specular_reflectance_and_roughness.w * env_roughness_scale * 4);
	
	const float exp_bias = 4.0f; // exponential bias of 2^2 for dynamic cubes
	reflection_0= sampleCUBElod(dynamic_environment_map_0, reflect_dir, lod) * exp_bias;
	reflection_1= sampleCUBElod(dynamic_environment_map_1, reflect_dir, lod) * exp_bias;

	//float3 reflection=  (reflection_0.rgb*reflection_0.rgb * reflection_0.a * 64.0f);

	float3 reflection=  (reflection_0.rgb*reflection_0.rgb * reflection_0.a) * dynamic_environment_blend.w +
						(reflection_1.rgb*reflection_1.rgb * reflection_1.a) * (1.0f-dynamic_environment_blend.w);

#else	// xenon
	float grad_x= 0.0f;
	float grad_y= 0.0f;
	float base_lod= 0.0f;

	float lod= max(base_lod, offset_env_reflection_lod(specular_reflectance_and_roughness.w));

	reflection_0= sampleCUBElod(dynamic_environment_map_0, reflect_dir, lod + dynamic_environment_blend.x);
	#ifndef xenon
		// environment maps on xenon have an exponent adjustment of +2
		reflection_0 *= 4;
	#endif // xenon

	#ifdef must_be_environment
		float3 reflection=  (reflection_0.rgb*reflection_0.rgb * reflection_0.a);
	#else // !environment
	    reflection_1= sampleCUBElod(dynamic_environment_map_1, reflect_dir, lod + dynamic_environment_blend.y);
		#ifndef xenon
			// environment maps on xenon have an exponent adjustment of +2
			reflection_1 *= 4;
		#endif
	
		float3 reflection=  (reflection_0.rgb*reflection_0.rgb * reflection_0.a) * dynamic_environment_blend.w +
							(reflection_1.rgb*reflection_1.rgb * reflection_1.a) * (1.0f-dynamic_environment_blend.w);
	#endif // !environment
#endif

	ssr_color.rgb = env_tint_color * specular_reflectance_and_roughness.xyz;
	ssr_color.a = specular_reflectance_and_roughness.w * env_roughness_scale;

	return reflection * specular_reflectance_and_roughness.xyz * env_tint_color * low_frequency_specular_color;
}
#endif // ENVMAP_TYPE_dynamic_reach