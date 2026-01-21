#ifndef _DECAL_REGISTERS_H_
#define _DECAL_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_decal_sprite CONSTANT_NAME(228)
#define k_vs_decal_pixel_kill_enabled 2

#define k_ps_decal_fade CONSTANT_NAME(32)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\decal_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif