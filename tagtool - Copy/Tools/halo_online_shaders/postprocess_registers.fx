#ifndef _POSTPROCESS_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _POSTPROCESS_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "postprocess_registers.h"

#ifndef SKIP_POSTPROCESS_EXPOSURE_REGISTERS
PIXEL_CONSTANT(float4, g_exposure, c0 );
PIXEL_CONSTANT(float4, g_alt_exposure, c12);			// self-illum exposure, unused, unused, unused
PIXEL_CONSTANT(bool, LDR_gamma2, b14);					// ###ctchou $TODO $PERF remove these when we settle on a render target format
PIXEL_CONSTANT(bool, HDR_gamma2, b15);
#endif

#ifndef USE_CUSTOM_POSTPROCESS_CONSTANTS

PIXEL_CONSTANT( float4, pixel_size, POSTPROCESS_PIXELSIZE_PIXEL_CONSTANT );
PIXEL_CONSTANT( float4, scale,		POSTPROCESS_DEFAULT_PIXEL_CONSTANT );

PIXEL_CONSTANT(float4x3, p_postprocess_hue_saturation_matrix, k_postprocess_hue_saturation_matrix);
PIXEL_CONSTANT(float4, p_postprocess_contrast, k_postprocess_contrast);

#endif

#elif DX_VERSION == 11

#ifndef DEFINE_CPP_CONSTANTS
#include "hlsl_constant_persist.fx"
#endif

CBUFFER_BEGIN(PostProcessPS)
	CBUFFER_CONST(PostProcessPS,	float4,		pixel_size,								k_postprocess_pixel_size)
	CBUFFER_CONST(PostProcessPS,	float4, 	scale,									k_postprocess_scale)
	CBUFFER_CONST(PostProcessPS,	float4x3,	p_postprocess_hue_saturation_matrix,	k_postprocess_hue_saturation_matrix)
	CBUFFER_CONST(PostProcessPS,	float4,		p_postprocess_contrast,					k_postprocess_contrast)
CBUFFER_END

#endif

#endif
