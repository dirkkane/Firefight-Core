#ifndef __BLEND_FX__
#define __BLEND_FX__

#ifdef TEST_CATEGORY_OPTION

	#define BLEND_MODE(mode) TEST_CATEGORY_OPTION(blend_mode, mode)

#else

	#define BLEND_TYPE(blend_type) BLEND_TYPE_##blend_type
	#define BLEND_TYPE_opaque 0
	#define BLEND_TYPE_additive 1
	#define BLEND_TYPE_multiply 2
	#define BLEND_TYPE_alpha_blend 3
	#define BLEND_TYPE_double_multiply 4
	#define BLEND_TYPE_pre_multiplied_alpha 5

	#define BLEND_MODE(mode) BLEND_TYPE(blend_type) == BLEND_TYPE_##mode

#endif

// define blend source
#define BLEND_SOURCE(alpha_blend_source) BLEND_SOURCE_##alpha_blend_source
#define BLEND_SOURCE_albedo_alpha_without_fresnel			1
#define BLEND_SOURCE_albedo_alpha							2
#define BLEND_SOURCE_opacity_map_alpha						3
#define BLEND_SOURCE_opacity_map_rgb						4
#define BLEND_SOURCE_opacity_map_alpha_and_albedo_alpha		5

#define ALPHA_BLEND_SOURCE(source)		BLEND_SOURCE(alpha_blend_source) == BLEND_SOURCE_##source

//default
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target

#if BLEND_MODE(opaque)
#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target
#define ALPHA_CHANNEL_OUTPUT output_alpha
#define BLEND_FOG_INSCATTER_SCALE 1.0
#endif

#if BLEND_MODE(additive)
#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target
#define ALPHA_CHANNEL_OUTPUT 0.0
#define BLEND_FOG_INSCATTER_SCALE 0.0
#define NO_ALPHA_TO_COVERAGE
#endif

#if BLEND_MODE(multiply)
#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target_multiplicative
#define BLEND_MULTIPLICATIVE 1.0
#define ALPHA_CHANNEL_OUTPUT 1.0
#define NO_ALPHA_TO_COVERAGE
#endif

#if BLEND_MODE(alpha_blend)
#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target
#define ALPHA_CHANNEL_OUTPUT albedo.w
#define BLEND_FOG_INSCATTER_SCALE 1.0
#define NO_ALPHA_TO_COVERAGE
#endif

#if BLEND_MODE(double_multiply)
#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target_multiplicative
#define BLEND_MULTIPLICATIVE 2.0
#define ALPHA_CHANNEL_OUTPUT 1.0
#define NO_ALPHA_TO_COVERAGE
#endif

#if BLEND_MODE(pre_multiplied_alpha)
#undef CONVERT_TO_RENDER_TARGET_FOR_BLEND
#define CONVERT_TO_RENDER_TARGET_FOR_BLEND convert_to_render_target_premultiplied_alpha
#define ALPHA_CHANNEL_OUTPUT albedo.w
#define BLEND_FOG_INSCATTER_SCALE 1.0
#define NO_ALPHA_TO_COVERAGE
#endif

/* ------- alpha blend source */

float opacity_fresnel_coefficient;
float opacity_fresnel_curve_steepness;
float opacity_fresnel_curve_bias;

sampler opacity_texture;
float4 opacity_texture_xform;

static float calc_fresnel_opacity(
	in float fresnel_coefficient,
	in float fresnel_curve_steepness,
	in float fresnel_curve_bias,	
	in float3 surface_normal,
	in float3 view_dir)
{
	const float n_dot_v= dot(surface_normal, view_dir);
	float fresnel_opacity= 			
			fresnel_coefficient* pow(saturate(1.0 - n_dot_v), fresnel_curve_steepness) + 
			fresnel_curve_bias;		
	if (n_dot_v > 0.0)
		return saturate(fresnel_opacity);
	else
		return 0.0f;
}

void calc_alpha_blend_opacity(		
	in float albedo_opacity,
	in float3 surface_normal,
	in float3 view_dir,
	in float2 texcoord,
	out float final_opacity,		
	out float specular_scalar)		// scale specular and envmap	
{		
	final_opacity= albedo_opacity;
	specular_scalar= 1.0f;

#ifdef PIXEL_SHADER

	#if defined(BLEND_MODE_OFF) || ALPHA_BLEND_SOURCE(albedo_alpha_without_fresnel)			

	#else		
			
		float fresnel_opacity= calc_fresnel_opacity(
			opacity_fresnel_coefficient, opacity_fresnel_curve_steepness, opacity_fresnel_curve_bias,
			surface_normal, view_dir);

		#if ALPHA_BLEND_SOURCE(albedo_alpha)
			final_opacity= 1.0f - (1 - albedo_opacity)*(1 - fresnel_opacity);

		#else
			float4 opacity= tex2D(opacity_texture, texcoord*opacity_texture_xform.xy + opacity_texture_xform.zw);

			#if ALPHA_BLEND_SOURCE(opacity_map_alpha)
				final_opacity= 1.0f - (1 - opacity.a)*(1 - fresnel_opacity);
			#endif

			#if  ALPHA_BLEND_SOURCE(opacity_map_rgb)
				const float monochorme= dot(opacity.rgb, float3(0.2126f, 0.7152f, 0.0722f));
				final_opacity= 1.0f - (1 - monochorme)*(1 - fresnel_opacity);
			#endif

			#if  ALPHA_BLEND_SOURCE(opacity_map_alpha_and_albedo_alpha)
				final_opacity= 1.0f - (1 - opacity.a)*(1 - fresnel_opacity)*(1 - albedo_opacity);
			#endif

		#endif
		specular_scalar= 1.0f + fresnel_opacity;

	#endif

#endif //PIXEL_SHADER
}


#endif //__BLEND_FX__