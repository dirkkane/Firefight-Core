#line 2 "source\rasterizer\hlsl\shadow_apply_point.hlsl"

//@generate tiny_position_only

//#define FASTER_SHADOWS

#define SAMPLE_PERCENTAGE_CLOSER sample_percentage_closer_point
float sample_percentage_closer_point(float3 fragment_shadow_position, float depth_bias);

#include "shadow_apply.hlsl"


float sample_percentage_closer_point(float3 fragment_shadow_position, float depth_bias)
{
	float shadow_depth= sample2D(shadow, fragment_shadow_position.xy).r;
	float depth_disparity= fragment_shadow_position.z - shadow_depth;
	return step(depth_disparity, depth_bias);
}
