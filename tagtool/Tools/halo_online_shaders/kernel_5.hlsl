#line 2 "source\rasterizer\hlsl\kernel_5.hlsl"

#define XENON_PIXEL_SIZE float2(1/1152.0f,1/648.0f)
#define BLUR_KERNEL_RADIUS 5

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "kernel_5_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(target_sampler, 0);

float2 calculate_pixel_scale(float2 size)
{
    return XENON_PIXEL_SIZE / size;
}

float get_gaussian_distribution_weight(float sigma, int weight_index)
{
    float x = weight_index / sigma;
    float weight = exp(-x * x * 4.5);
    return weight;
}

float4 dynamic_blur_vertical(float2 texcoord)
{	
    float4 sample_occlusion = 0.0f;
    float4 weighted_occlusion_sum = 0.0f;
    float total_weight = 0.0f;

    float filter_radius = max(BLUR_KERNEL_RADIUS * calculate_pixel_scale(pixel_size.xy), 2);

    int number_of_taps = filter_radius * 2 + 1;
    float4 sample_texcoord = 0.0f;

	[loop]
    for (int sample_index = 0; sample_index < number_of_taps; sample_index++)
    {
        float location_delta = sample_index - filter_radius; // Distance from center of filter
        sample_texcoord.xy = float2(texcoord.x, texcoord.y + location_delta * pixel_size.y);
        sample_occlusion = tex2Dlod(target_sampler, float4(sample_texcoord.xy, 0, 0)).rgba;
		
        float fSampleWeight = get_gaussian_distribution_weight(filter_radius, location_delta);
        weighted_occlusion_sum += fSampleWeight * sample_occlusion;
        total_weight += fSampleWeight;
    }

    return weighted_occlusion_sum / total_weight;
}

float4 default_ps(screen_output IN) : SV_Target
{
	float2 sample= IN.texcoord;

#ifdef APPLY_FIXES
	// kernel_5 supplied is always identical to hardcoded kernel in blur_11_vertical
	return dynamic_blur_vertical(sample) * scale;
#endif
	
    float2 pixel_size_scale = float2(1.0f / 1152, 1.0f / 640) / pixel_size.xy;

#ifdef APPLY_FIXES
	float4 color=	kernel[0].z * sample2D(target_sampler, sample + kernel[0].xy * pixel_size.xy * pixel_size_scale) +
					kernel[1].z * sample2D(target_sampler, sample + kernel[1].xy * pixel_size.xy * pixel_size_scale) +
					kernel[2].z * sample2D(target_sampler, sample + kernel[2].xy * pixel_size.xy * pixel_size_scale) +
					kernel[3].z * sample2D(target_sampler, sample + kernel[3].xy * pixel_size.xy * pixel_size_scale) +
					kernel[4].z * sample2D(target_sampler, sample + kernel[4].xy * pixel_size.xy * pixel_size_scale);
#else
   float4 color=	kernel[0].z * sample2D(target_sampler, sample + kernel[0].xy * pixel_size.xy) +
					kernel[1].z * sample2D(target_sampler, sample + kernel[1].xy * pixel_size.xy) +
					kernel[2].z * sample2D(target_sampler, sample + kernel[2].xy * pixel_size.xy) +
					kernel[3].z * sample2D(target_sampler, sample + kernel[3].xy * pixel_size.xy) +
					kernel[4].z * sample2D(target_sampler, sample + kernel[4].xy * pixel_size.xy);
#endif

	return color * scale;
}