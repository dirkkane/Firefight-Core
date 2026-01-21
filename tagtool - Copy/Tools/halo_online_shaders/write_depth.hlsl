#line 2 "source\rasterizer\hlsl\write_depth.hlsl"

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "deform.fx"
#include "utilities.fx"

//@generate world

void default_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	out float4 position_copy : TEXCOORD0)
{
    float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(vertex, local_to_world_transform);
	}
	
	if (always_true)
	{
		position= mul(float4(vertex.position, 1.0f), View_Projection);
		position_copy= position;
	}
	else
	{
		position= float4(0,0,0,0);
		position_copy= position;
	}
}

#if DX_VERSION == 9
float4 default_ps(SCREEN_POSITION_INPUT(screen_position), in float4 position : TEXCOORD0) : SV_Target
{
	return float4(position.z, position.z, position.z, 1.0f);
}
#elif DX_VERSION == 11
void default_ps()
{
}
#endif
