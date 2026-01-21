#line 2 "source\rasterizer\hlsl\clear_letterbox.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

accum_pixel default_ps(screen_output IN) : SV_Target
{
	accum_pixel ret;
	ret.color = 0;
	ret.dark_color = 0;
	return ret;
}
