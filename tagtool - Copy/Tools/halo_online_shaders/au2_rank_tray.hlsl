#line 2 "source\rasterizer\hlsl\au2_rank_tray.hlsl"

#define POSTPROCESS_COLOR
#define FADEIN0 (9.0f / 114.0f)
#define FADEOUT0 (57.0f / 114.0f)
#define FADEIN1 (63.0f / 114.0f)

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	// set color channel to semi-transparent black
	float4 color;
	color.a= 0.7f;
	color.rgb= 0;
	
	if (IN.texcoord.x <= FADEIN0)
	{
		color.a = 0;
	}
	else if (IN.texcoord.x >= FADEOUT0 && IN.texcoord.x < FADEIN1)
	{
		color.a = 0;
	}
	
	// apply input color (nescessary to get UI animations)
 	color*= IN.color;
 	
 	return color*scale;
}
