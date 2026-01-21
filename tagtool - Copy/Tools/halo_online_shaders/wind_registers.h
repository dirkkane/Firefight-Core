#ifndef _WIND_REGISTERS_H_
#define _WIND_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_wind_data CONSTANT_NAME(243)
#define k_vs_wind_data2 CONSTANT_NAME(244)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\wind_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif