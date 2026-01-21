#ifndef _OVERHEAD_MAP_GEOMETRY_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _OVERHEAD_MAP_GEOMETRY_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "overhead_map_geometry_registers.h"

VERTEX_CONSTANT(float4, map_override, k_vs_overhead_map_geometry_override);
VERTEX_CONSTANT(float4, map_transform1, k_vs_overhead_map_geometry_transform1);
VERTEX_CONSTANT(float4, map_transform2, k_vs_overhead_map_geometry_transform2);
VERTEX_CONSTANT(float4, map_transform3, k_vs_overhead_map_geometry_transform3);
PIXEL_CONSTANT(float4, map_sphere, k_ps_overhead_map_geometry_sphere);
PIXEL_CONSTANT(float4, blend_factor, k_ps_overhead_map_geometry_blend_factor);

#elif DX_VERSION == 11

CBUFFER_BEGIN(OverheadMapGeometryVS)
	CBUFFER_CONST(OverheadMapGeometryVS,	float4,		map_override,		k_vs_overhead_map_geometry_override)
	CBUFFER_CONST(OverheadMapGeometryVS,	float4,		map_transform1,		k_vs_overhead_map_geometry_transform1)
	CBUFFER_CONST(OverheadMapGeometryVS,	float4,		map_transform2,		k_vs_overhead_map_geometry_transform2)
	CBUFFER_CONST(OverheadMapGeometryVS,	float4,		map_transform3,		k_vs_overhead_map_geometry_transform3)
CBUFFER_END

CBUFFER_BEGIN(OverheadMapGeometryPS)
	CBUFFER_CONST(OverheadMapGeometryPS,	float4,		map_sphere,			k_ps_overhead_map_geometry_sphere)
	CBUFFER_CONST(OverheadMapGeometryPS,	float4,		blend_factor,		k_ps_overhead_map_geometry_blend_factor)
CBUFFER_END

#endif

#endif
