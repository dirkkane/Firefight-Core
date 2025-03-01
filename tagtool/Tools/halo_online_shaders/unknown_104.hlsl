
#define POSTPROCESS_USE_CUSTOM_VERTEX_SHADER

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "unknown_103_unknown_104_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(depthBuf, 0);
LOCAL_SAMPLER_2D(normBuf, 1);

screen_output default_vs(screen_output IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord * uv_scale_offset.xy + uv_scale_offset.zw;
	OUT.position.xy=	IN.position;
	OUT.position.zw=    1.0f;
	return OUT;
}

float4 default_ps(vertex_type IN) : SV_Target
{
    return float4(1, 0, 0, 0);
}