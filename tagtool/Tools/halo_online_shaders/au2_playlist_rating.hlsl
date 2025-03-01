#line 2 "source\rasterizer\hlsl\au2_playlist_rating.hlsl"

#define POSTPROCESS_COLOR

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "au2_playlist_rating_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	float2 texcoord= IN.texcoord;
	float4 color_0, color_1, color_2, color_3, color_4;

	color_0 = sample2D(source_sampler, texcoord);
	color_1 = sample2Doffset(source_sampler, texcoord, int2(-1, 0));
	color_2 = sample2Doffset(source_sampler, texcoord, int2(1, 0));
	color_3 = sample2Doffset(source_sampler, texcoord, int2(0, -1));
	color_4 = sample2Doffset(source_sampler, texcoord, int2(0, 1));
	
	if (IN.texcoord.x < uv_coords.x) color_1 = color_0;
	if (IN.texcoord.x > uv_coords.z) color_2 = color_0;
	if (IN.texcoord.y < uv_coords.y) color_3 = color_0;
	if (IN.texcoord.y > uv_coords.w) color_4 = color_0;

	// set color channel to light gray
	color_0.rgb = 0.8f;
	color_0.a = (color_0.a + color_1.a + color_2.a + color_3.a + color_4.a) / 5;

	// apply input color (nescessary to get UI animations)
 	color_0*= IN.color;
 	
 	return color_0*scale;
}
