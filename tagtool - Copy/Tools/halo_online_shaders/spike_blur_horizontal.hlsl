#line 2 "source\rasterizer\hlsl\spike_blur_horizontal.hlsl"

#define USE_CUSTOM_POSTPROCESS_CONSTANTS

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "spike_blur_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float3 get_pixel_linear_y(float2 tex_coord)		// linear in Y, point in X
{
	tex_coord.y= (tex_coord.y / source_pixel_size.y) - 0.5;
	float2 texel0= float2(tex_coord.x, floor(tex_coord.y));

	float4 blend;
	blend.xy= tex_coord - texel0;
	blend.zw= 1.0 - blend.xy;

	texel0.y= (texel0.y + 0.5)* source_pixel_size.y;

	float2 texel1= texel0;
	texel1.y += source_pixel_size.y;

	float3 color=	blend.w * convert_from_bloom_buffer(sample2D(source_sampler, texel0))+
					blend.y * convert_from_bloom_buffer(sample2D(source_sampler, texel1));

	return color;
}


// pixel fragment entry points
float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample0= IN.texcoord + offset_delta.xy;

	float3 color_scale= initial_color;

	float3 color= color_scale * get_pixel_linear_y(sample0);
		
	for (int x= 1; x < 8; x++)
	{
		color_scale *= delta_color;
		sample0.xy += offset_delta.zw;
		color += color_scale * get_pixel_linear_y(sample0);
	}

	return convert_to_bloom_buffer(color);
}
