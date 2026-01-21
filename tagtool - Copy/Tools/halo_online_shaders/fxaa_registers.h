#ifndef _FXAA_REGISTERS_H_
#define _FXAA_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_fxaa_texel_size CONSTANT_NAME(240)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\fxaa_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif