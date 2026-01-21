#ifndef _HLSL_CONSTANT_ONESHOT_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _HLSL_CONSTANT_ONESHOT_FX_
#endif

#if DX_VERSION == 9

//NOTE: if you modify any of this, than you need to modify hlsl_constant_oneshot.h 

// Shader constants which are fair game (set prior to each draw call which uses them)
#define k_register_node_per_vertex_count		c230
#define k_register_position_compression_scale 	c12
#define k_register_position_compression_offset 	c13
#define k_register_uv_compression_scale_offset 	c14
#define k_register_node_start					c16
#define k_node_per_vertex_count					c0

#define k_alpha_test_shader_lighting_constant	c229

VERTEX_CONSTANT(float4, lighting, k_alpha_test_shader_lighting_constant);

VERTEX_CONSTANT(float4, Position_Compression_Scale, k_register_position_compression_scale);
VERTEX_CONSTANT(float4, Position_Compression_Offset, k_register_position_compression_offset);
VERTEX_CONSTANT(float4, UV_Compression_Scale_Offset, k_register_uv_compression_scale_offset);

#ifndef IGNORE_SKINNING_NODES
VERTEX_CONSTANT(int, Node_Per_Vertex_Count, k_node_per_vertex_count); 
VERTEX_CONSTANT(float4, Nodes[70][3], k_register_node_start); // !!!Actually uses c16-c227 because we own multiples of 4
VERTEX_CONSTANT(float4, Nodes_pad0, c226);
VERTEX_CONSTANT(float4, Nodes_pad1, c227);
#endif // IGNORE_SKINNING_NODES

PIXEL_CONSTANT( float4, k_ps_dominant_light_direction, c11);
PIXEL_CONSTANT( float4, k_ps_constant_shadow_alpha, c11);		// overlaps with k_ps_dominant_light_direction, but they aren't used at the same time
PIXEL_CONSTANT( float4, k_ps_dominant_light_intensity, c13);

PIXEL_CONSTANT(bool, dynamic_light_shadowing, b13);
PIXEL_CONSTANT(bool, is_normal_basemap, b14);

// Active camo constants

// set immediately before rendering
PIXEL_CONSTANT(float4, k_ps_active_camo_factor, c212);
// set at the start of render_transparents
PIXEL_CONSTANT(float4, k_ps_distort_bounds, c213);

// set for c_lightmap_shadows_view scope
PIXEL_CONSTANT(float2, shadow_map_pixel_size, c214);

#elif DX_VERSION == 11

CBUFFER_BEGIN(VertexCompressionVS)
	CBUFFER_CONST(VertexCompressionVS,		float4,		Position_Compression_Scale,		k_position_compression_scale)
	CBUFFER_CONST(VertexCompressionVS,		float4,		Position_Compression_Offset,	k_position_compression_offset)
	CBUFFER_CONST(VertexCompressionVS,		float4,		UV_Compression_Scale_Offset,	k_uv_compression_scale_offset)
CBUFFER_END

CBUFFER_BEGIN_FIXED(SkinningVS, 12)
	CBUFFER_CONST_ARRAY(SkinningVS,			float4,		Nodes, [70][3],					k_node_start)
CBUFFER_END

CBUFFER_BEGIN(AlphaTestShaderVS)
	CBUFFER_CONST(AlphaTestShaderVS,		float4,		lighting, 						k_alpha_test_shader_lighting_constant)
CBUFFER_END

CBUFFER_BEGIN(DominantLightPS)
	CBUFFER_CONST(DominantLightPS,			float4,		k_ps_dominant_light_direction,	k_ps_dominant_light_direction)
	CBUFFER_CONST(DominantLightPS,			float4,		k_ps_dominant_light_intensity,	k_ps_dominant_light_intensity)
CBUFFER_END

CBUFFER_BEGIN(DynamicLightPS)
	CBUFFER_CONST(DynamicLightPS,			float4,		k_ps_constant_shadow_alpha,		k_ps_constant_shadow_alpha)
	CBUFFER_CONST(DynamicLightPS,			bool,		dynamic_light_shadowing,		k_ps_bool_dynamic_light_shadowing)
CBUFFER_END

CBUFFER_BEGIN(ActiveCamoPS)
	CBUFFER_CONST(ActiveCamoPS,				float4,		k_ps_active_camo_factor,		k_ps_active_camo_factor)
	CBUFFER_CONST(ActiveCamoPS,				float4,		k_ps_distort_bounds,			k_ps_distort_bounds)
CBUFFER_END

#endif

#endif //ifndef _HLSL_CONSTANT_ONESHOT_FX_
