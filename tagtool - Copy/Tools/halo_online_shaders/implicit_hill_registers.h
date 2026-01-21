#ifndef _IMPLICIT_HILL_REGISTERS_H_
#define _IMPLICIT_HILL_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#ifndef BOOL_CONSTANT_NAME
#define BOOL_CONSTANT_NAME(n) n
#endif

#define k_vs_implicit_hill_color 		CONSTANT_NAME(20)
#define k_vs_implicit_hill_z_scales 	CONSTANT_NAME(23) // <lower_z_offset, lower_scale, upper_z_offset - lower_z_offset, upper_scale - lower_scale>
#define k_vs_implicit_hill_transform1 	CONSTANT_NAME(24)
#define k_vs_implicit_hill_transform2 	CONSTANT_NAME(25)
#define k_vs_implicit_hill_transform3 	CONSTANT_NAME(26)

#define k_vs_implicit_hill_use_zscales 	BOOL_CONSTANT_NAME(7)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\implicit_hill_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
