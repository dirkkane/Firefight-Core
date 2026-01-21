#ifndef _DEFORM_FX_
#define _DEFORM_FX_

#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "entry.fx"

// Flip binormal if mirrored UV
float3 checkBinormal(in float3 tangent, in float3 binormal, in float3 normal)
{
	float3 res = binormal;
	//// check for mirrored UV
	//// TBN invariants
	//// dot(cross(n, t), b)
	//// dot(cross(b, n), t)
	//// dot(cross(t, b), n)
	//// Do not flip normal if it is already flipped (maya uv winding order)
#ifndef APPLY_FIXES
	if (!IS_VERTEX_TYPE(s_skinned_vertex) && !IS_VERTEX_TYPE(s_flat_skinned_vertex)) {
	   res *= sign(dot(cross(tangent, normal), binormal));
	}
#endif
	return res;
}

float3 transform_point(in float4 position, in float4 node[3])
{
	float3 result;

	result.x = dot(position, node[0]);
	result.y = dot(position, node[1]);
	result.z = dot(position, node[2]);

	return result;
}

float3 transform_point(in float3 position, in float4 node[3])
{
	return transform_point(float4(position, 1.0f), node);
}

float3 transform_vector(in float3 vect, in float4 node[3])
{
	float3 result;

	result.x= dot(vect, node[0].xyz);
	result.y= dot(vect, node[1].xyz);
	result.z= dot(vect, node[2].xyz);

	return result;
}

void decompress_position(inout float3 position)
{
	position = position * Position_Compression_Scale.xyz + Position_Compression_Offset.xyz;
}

void decompress_texcoord(inout float2 texcoord)
{
	texcoord = texcoord * UV_Compression_Scale_Offset.xy + UV_Compression_Scale_Offset.zw;
}

void decompress_deform_flat_world(inout s_world_vertex vertex) {}

void deform_flat_world(
	inout s_world_vertex vertex,
	out float4 local_to_world_transform[3])
{
	local_to_world_transform[0]= float4(1, 0, 0, 0);
	local_to_world_transform[1]= float4(0, 1, 0, 0);
	local_to_world_transform[2]= float4(0, 0, 1, 0);
}
void deform_flat_world(inout float4 pos)
{
	//pos.z -= 5e-6;
}

void decompress_deform_world(inout s_world_vertex vertex) {}

void deform_world(
	inout s_world_vertex vertex,
	out float4 local_to_world_transform[3])
{
	deform_flat_world(vertex, local_to_world_transform);
	
	vertex.binormal= checkBinormal(vertex.normal.xyz, vertex.binormal.xyz, vertex.tangent.xyz);
}
void deform_world(inout float4 pos) {}

void decompress_deform_flat_rigid(inout s_rigid_vertex vertex)
{
	decompress_position(vertex.position);
	decompress_texcoord(vertex.texcoord);
}

void deform_flat_rigid(
	inout s_rigid_vertex vertex,
	out float4 local_to_world_transform[3])
{
	decompress_deform_flat_rigid(vertex);

	local_to_world_transform = Nodes[0];
	vertex.position= transform_point(vertex.position, local_to_world_transform);
}
void deform_flat_rigid(inout float4 pos) {}

void decompress_deform_rigid(inout s_rigid_vertex vertex)
{
	decompress_deform_flat_rigid(vertex);
}

void deform_rigid(
	inout s_rigid_vertex vertex,
	out float4 local_to_world_transform[3])
{
	deform_flat_rigid(vertex, local_to_world_transform);
	
	vertex.binormal= checkBinormal(vertex.normal.xyz, vertex.binormal.xyz, vertex.tangent.xyz);
	
	vertex.normal= transform_vector(vertex.normal,local_to_world_transform);
	vertex.binormal= transform_vector(vertex.binormal, local_to_world_transform);
	vertex.tangent= transform_vector(vertex.tangent, local_to_world_transform);

	vertex.normal= normalize(vertex.normal);
	vertex.binormal= normalize(vertex.binormal);
	vertex.tangent= normalize(vertex.tangent);
}
void deform_rigid(inout float4 pos) {}

void decompress_deform_flat_skinned(inout s_skinned_vertex vertex)
{
	decompress_position(vertex.position);
	decompress_texcoord(vertex.texcoord);
}

