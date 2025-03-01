#line 2 "source\rasterizer\hlsl\rotate_2d.hlsl"

//#define USE_CUSTOM_POSTPROCESS_CONSTANTS

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "apply_color_matrix_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);


// pixel fragment entry points
float4 default_ps(screen_output IN) : SV_Target
{
	float4 color= sample2D(source_sampler, IN.texcoord);

	float4 dest_color;
	dest_color.r= dot(dest_red.rgba,	color.rgba);
	dest_color.g= dot(dest_green.rgba,	color.rgba);
	dest_color.b= dot(dest_blue.rgba,	color.rgba);
	dest_color.a= dot(dest_alpha.rgba,	color.rgba);

	return dest_color;
}
