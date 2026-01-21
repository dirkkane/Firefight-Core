#ifndef _GAMMA_CORRECT_REGISTERS_H_
#define _GAMMA_CORRECT_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_gamma_correct_power POSTPROCESS_DEFAULT_PIXEL_CONSTANT

#elif DX_VERSION ==11

#define FX_FILE "rasterizer\\hlsl\\gamma_correct_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif