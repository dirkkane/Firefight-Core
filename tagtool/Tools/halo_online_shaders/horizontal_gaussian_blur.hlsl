#line 2 "source\rasterizer\hlsl\horizontal_gaussian_blur.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(target_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample= IN.texcoord;

//	sample.y += texture_size.y / 2;
//	sample.x= sample0.x - 4.5 * texture_size.x;	// 4.5

	sample.x -= 5.0 * pixel_size.x;	// -5								
	float3 color= (1/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// -4
	color += (10/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// -3
	color += (45/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// -2
	color += (120/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// -1
	color += (210/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// 0
	color += (252/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// +1
	color += (210/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// +2
	color += (120/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// +3
	color += (45/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// +4
	color += (10/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	sample.x += pixel_size.x;			// +5
	color += (1/1024.0) *convert_from_bloom_buffer(sample2D(target_sampler, sample));

	return convert_to_bloom_buffer(color);
}
