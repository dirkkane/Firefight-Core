#ifndef _DECORATORS_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _DECORATORS_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "decorators_registers.h"

//int4 test :register(i10);

// light data goes where node data would normally be
VERTEX_CONSTANT(float4, v_simple_light_count, k_vs_decorators_light_count);
VERTEX_CONSTANT(float4, v_simple_lights[5 * k_maximum_simple_light_count], k_vs_decorators_lights); 

VERTEX_CONSTANT(float4, instance_compression_offset, k_vs_decorators_instance_compression_offset);
VERTEX_CONSTANT(float4, instance_compression_scale, k_vs_decorators_instance_compression_scale);

// Instance data holds the index count of one instance, as well as an index offset
// for drawing index buffer subsets.
VERTEX_CONSTANT(float4, instance_data, k_vs_decorators_instance_data);
VERTEX_CONSTANT(float4, LOD_constants, k_vs_decorators_lod_constants);
VERTEX_CONSTANT(float4, translucency, k_vs_decorators_translucency);

VERTEX_CONSTANT(float3, sun_direction, k_vs_decorators_sun_direction);

VERTEX_CONSTANT(float3, sun_color, k_vs_decorators_sun_color);
PIXEL_CONSTANT(float3, contrast, k_ps_decorators_contrast);

VERTEX_CONSTANT(float4, wave_flow, k_vs_decorators_wave_flow);		// phase direction + frequency

#ifdef DECORATOR_EDIT

VERTEX_CONSTANT(float4, instance_position_and_scale, k_vs_decorators_instance_position_and_scale);
VERTEX_CONSTANT(float4, instance_quaternion, k_vs_decorators_instance_quaternion);

#endif

#elif DX_VERSION == 11

CBUFFER_BEGIN(DecoratorsLightsVS)
	CBUFFER_CONST_ARRAY(DecoratorsLightsVS,		float4, 	v_simple_lights,		[5 * k_maximum_simple_light_count],		k_vs_decorators_lights)
	CBUFFER_CONST(DecoratorsLightsVS,			float4, 	v_simple_light_count,											k_vs_decorators_lights_count)
CBUFFER_END

CBUFFER_BEGIN(DecoratorsVS)
	CBUFFER_CONST(DecoratorsVS,					float4,		instance_compression_offset,									k_vs_decorators_instance_compression_offset)
	CBUFFER_CONST(DecoratorsVS,					float4,		instance_compression_scale,										k_vs_decorators_instance_compression_scale)
	CBUFFER_CONST(DecoratorsVS,					float4,		instance_data,													k_vs_decorators_instance_data)
	CBUFFER_CONST(DecoratorsVS,					float4,		LOD_constants,													k_vs_decorators_lod_constants)
	CBUFFER_CONST(DecoratorsVS,					float4,		translucency,													k_vs_decorators_translucency)
	CBUFFER_CONST(DecoratorsVS,					float4,		wave_flow,														k_vs_decorators_wave_flow)
CBUFFER_END

CBUFFER_BEGIN(DecoratorsGlobalsVS)
	CBUFFER_CONST(DecoratorsGlobalsVS,			float3,		sun_direction,													k_vs_decorators_sun_direction)
	CBUFFER_CONST(DecoratorsGlobalsVS,			float,		sun_direction_pad,												k_vs_decorators_sun_direction_pad)
	CBUFFER_CONST(DecoratorsGlobalsVS,			float3,		sun_color,														k_vs_decorators_sun_color)
	CBUFFER_CONST(DecoratorsGlobalsVS,			float,		sun_color_pad,													k_vs_decorators_sun_color_pad)
CBUFFER_END

CBUFFER_BEGIN(DecoratorsEditVS)
	CBUFFER_CONST(DecoratorsEditVS,				float4,		instance_position_and_scale,									k_vs_decorators_instance_position_and_scale)
	CBUFFER_CONST(DecoratorsEditVS,				float4,		instance_quaternion,											k_vs_decorators_instance_quaternion)
CBUFFER_END

CBUFFER_BEGIN(DecoratorsPS)
	CBUFFER_CONST(DecoratorsPS,					float3,		contrast,														k_ps_decorators_contrast)
	CBUFFER_CONST(DecoratorsPS,					float,		contrast_pad,													k_ps_decorators_contrast_pad)
CBUFFER_END
	
#endif

#endif
