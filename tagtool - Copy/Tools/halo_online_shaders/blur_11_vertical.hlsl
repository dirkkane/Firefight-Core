#line 2 "source\rasterizer\hlsl\blur_11_vertical.hlsl"

#define XENON_PIXEL_SIZE float2(1/1152.0f,1/648.0f)
#define BLUR_KERNEL_RADIUS 5

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(target_sampler, 0);
//float4 kernel[11] : register(c2);		// c2 through c12 are the kernel (r,g,b)

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

fast4 default_ps(screen_output IN) : SV_Target
{
	float2 sample= IN.texcoord;

#ifdef APPLY_FIXES
    return dynamic_blur_vertical(sample);
#endif

	// solution using bilinear filtering:
	// actually this is a 10 wide blur - you get the 11th pixel by offsetting the vertical blur by half a pixel
	//
	// horizontal pass has the effect of shifting the center half a pixel to the left and down
	// vertical pass shifts it half a pixel up and right
	// result is an 11x11 gaussian blur that is perfectly centered
	//
	//   C = center pixel
	//   x = horizontal sample positions
	//   y = vertical sample positions
	//
	//
	//                      .---.---.
	//                      |   |   |
	//                      |---y---|
	//                      |   |   |
	//                      |---|---|
	//                      |   |   |
	//                      |---y---|
	//                      |   |   |
	//                      |---|---|
	//                      |   |   |
	//  .---.---.---.---.---|---y---|---.---.---. . .
	//  |   |   |   |   |   | C |   |   |   |   |   .
	//  '---x---|---x---|---x---|---x---|---x---| . .
	//  |   |   |   |   |   |   |   |   |   |   |   .
	//  '---'---'---'---'---'---y---'---'---'---' . .
	//                      |   |   |
	//                      |---|---|
	//                      |   |   |
	//                      |---y---|
	//                      |   |   |
	//                      '---'---'
	//						`   `   `		<-- virtual pixel you get for 'free' because of the half-pixel shift down in the horizontal pass
	//                      ' - ' - '
	//
	//
	// hard-coded kernel
	//
	//		[1  9]  [36  84]  [126  126]  [84  36]  [9  1]			/ 512
	//
	// Note:  with the half-pixel offset in the other direction, this kernel becomes:
	//
	//		1  10  45  120  210  252  210  120  45  10  1			/ 1024
	
	const float2 offset[5]=
		{
			{0.5,	-4.0 - 1.0 /(1.0+9.0)			},			// -4.1
			{0.5,	-2.0 - 36.0/(36.0+84.0)			},			// -2.3
			{0.5,	 0.0 - 126.0/(126.0+126.0)		},			// -0.5
			{0.5,	+2.0 - 84.0/(84.0+36.0)			},			// +1.3
			{0.5,	+4.0 - 9.0/(1.0+9.0)			}			// +3.1
		};

#ifdef APPLY_FIXES
    float2 pixel_size_scale = float2(1.0f / 1152, 1.0f / 640) / pixel_size.xy;
	
	float4 color=	(1.0   + 9.0)	* sample2D(target_sampler, sample + offset[0] * pixel_size * pixel_size_scale) +
					(36.0  + 84.0)	* sample2D(target_sampler, sample + offset[1] * pixel_size * pixel_size_scale) +
					(126.0 + 126.0)	* sample2D(target_sampler, sample + offset[2] * pixel_size * pixel_size_scale) +
					(84.0  + 36.0)	* sample2D(target_sampler, sample + offset[3] * pixel_size * pixel_size_scale) +
					(1.0   + 9.0)	* sample2D(target_sampler, sample + offset[4] * pixel_size * pixel_size_scale);
#else
    float4 color=	(1.0   + 9.0)	* sample2D(target_sampler, sample + offset[0] * pixel_size) +
					(36.0  + 84.0)	* sample2D(target_sampler, sample + offset[1] * pixel_size) +
					(126.0 + 126.0)	* sample2D(target_sampler, sample + offset[2] * pixel_size) +
					(84.0  + 36.0)	* sample2D(target_sampler, sample + offset[3] * pixel_size) +
					(1.0   + 9.0)	* sample2D(target_sampler, sample + offset[4] * pixel_size);
#endif

	return color / 512.0;
}
