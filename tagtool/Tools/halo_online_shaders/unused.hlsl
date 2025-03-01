#line 2 "source\rasterizer\hlsl\unused.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen


float4 default_ps(screen_output IN) : SV_Target
{
	return float4(1.0f, 0.0f, 1.0f, 0.5f);
}
