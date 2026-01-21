#ifndef _SHADOW_APPLY_REGISTERS_H_
#define _SHADOW_APPLY_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#ifndef INT_CONSTANT_NAME
#define INT_CONSTANT_NAME(n) n
#endif

#define k_ps_shadow_apply_occlusion_spheres_count			INT_CONSTANT_NAME(1)
#define k_ps_shadow_apply_view_inverse_matrix				CONSTANT_NAME(100)
#define k_ps_shadow_apply_occlusion_spheres					CONSTANT_NAME(114)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\shadow_apply_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif