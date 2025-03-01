#ifndef _COPY_TARGET_REGISTERS_H_
#define _COPY_TARGET_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_copy_target_intensity POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_ps_copy_target_tone_curve_constants POSTPROCESS_EXTRA_PIXEL_CONSTANT_0

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\copy_target_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
