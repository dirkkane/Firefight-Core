#line 1 "source\rasterizer\hlsl\hlsl_vertex_types.h"

// data from application vertex buffer
struct world_vertex 
{
    float3 Position		:POSITION;
    float2 UV			:TEXCOORD0;
    float3 Normal		:NORMAL;
    float3 Tangent		:TANGENT;
    float3 Binormal		:BINORMAL;
};

struct rigid_vertex 
{
	float3 Position		:POSITION;
	float2 UV			:TEXCOORD0;
    float3 Normal		:NORMAL;
    float3 Tangent		:TANGENT;
    float3 Binormal		:BINORMAL;
};

struct skinned_vertex 
{
    float3 Position		:POSITION;
    float2 UV			:TEXCOORD0;
    float3 Normal		:NORMAL;
    float3 Tangent		:TANGENT;
    float3 Binormal		:BINORMAL;
    float node_indices[4] :BLENDINDICES;
    float node_weights[4] :BLENDWEIGHT;
};

struct screen_vertex 
{
    float2 Position		:POSITION;
    float2 UV			:TEXCOORD0;
};

struct debug_vertex
{
	float3 Position		:POSITION;
	float3 Color		:COLOR0;
};

// data passed from vertex shader and interpolated for pixel shader
struct vertex_fragment 
{
    float4 HPosition	:POSITION;
    float2 TexCoord		:TEXCOORD0;
    float3 LightVec		:TEXCOORD1;
	float3 EyeVec		:TEXCOORD2;
};

