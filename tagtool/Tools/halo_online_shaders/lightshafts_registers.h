#ifndef _LIGHTSHAFTS_REGISTERS_H_
#define _LIGHTSHAFTS_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_lightshafts_tint       POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_ps_lightshafts_sun_pos    POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_lightshafts_inner_size POSTPROCESS_EXTRA_PIXEL_CONSTANT_1

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\lightshafts_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
