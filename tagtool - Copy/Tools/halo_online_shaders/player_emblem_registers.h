#ifndef _PLAYER_EMBLEM_REGISTERS_H_
#define _PLAYER_EMBLEM_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_emblem_color_background_argb  CONSTANT_NAME(55)
#define k_ps_emblem_color_icon1_argb CONSTANT_NAME(56)
#define k_ps_emblem_color_icon2_argb CONSTANT_NAME(57)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\player_emblem_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif