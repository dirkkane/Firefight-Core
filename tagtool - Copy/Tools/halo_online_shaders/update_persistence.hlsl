#line 2 "source\rasterizer\hlsl\update_persistence.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);
LOCAL_SAMPLER_2D(previous_sampler, 1);

// how fast the persistence fades.  0.05 is about as slow as you want to go, and higher numbers fade faster
#define k_persistent_fadeout_speed 0.8

// pixel fragment entry points
float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample0= IN.texcoord; // - 0.5 * source_pixel_size;

 	float3 color= convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
 	sample0.x += pixel_size.x;
	color += 2*convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
 	sample0.x += pixel_size.x;
	color += 2*convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
	
	sample0.x -= pixel_size.x*2;
	sample0.y += pixel_size.y;
	color += 2*convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
 	sample0.x += pixel_size.x;
	color += 4*convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
	color += (k_persistent_fadeout_speed * 16) * convert_from_bloom_buffer(sample2D(source_sampler, sample0));
 	sample0.x += pixel_size.x;
	color += 2*convert_from_bloom_buffer(sample2D(previous_sampler, sample0));

	sample0.x -= pixel_size.x*2;
	sample0.y += pixel_size.y;
	color += convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
 	sample0.x += pixel_size.x;
	color += 2*convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
 	sample0.x += pixel_size.x;
	color += convert_from_bloom_buffer(sample2D(previous_sampler, sample0));
	
	color= color / (16 * (1.0 + k_persistent_fadeout_speed));

	return convert_to_bloom_buffer(color);
}
