#line 1 "source\rasterizer\hlsl\screen.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"

//@generate screen

struct screen_output
{
	float4 HPosition	:SV_Position;
    float2 Texcoord		:TEXCOORD0;
    float3 color		:COLOR0;
};

screen_output default_vs(vertex_type IN)
{
    screen_output OUT;

    OUT.Texcoord = IN.texcoord;
    OUT.HPosition.xy= IN.position;
    OUT.HPosition.zw= 0.5f;
    OUT.color= IN.color;

    return OUT;
}

// pixel fragment entry points

float4 default_ps(screen_output IN) : SV_Target
{
    return float4(1.0f, 1.0f, 1.0f, 1.0f);
}
