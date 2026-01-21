#line 2 "source\rasterizer\hlsl\write_depth.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "deform.fx"
#include "utilities.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

//@generate world

struct VS_INPUT
{
	float3 vPos : POSITION;
	float3 vColor : TEXCOORD0;
	float3 vNormal : NORMAL;
};

struct VS_OUTPUT
{
	float4 pos : SV_Position;
	float3 color : TEXCOORD0;
	float3 normal : TEXCOORD1;
};

VS_OUTPUT default_vs(VS_INPUT input)
{
	VS_OUTPUT output;

	float4 world_pos;
	world_pos.xyz= transform_point(float4(input.vPos, 1.0f), Nodes[0]);
	world_pos.w= 1.0f;
	output.pos= mul(world_pos, View_Projection);
	output.color= input.vColor;
	output.normal= normalize(input.vPos);

	return output;
}

accum_pixel default_ps(VS_OUTPUT input)
{

	float4 out_color= float4(input.color * g_exposure.rrr, 1.0f);

    float3 sun= pow(max(dot(p_lighting_constant_0.xyz, normalize(input.normal)), 0.0f), p_lighting_constant_0.w) * p_lighting_constant_1.rgb;
    out_color.rgb+= sun;

	return convert_to_render_target(out_color, true, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
		
}
