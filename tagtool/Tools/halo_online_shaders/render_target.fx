#ifndef _RENDER_TARGET_FX_
#define _RENDER_TARGET_FX_

#include "utilities.fx"

// our output format
struct accum_pixel
{
#ifdef PC_CPU
	   float4 color;
   #ifndef LDR_ONLY
	   float4 dark_color;
	   float4 ssr_color;
   #endif
#else
	   float4 color : COLOR0;			// LDR buffer output -> render target 0
   #ifndef LDR_ONLY
	   float4 dark_color : COLOR1;		// HDR buffer output -> render target 1
	#ifdef SSR_ENABLE
	   float4 ssr_color : COLOR2;		// SSR buffer output -> render target 2
	#endif
   #endif
#endif
};
	
// convert a color to the render target format
#ifdef PC_CPU
   accum_pixel convert_to_render_target(float4 color, bool clamp_positive, bool ignore_bloom_override)
#else
   accum_pixel convert_to_render_target(in float4 color, bool clamp_positive, bool ignore_bloom_override
#ifdef SSR_ENABLE
	,float4 ssr
#endif
)
#endif
{
	if (clamp_positive)
	{
		color.rgb= max(color.rgb, float3(0.0f, 0.0f, 0.0f));
	}
	accum_pixel result;
	result.color.rgb= color.rgb;
	result.color.a= color.a * LDR_ALPHA_ADJUST;

#ifndef LDR_ONLY
		result.dark_color.rgb= color.rgb / DARK_COLOR_MULTIPLIER;
	#ifdef BLOOM_OVERRIDE
		if (!ignore_bloom_override)
		{
			result.dark_color.rgb= BLOOM_OVERRIDE;
		}
	#endif // BLOOM_OVERRIDE
		result.dark_color.a= color.a * HDR_ALPHA_ADJUST;
	
	#ifdef SSR_ENABLE
		result.ssr_color = ssr;
	#endif
#endif

	//if (LDR_gamma2)
	//{
	//	result.color.rgb= safe_sqrt(result.color.rgb);
	//}
#ifndef LDR_ONLY
	//if (HDR_gamma2)
	//{
	//	result.dark_color.rgb= safe_sqrt(result.dark_color.rgb);
	//}
#endif

	return result;
}

// convert a color to the render target format
accum_pixel convert_to_render_target_premultiplied_alpha(in float4 color, bool clamp_positive, bool ignore_bloom_override
#ifdef SSR_ENABLE
	,float4 ssr
#endif
)
{
	color.xyz *= color.w;
    return convert_to_render_target(color, clamp_positive, ignore_bloom_override
#ifdef SSR_ENABLE
	, ssr
#endif
	);
}

accum_pixel convert_to_render_target_multiplicative(in float4 color, bool clamp_positive, bool ignore_bloom_override
#ifdef SSR_ENABLE
	,float4 ssr
#endif
)
{
	if (clamp_positive)
	{
		color.rgb= max(color.rgb, float3(0.0f, 0.0f, 0.0f));
	}
	accum_pixel result;	
	result.color= color * LDR_ALPHA_ADJUST;				// multiply all channels by the alpha correction factor
	
#ifndef LDR_ONLY
		result.dark_color= color;
	#ifdef BLOOM_OVERRIDE
		if (!ignore_bloom_override)
		{
			result.dark_color.rgb= BLOOM_OVERRIDE;
		}
	#endif // BLOOM_OVERRIDE
		result.dark_color *= HDR_ALPHA_ADJUST;		// multiply all channels by the alpha correction factor, and DON'T add in DARK_COLOR_MULTIPLIER
	
	#ifdef SSR_ENABLE
		result.ssr_color = ssr;
	#endif
#endif

	//if (LDR_gamma2)
	//{
	//	result.color.rgb= safe_sqrt(result.color.rgb);
	//}
#ifndef LDR_ONLY
	//if (HDR_gamma2)
	//{
	//	result.dark_color.rgb= safe_sqrt(result.dark_color.rgb);
	//}
#endif

	return result;
}


#ifndef LDR_ONLY
// converts from render-target format to linear light RGB	(dark a.k.a. HDR render target only)
float3 convert_from_dark_render_target(in float4 dark_color)
{
	if (HDR_gamma2)
	{
		dark_color.rgb *= dark_color.rgb;
	}
	return dark_color.rgb * DARK_COLOR_MULTIPLIER;
}
#endif


#ifndef LDR_ONLY
// converts from render-target format to linear light RGB
float3 convert_from_render_targets(in float4 color, in float4 dark_color)
{
//#ifdef pc
	//if (LDR_gamma2)
	//{
	//	color.rgb *= color.rgb;
	//}
	//if (HDR_gamma2)
	//{
	//	dark_color.rgb *= dark_color.rgb;
	//}
	return max(color.rgb, dark_color.rgb * DARK_COLOR_MULTIPLIER);
//#else // XENON
//	return max(color, dark_color);											// DARK_COLOR_MULTIPLIER is set as the texture's exponent bias on Xenon
//#endif
}
#endif


/*

// OLD CODE

float3 convert_from_render_targets(in float4 color,in float4 dark_color)
{
#ifndef pc
	// 7e3 (Xenon) - cheap ass approximation of the 7e3 curve (good enough for bloom, probably not for the final combine)
	color.rgb=		(exp2(color.rgb		 * 7.75)-1) / 214.2695;
	dark_color.rgb= (exp2(dark_color.rgb * 7.75)-1) / 214.2695;
#endif
	return max(color.rgb, dark_color.rgb * DARK_COLOR_MULTIPLIER);
}


// adjust HDR color for PC
//#ifndef TRUE_GAMMA
//#define TRUE_GAMMA true
//#endif
//	if (TRUE_GAMMA)
//	{
		// 'true' gamma (nvidia 6800)
//		result.dark_color.rgb= (color.rgb - 0.0281 * sqrt(color.rgb)) / DARK_COLOR_MULTIPLIER;
//	}
//	else
//	{
		// piecewise linear gamma (nvidia 7800)
//		result.dark_color.rgb= (color.rgb - 1/32.0f) / DARK_COLOR_MULTIPLIER;		// Note: 32.0f might change if DARK_COLOR_MULTIPLIER changes
//	}


// adjust HDR color for Xenon
	// piecewise linear gamma (xenon)
//	result.dark_color.rgb= (color.rgb - 1/4.0f) / DARK_COLOR_MULTIPLIER;			// ###ctchou $TODO why doesn't 1/32.0f work?  it should from the curves...
//	result.dark_color.a= color.a;

	// 7e3 gamma (xenon)
//	result.dark_color.rgb= (color.rgb * 1.82f - 0.015f) / DARK_COLOR_MULTIPLIER;	// these values are calibrated to DARK_COLOR_MULTIPLIER of 256
	result.dark_color.rgb= (color.rgb - 0.005f) / DARK_COLOR_MULTIPLIER;	// these values are calibrated to DARK_COLOR_MULTIPLIER of 256


// reconstruct 7e3
#ifndef pc
	// 7e3 (Xenon)
	float3 bits=	color.rgb * 1023;
	float3 e=		floor(bits / 128);
	float3 m=		bits - e * 128;
	color.rgb=		(min(e, 1) +	m/128) * exp2(max(e,1)-8);
	
	bits=			dark_color.rgb * 1023;
	e=				floor(bits / 128);
	m=				bits - e * 128;
	dark_color.rgb= (min(e, 1) +	m/128) * exp2(max(e,1)-8);
#endif


*/



#endif //_RENDER_TARGET_FX_