void deform_flat_skinned(
	inout s_skinned_vertex vertex,
	out float4 local_to_world_transform[3])
{
	// normalize (with 1-norm) the node weights so that they sum to 1
	float sum_of_weights = dot(vertex.node_weights.xyzw, 1.0f);
	vertex.node_weights= vertex.node_weights/sum_of_weights;
	
	decompress_deform_flat_skinned(vertex);
	
	local_to_world_transform[0]=	Nodes[vertex.node_indices.x][0] * vertex.node_weights.x +
									Nodes[vertex.node_indices.y][0] * vertex.node_weights.y +
									Nodes[vertex.node_indices.z][0] * vertex.node_weights.z +
									Nodes[vertex.node_indices.w][0] * vertex.node_weights.w;
							
	local_to_world_transform[1]=	Nodes[vertex.node_indices.x][1] * vertex.node_weights.x +
									Nodes[vertex.node_indices.y][1] * vertex.node_weights.y +
									Nodes[vertex.node_indices.z][1] * vertex.node_weights.z +
									Nodes[vertex.node_indices.w][1] * vertex.node_weights.w;

	local_to_world_transform[2]=	Nodes[vertex.node_indices.x][2] * vertex.node_weights.x +
									Nodes[vertex.node_indices.y][2] * vertex.node_weights.y +
									Nodes[vertex.node_indices.z][2] * vertex.node_weights.z +
									Nodes[vertex.node_indices.w][2] * vertex.node_weights.w;

	vertex.position= transform_point(vertex.position, local_to_world_transform);
	
	vertex.binormal= checkBinormal(vertex.normal.xyz, vertex.binormal.xyz, vertex.tangent.xyz);
}
void deform_flat_skinned(inout float4 pos)
{
	pos.z -= 2e-5;
}

void decompress_deform_skinned(inout s_skinned_vertex vertex)
{
	decompress_deform_flat_skinned(vertex);
}

void deform_skinned(
	inout s_skinned_vertex vertex,
	out float4 local_to_world_transform[3])
{
	deform_flat_skinned(vertex, local_to_world_transform);

	vertex.normal= transform_vector(vertex.normal, local_to_world_transform);
	vertex.binormal= transform_vector(vertex.binormal, local_to_world_transform);
	vertex.tangent= transform_vector(vertex.tangent,local_to_world_transform);

	vertex.normal= normalize(vertex.normal);
	vertex.binormal= normalize(vertex.binormal);
	vertex.tangent= normalize(vertex.tangent);
}
void deform_skinned(inout float4 pos) { deform_flat_skinned(pos); }

void decompress_deform_decorator(inout s_decorator_vertex vertex) {}

void deform_decorator(
	inout s_decorator_vertex vertex,
	out float4 local_to_world_transform[3])
{
	// not used - see explicit transform in decorator render shader
}
void deform_decorator(inout float4 pos) {}

void decompress_deform_tiny_position(inout s_tiny_position_vertex vertex)
{
	// basically exactly the same as deform_rigid, but only acting on position
	decompress_position(vertex.position);
}

void deform_tiny_position(
	inout s_tiny_position_vertex vertex,
	out float4 local_to_world_transform[3])
{
	decompress_deform_tiny_position(vertex);

	local_to_world_transform = Nodes[0];
	vertex.position= transform_point(vertex.position, local_to_world_transform);
}
void deform_tiny_position(inout float4 pos) {}

void squish_local_view(inout float4 position)
{
	position.z+= v_squish_params.w*((v_squish_params.x*position.w-v_squish_params.y)*v_squish_params.z-position.z);
	
	if (ENTRY_POINT(entry_point)!= ENTRY_POINT_albedo)
	{
		if (IS_VERTEX_TYPE(s_skinned_vertex) || IS_VERTEX_TYPE(s_flat_skinned_vertex))
		{
			float squish_amount;
			if (v_mesh_squished)
				squish_amount= 0.000005f;
			else
				squish_amount= 0.00002f;
			position.z-= squish_amount;
		}
		
		if (ENTRY_POINT(entry_point)== ENTRY_POINT_active_camo)
			position.z -= 0.00002f;
	}
}

// Workaround for z-fighting problem...
// Calculation of output interpolator "position" must be completely segregated from the
// rest of the calculation by a scope with a runtime test.  DO NOT USE "position" for 
// anything after this call, other than a return value from the shader!
void always_local_to_view(
	inout vertex_type vertex,
	out float4 local_to_world_transform[3],
	out float4 position, bool is_albedo = false)
{
	//[branch]
	//if (v_always_true) // always true - poor man's isolate ;)
	//{
		deform(vertex, local_to_world_transform);
	//}
	position= mul(float4(vertex.position, 1.0f), View_Projection);
	
#ifndef APPLY_FIXES
	squish_local_view(position);
#endif
}

#endif
