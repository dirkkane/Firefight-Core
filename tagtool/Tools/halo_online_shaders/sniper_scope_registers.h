#ifndef _SNIPER_SCOPE_REGISTERS_H_
#define _SNIPER_SCOPE_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_sniper_scope_texture_params CONSTANT_NAME(9)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\sniper_scope_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
