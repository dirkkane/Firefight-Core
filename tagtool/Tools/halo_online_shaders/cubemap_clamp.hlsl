#line 2 "source\rasterizer\hlsl\cubemap_clamp.hlsl"

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "cubemap_registers.fx"
//@generate screen

LOCAL_SAMPLER_CUBE(source_sampler, 0);

#define scale param

struct screen_output
{
	float4 position	:POSITION;
	float2 texcoord	:TEXCOORD0;
};

screen_output default_vs(vertex_type IN)
{
	screen_output OUT;

	OUT.texcoord = IN.texcoord;
	OUT.position.xy= IN.position;
	OUT.position.zw= 1.0f;

	return OUT;
}

float4 sample_cube_map(float3 direction)
{
	direction.y= -direction.y;
	return sampleCUBE(source_sampler, direction);
}

float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample0= IN.texcoord;
	
	float3 direction;
	direction= forward - (sample0.y*2-1)*up - (sample0.x*2-1)*left;
	direction= direction * (1.0 / sqrt(dot(direction, direction)));

 	float4 color= sample_cube_map(direction);

	color= ((isnan(color) || any(color < 0)) ? 0.0f : isinf(color) ? scale : min(color, scale));		// if it's NAN, replace with zero, if it's INF, replace with max, otherwise, clamp
 	
 	return color;
}
