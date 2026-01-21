#ifndef _OVERHEAD_MAP_GEOMETRY_REGISTERS_H_
#define _OVERHEAD_MAP_GEOMETRY_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_overhead_map_geometry_override 	CONSTANT_NAME(19)
#define k_vs_overhead_map_geometry_transform1 	CONSTANT_NAME(20)
#define k_vs_overhead_map_geometry_transform2 	CONSTANT_NAME(21)
#define k_vs_overhead_map_geometry_transform3 	CONSTANT_NAME(22)
#define k_ps_overhead_map_geometry_sphere		CONSTANT_NAME(23)
#define k_ps_overhead_map_geometry_blend_factor CONSTANT_NAME(24)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\overhead_map_geometry_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif