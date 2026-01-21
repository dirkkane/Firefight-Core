#line 2 "source\rasterizer\hlsl\downsize_2x_target_with_curve.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample0= IN.texcoord;

//	float scalex= 1.0 / (1280.0-1.0);
//	float scaley= 1.0 / (720.0-1.0);

	float startx= sample0.x; // + 0.0 * scalex;

	sample0.x = startx;
	sample0.y = sample0.y; // + 0.0 * scaley;
	
 	float4 color= sample2D(source_sampler, sample0);
 	color*= color;
 	float4 accum= color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);		color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;

	sample0.x= startx;
	sample0.y += pixel_size.y;		color= sample2D(source_sampler, sample0);		color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;

	sample0.x= startx;
	sample0.y += pixel_size.y;		color= sample2D(source_sampler, sample0);		color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;

	sample0.x= startx;
	sample0.y += pixel_size.y;		color= sample2D(source_sampler, sample0);		color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;
	sample0.x += pixel_size.x;		color= sample2D(source_sampler, sample0);	 	color *= color;		accum += color;

	color= color / (16);

	return /*reconvert_render_target*/(color);
}
