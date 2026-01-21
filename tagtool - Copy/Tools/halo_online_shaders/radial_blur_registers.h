#ifndef _RADIAL_BLUR_REGISTERS_H_
#define _RADIAL_BLUR_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_radial_blur_tint         	POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_ps_radial_blur_center_scale 	POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_radial_blur_weights0  		POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define k_ps_radial_blur_weights1  		POSTPROCESS_EXTRA_PIXEL_CONSTANT_2
#define k_ps_radial_blur_weights2  		POSTPROCESS_EXTRA_PIXEL_CONSTANT_3
#define k_ps_radial_blur_weights3  		POSTPROCESS_EXTRA_PIXEL_CONSTANT_4

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\radial_blur_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
