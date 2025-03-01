#line 2 "source\rasterizer\hlsl\final_composite_base.hlsl"

#ifndef SCREENSHOT_COMBINE
#define POSTPROCESS_USE_CUSTOM_VERTEX_SHADER 1
#endif

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "postprocess.fx"
#include "utilities.fx"
#include "texture_xform.fx"
#include "final_composite_registers.fx"


LOCAL_SAMPLER_2D(surface_sampler, 0);		
LOCAL_SAMPLER_2D(dark_surface_sampler, 1);		
LOCAL_SAMPLER_2D(bloom_sampler, 2);	
uniform sampler2D unknown3 : register(s3);
LOCAL_SAMPLER_3D(color_grading0, 4);
LOCAL_SAMPLER_3D(color_grading1, 5);
LOCAL_SAMPLER_2D(depth_sampler, 6);		// depth of field
LOCAL_SAMPLER_2D(blur_sampler, 7);		// depth of field
LOCAL_SAMPLER_2D(blur_grade_sampler, 8);		// weapon zoom
LOCAL_SAMPLER_2D(noise_sampler, 9);		// reach noise


// define default functions, if they haven't been already

#ifndef COMBINE_HDR_LDR
#define COMBINE_HDR_LDR default_combine_hdr_ldr
#endif // !COMBINE_HDR_LDR

#ifndef CALC_BLOOM
#define CALC_BLOOM default_calc_bloom
#endif // !CALC_BLOOM

#ifndef CALC_BLEND
#define CALC_BLEND default_calc_blend
#endif // !CALC_BLEND



float4 default_combine_hdr_ldr(in float2 texcoord)							// supports multiple sources and formats, but much slower than the optimized version
{
#ifdef pc
	float4 accum=		sample2D(surface_sampler, texcoord);
	#ifdef APPLY_FIXES
		accum.rgb = pow(sqrt(accum.rgb), gamma_power);
	#endif
	float4 combined= accum;
	// HO cut this out, but hdr is still rendered.
#ifdef APPLY_FIXES
	float4 accum_dark=	sample2D(dark_surface_sampler, texcoord);
		accum_dark.rgb = pow(sqrt(accum_dark.rgb), gamma_power);
	combined= max(accum, accum_dark * DARK_COLOR_MULTIPLIER);		// convert_from_render_targets <-- for some reason this isn't optimized very well
#endif
#else // XENON
	
	float4 accum=		sample2D(surface_sampler, texcoord);
	if (LDR_gamma2)
	{
		accum.rgb *= accum.rgb;
	}

	float4 accum_dark=	sample2D(dark_surface_sampler, texcoord);
	if (HDR_gamma2)
	{
		accum_dark.rgb *= accum_dark.rgb;
	}
	accum_dark *= DARK_COLOR_MULTIPLIER;
	
/*	float4 combined= accum_dark - 1.0f;
	asm																		// combined = ( combined > 0.0f ) ? accum_dark : accum
	{
		cndgt combined, combined, accum_dark, accum
	};
*/
	float4 combined= max(accum, accum_dark);
#endif // XENON

	return combined;
}


float4 default_combine_optimized(in float2 texcoord)						// final game code: single sample LDR surface, use hardcoded hardware curve
{
    float4 ldr = sample2D(surface_sampler, texcoord);
    ldr.rgb = pow(sqrt(ldr.rgb), gamma_power);
    return ldr;
}


float4 default_calc_bloom(in float2 texcoord)
{
    float4 bloom_sample = tex2D_offset(bloom_sampler, transform_texcoord(texcoord, bloom_sampler_xform), 0, 0); // $PERF xform in vs
    //bloom_sample.rgb = pow(sqrt(bloom_sample.rgb), gamma_power);
    return bloom_sample;
}


float3 default_calc_blend(in float2 texcoord, in float4 combined, in float4 bloom)
{
#ifdef pc
	return combined + bloom;
#else // XENON
    return combined.rgb * (texcoord.x > 0.5f ? 1.0f : bloom.a) + bloom.rgb;
#endif // XENON
}

float4 apply_noise( in float2 noise_space_texcoord, in float4 input_color )
{
	float4 output_color= input_color;
	
    float4 noise= sample2D(noise_sampler, noise_space_texcoord);

	noise.xy=			noise.zz * noise_params.xy + noise_params.zw; // noize.zz monochrome A8, noise.zz Y8 PC
	output_color.rgb=	output_color.rgb * noise.xxx + noise.yyy;

	return output_color;
}

struct s_final_composite_output
{
    float4 position			: SV_Position;
    float2 texcoord			: TEXCOORD0;
    float4 xformed_texcoord : TEXCOORD1; // xy - pixel-space texcoord, zw - noise-space texcoord
};

#ifndef SCREENSHOT_COMBINE

s_final_composite_output default_vs(vertex_type IN)
{
    s_final_composite_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
	
    // Convert the [0,1] input texture coordinates into pixel space. Note that this transform must include the appropriate
	// scale and bias for screenshot tile offsets
	float2 pixel_space_texcoord= IN.texcoord * pixel_space_xform.xy + pixel_space_xform.zw;

	// Transform pixel space texture coordinates to tile the noise texture such as to maintain 1:1 fetch ratio
	float2 noise_space_texcoord= pixel_space_texcoord * noise_space_xform.xy + noise_space_xform.zw;

	OUT.xformed_texcoord= float4( pixel_space_texcoord, noise_space_texcoord );
	
	return OUT;
}

#endif // !SCREENSHOT_COMBINE

float4 default_ps(in s_final_composite_output input) : SV_Target
{
	// final composite
	float4 combined= COMBINE_HDR_LDR(input.texcoord);									// sample and blend full resolution render targets
	float4 bloom= CALC_BLOOM(input.texcoord);											// sample postprocessed buffer(s)
	float3 blend= CALC_BLEND(input.texcoord, combined, bloom);						// blend them together

	// apply hue and saturation (3 instructions)
	blend= mul(float4(blend, 1.0f), p_postprocess_hue_saturation_matrix);

	// apply contrast (4 instructions)
	float luminance= dot(blend, float3(0.333f, 0.333f, 0.333f));
#if DX_VERSION == 11
	if (luminance > 0)
#endif
	{
		blend *= pow(luminance, p_postprocess_contrast.x) / luminance;
	}

	// apply tone curve (4 instructions)
	float3 clamped  = min(blend, tone_curve_constants.xxx);		// default= 1.4938015821857215695824940046795		// r1

	float4 result;
	result.rgb= ((clamped.rgb * tone_curve_constants.w + tone_curve_constants.z) * clamped.rgb + tone_curve_constants.y) * clamped.rgb;		// default linear = 1.0041494251232542828239889869599, quadratic= 0, cubic= - 0.15;

   // color grading
   const float rSize = 1.0f / 16.0f;
   const float3 scale = 1.0f - rSize;
   const float3 offset = 0.5f * rSize;
   float3 cgTexC = result.rgb * scale + offset;
   float3 cg0 = sample3D(color_grading0, cgTexC).rgb;
   float3 cg1 = sample3D(color_grading1, cgTexC).rgb;
   result.rgb = lerp(cg0, cg1, cg_blend_factor.x);

	result.a= sqrt( dot(result.rgb, float3(0.299, 0.587, 0.114)) );
	
#ifdef APPLY_FIXES
	result= apply_noise(input.xformed_texcoord.zw, result);
#endif
	
	return result;
}
