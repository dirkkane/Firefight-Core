#ifndef _DEBUG_2D_REGISTERS_H_
#define _DEBUG_2D_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_debug_2d_fill_color CONSTANT_NAME(1)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\debug_2d_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
