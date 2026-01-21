#line 2 "source\rasterizer\hlsl\sniper_scope_stencil_pc.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"

//@generate screen

float4 default_ps(screen_output IN) : SV_Target
{
  float4 result= float4(0, 1, 0, 1);
	return scale * result;
}
