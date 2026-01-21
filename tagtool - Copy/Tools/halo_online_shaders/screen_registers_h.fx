#ifndef _SCREEN_REGISTERS_H_
#define _SCREEN_REGISTERS_H_

#if DX_VERSION == 9

#define k_vs_screen_pixelspace_xform 250
#define k_vs_screen_screenspace_sampler_xform 251
#define k_ps_screen_screenspace_xform 200

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\screen_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
