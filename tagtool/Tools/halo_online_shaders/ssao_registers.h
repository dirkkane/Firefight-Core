#ifndef _SSAO_REGISTERS_H_
#define _SSAO_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_ssao_texcoord_scale CONSTANT_NAME(240)
#define k_vs_ssao_frustum_scale CONSTANT_NAME(241)

#define k_ps_ssao_params POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_ssao_frustum_scale POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define k_ps_ssao_mv_1 POSTPROCESS_EXTRA_PIXEL_CONSTANT_2
#define k_ps_ssao_mv_2 POSTPROCESS_EXTRA_PIXEL_CONSTANT_3
#define k_ps_ssao_mv_3 POSTPROCESS_EXTRA_PIXEL_CONSTANT_4

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\ssao_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
