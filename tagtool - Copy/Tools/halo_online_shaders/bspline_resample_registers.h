#ifndef _BSPLINE_RESAMPLE_REGISTERS_H_
#define _BSPLINE_RESAMPLE_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_bspline_resample_surface_sampler_xform CONSTANT_NAME(3)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\bspline_resample_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif