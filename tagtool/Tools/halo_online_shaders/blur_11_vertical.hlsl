#line 2 "source\rasterizer\hlsl\blur_11_vertical.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(target_sampler, 0);

fast4 default_ps(screen_output IN) : SV_Target
{
	float2 sample= IN.texcoord;
	
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
	
	float4 color=	(1.0   + 9.0)	* sample2D(target_sampler, sample + offset[0] * pixel_size) +
					(36.0  + 84.0)	* sample2D(target_sampler, sample + offset[1] * pixel_size) +
					(126.0 + 126.0)	* sample2D(target_sampler, sample + offset[2] * pixel_size) +
					(84.0  + 36.0)	* sample2D(target_sampler, sample + offset[3] * pixel_size) +
					(1.0   + 9.0)	* sample2D(target_sampler, sample + offset[4] * pixel_size);

	return color / 512.0;
}
