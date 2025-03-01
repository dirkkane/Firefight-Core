#line 1 "source\rasterizer\hlsl\downsample_4x4_block_bloom_new.hlsl"


#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

float4 default_ps( SCREEN_POSITION_INPUT(screen_position) ) : SV_Target0
{
    return float4(-1, -1, -1, 0);
}