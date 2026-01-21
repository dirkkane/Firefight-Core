#ifndef _RADIAL_BLUR_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _RADIAL_BLUR_REGISTERS_FX_
#endif

#if DX_VERSION == 9

PIXEL_CONSTANT(float4, g_tint,         POSTPROCESS_DEFAULT_PIXEL_CONSTANT);
PIXEL_CONSTANT(float4, g_center_scale, POSTPROCESS_EXTRA_PIXEL_CONSTANT_0);
PIXEL_CONSTANT(float4, BLUR_WEIGHTS0,  POSTPROCESS_EXTRA_PIXEL_CONSTANT_1);
PIXEL_CONSTANT(float4, BLUR_WEIGHTS1,  POSTPROCESS_EXTRA_PIXEL_CONSTANT_2);
PIXEL_CONSTANT(float4, BLUR_WEIGHTS2,  POSTPROCESS_EXTRA_PIXEL_CONSTANT_3);
PIXEL_CONSTANT(float4, BLUR_WEIGHTS3,  POSTPROCESS_EXTRA_PIXEL_CONSTANT_4);

#elif DX_VERSION == 11

CBUFFER_BEGIN(RadialBlurPS)
	CBUFFER_CONST(RadialBlurPS,		float4, 	g_tint,         	k_ps_radial_blur_tint)
	CBUFFER_CONST(RadialBlurPS,		float4, 	g_center_scale, 	k_ps_radial_blur_center_scale)
	CBUFFER_CONST(RadialBlurPS,		float4, 	BLUR_WEIGHTS0,  	k_ps_radial_blur_weights0)
	CBUFFER_CONST(RadialBlurPS,		float4, 	BLUR_WEIGHTS1,  	k_ps_radial_blur_weights1)
	CBUFFER_CONST(RadialBlurPS,		float4, 	BLUR_WEIGHTS2,  	k_ps_radial_blur_weights2)
	CBUFFER_CONST(RadialBlurPS,		float4, 	BLUR_WEIGHTS3,  	k_ps_radial_blur_weights3)	
CBUFFER_END

#endif

#endif
