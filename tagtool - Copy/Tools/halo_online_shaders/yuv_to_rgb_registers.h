#ifndef _YUV_TO_RGB_REGISTERS_H_
#define _YUV_TO_RGB_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_yuv_to_rgb_tor   	POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_yuv_to_rgb_tog   	POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define k_ps_yuv_to_rgb_tob   	POSTPROCESS_EXTRA_PIXEL_CONSTANT_2
#define k_ps_yuv_to_rgb_consts	POSTPROCESS_EXTRA_PIXEL_CONSTANT_3

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\yuv_to_rgb_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif