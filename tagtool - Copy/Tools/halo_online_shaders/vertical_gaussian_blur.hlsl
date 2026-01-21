#line 2 "source\rasterizer\hlsl\vertical_gaussian_blur.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(target_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample= IN.texcoord;

//	sample.y= sample0.y - 4.5 * source_pixel_size.y;
//	sample.x += source_pixel_size.x / 2;

	sample.y -= 5.0 * pixel_size.y;	// -5
	float3 color= (1/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// -4
	color += (10/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// -3
	color += (45/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// -2
	color += (120/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// -1
	color += (210/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// 0
	color += (252/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// +1
	color += (210/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// +2
	color += (120/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// +3
	color += (45/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// +4
	color += (10/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.y += pixel_size.y;			// +5
	color += (1/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	return convert_to_bloom_buffer(color);
}
