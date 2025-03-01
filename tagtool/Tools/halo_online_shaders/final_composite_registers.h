#ifndef _FINAL_COMPOSITE_REGISTERS_H_
#define _FINAL_COMPOSITE_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_final_composite_intensity					POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_ps_final_composite_tone_curve_constants		POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_final_composite_player_window_constants	POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define k_ps_final_composite_bloom_sampler_xform		POSTPROCESS_EXTRA_PIXEL_CONSTANT_2
#define k_ps_final_composite_cg_blend_factor			POSTPROCESS_EXTRA_PIXEL_CONSTANT_3
#define k_ps_final_composite_gamma_power				POSTPROCESS_EXTRA_PIXEL_CONSTANT_5

#define k_ps_final_composite_depth_constants			POSTPROCESS_EXTRA_PIXEL_CONSTANT_3
#define k_ps_final_composite_depth_constants2			POSTPROCESS_EXTRA_PIXEL_CONSTANT_4

#define k_ps_final_composite_noise_params				CONSTANT_NAME(11)

#define k_vs_final_composite_pixel_space_xform			CONSTANT_NAME(9)
#define k_vs_final_composite_noise_space_xform			CONSTANT_NAME(10)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\final_composite_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif