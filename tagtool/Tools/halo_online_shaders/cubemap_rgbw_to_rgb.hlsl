#line 1 "source\rasterizer\hlsl\cubemap_RGBW_to_RGB.hlsl"

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "cubemap_registers.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

//@generate screen

LOCAL_SAMPLER_CUBE(source_sampler, 0);

#define exposure param

struct screen_output
{
	float4 position	:SV_Position;
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
	float2 texcoord= IN.texcoord;
	
	float3 direction= forward - (texcoord.y*2-1)*up - (texcoord.x*2-1)*left;

	float4 color= exposure * sample_cube_map(direction);

	return float4(convert_from_dark_render_target(color), 0.0f);
}
