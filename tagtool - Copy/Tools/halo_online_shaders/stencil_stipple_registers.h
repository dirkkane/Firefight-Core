#ifndef _STENCIL_STIPPLE_REGISTERS_H_
#define _STENCIL_STIPPLE_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#ifndef BOOL_CONSTANT_NAME
#define BOOL_CONSTANT_NAME(n) n
#endif

#define k_ps_stencil_stipple_block_size CONSTANT_NAME(80)
#define k_ps_stencil_stipple_odd_bits BOOL_CONSTANT_NAME(1)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\stencil_stipple_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif