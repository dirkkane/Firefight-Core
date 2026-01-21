#ifndef _CONTRAIL_UPDATE_REGISTERS_H
#define _CONTRAIL_UPDATE_REGISTERS_H

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_contrail_update_hidden_from_compiler CONSTANT_NAME(32)
#define k_vs_contrail_update_delta_time CONSTANT_NAME(33)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\contrail_update_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif