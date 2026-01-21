#ifndef _DOWNSAMPLE_REGISTERS_H_
#define _DOWNSAMPLE_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_downsample_intensity_vector POSTPROCESS_EXTRA_PIXEL_CONSTANT_0

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\downsample_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif