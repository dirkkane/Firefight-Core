#ifndef _SPIKE_BLUR_REGISTERS_H_
#define _SPIKE_BLUR_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_spike_blur_source_pixel_size	POSTPROCESS_PIXELSIZE_PIXEL_CONSTANT
#define k_ps_spike_blur_offset_delta		POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_ps_spike_blur_initial_color		POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_spike_blur_delta_color			POSTPROCESS_EXTRA_PIXEL_CONSTANT_1

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\spike_blur_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif