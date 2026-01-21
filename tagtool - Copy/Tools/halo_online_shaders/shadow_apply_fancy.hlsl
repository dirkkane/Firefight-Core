#line 2 "source\rasterizer\hlsl\shadow_apply_fancy.hlsl"

//@generate tiny_position_only

//#define FASTER_SHADOWS

#define SAMPLE_PERCENTAGE_CLOSER sample_percentage_closer_PCF_5x5_block_predicated
float sample_percentage_closer_PCF_5x5_block_predicated(float3 fragment_shadow_position, float depth_bias);

#include "shadow_apply.hlsl"


float sample_percentage_closer_PCF_5x5_block_predicated(float3 fragment_shadow_position, float depth_bias)
{
	float2 texel1= fragment_shadow_position.xy;

	float4 blend;

#ifdef pc
   float2 frac_pos = fragment_shadow_position.xy / pixel_size + float2(0.5f, 0.5f);
   blend.xy = frac(frac_pos);
#else
#ifndef VERTEX_SHADER
	fragment_shadow_position.xy += 0.5f;
	asm {
		getWeights2D blend.xy, fragment_shadow_position.xy, shadow, MagFilter=linear, MinFilter=linear
	};
#endif
#endif
	blend.zw= 1.0f - blend.xy;
//	blend.xy= 1.0f - blend.zw;
	
//	blend.xyzw= 1.0f;										// point-sampled filter
	
	// old code here
//	texel1= texel1 * pixel_size;
	
/*	texel1= (texel1 + 0.5)* pixel_size;
	float2 texel0= texel1 - pixel_size;
	float2 texel2= texel1 + pixel_size;
//	float2 texel3= texel2 + pixel_size;
*/
/*	
#define offset_0 -1.5f
#define offset_1 -0.5f
#define offset_2 +0.5f
#define offset_3 +1.5f
	
	float d0= 1 / 8.0f;										// gaussian 4x4 filter
	float d1= 3 / 8.0f;
	float d2= 3 / 8.0f;
	float d3= 1 / 8.0f;
	float color=	d0 * d0 * blend.z * blend.w * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_0, offset_0).r, depth_bias) + 
					d1 * d0 * 1.0f    * blend.w * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_1, offset_0).r, depth_bias) +
					d2 * d0 * 1.0f    * blend.w * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_2, offset_0).r, depth_bias) +
					d3 * d0 * blend.x * blend.w * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_3, offset_0).r, depth_bias) +
					d0 * d1 * blend.z * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_0, offset_1).r, depth_bias) +
					d1 * d1 * 1.0f    * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_1, offset_1).r, depth_bias) +
					d2 * d1 * 1.0f    * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_2, offset_1).r, depth_bias) +
					d3 * d1 * blend.x * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_3, offset_1).r, depth_bias) +
					d0 * d2 * blend.z * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_0, offset_2).r, depth_bias) +
					d1 * d2 * 1.0f    * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_1, offset_2).r, depth_bias) +
					d2 * d2 * 1.0f    * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_2, offset_2).r, depth_bias) +
					d3 * d2 * blend.x * 1.0f    * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_3, offset_2).r, depth_bias) +
					d0 * d3 * blend.z * blend.y * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_0, offset_3).r, depth_bias) +
					d1 * d3 * 1.0f    * blend.y * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_1, offset_3).r, depth_bias) +
					d2 * d3 * 1.0f    * blend.y * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_2, offset_3).r, depth_bias) +
					d3 * d3 * blend.x * blend.y * step(fragment_shadow_position.z-tex2D_offset_point(shadow, offset_3, offset_3).r, depth_bias);
*/

#define offset_0 -1.5f
#define offset_1 -0.5f
#define offset_2 +0.5f
#define offset_3 +1.5f

	float3 max_depth= depth_bias;							// x= central samples,   y = adjacent sample,   z= diagonal sample
	max_depth *= float3(-2.0f, -sqrt(5.0f), -4.0f);			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	// 4x4 point and 3x3 bilinear
	float color=	blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_0, offset_0).r) + 
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_1, offset_0).r) +
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_2, offset_0).r) +
					blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_3, offset_0).r) +
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_0, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow, texel1, offset_1, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow, texel1, offset_2, offset_1).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_3, offset_1).r) +
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_0, offset_2).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow, texel1, offset_1, offset_2).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow, texel1, offset_2, offset_2).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_3, offset_2).r) +
					blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_0, offset_3).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_1, offset_3).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_2, offset_3).r) +
					blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_3, offset_3).r);
					
	color /= 9.0f;

/*	// 3x3 point and 2x2 bilinear
	float color=	blend.z * blend.w * step(fragment_shadow_position.z-tex2D(shadow, float2(texel0.x, texel0.y)).r, depth_bias) + 
					1.0f    * blend.w * step(fragment_shadow_position.z-tex2D(shadow, float2(texel1.x, texel0.y)).r, depth_bias) +
					blend.x * blend.w * step(fragment_shadow_position.z-tex2D(shadow, float2(texel2.x, texel0.y)).r, depth_bias) +
					blend.z * 1.0f    * step(fragment_shadow_position.z-tex2D(shadow, float2(texel0.x, texel1.y)).r, depth_bias) +
					1.0f    * 1.0f    * step(fragment_shadow_position.z-tex2D(shadow, float2(texel1.x, texel1.y)).r, depth_bias) +
					blend.x * 1.0f    * step(fragment_shadow_position.z-tex2D(shadow, float2(texel2.x, texel1.y)).r, depth_bias) +
					blend.z * blend.y * step(fragment_shadow_position.z-tex2D(shadow, float2(texel0.x, texel2.y)).r, depth_bias) +
					1.0f    * blend.y * step(fragment_shadow_position.z-tex2D(shadow, float2(texel1.x, texel2.y)).r, depth_bias) +
					blend.x * blend.y * step(fragment_shadow_position.z-tex2D(shadow, float2(texel2.x, texel2.y)).r, depth_bias);
*/
/*
#define offset_0 -1.0f
//#define offset_A -1.0f
#define offset_1 0.0f
//#define offset_B +1.0f
#define offset_2 +1.0f

	float3 max_depth= depth_bias;							// x= central sample,   y = adjacent sample,   z= diagonal sample
	max_depth *= float3(-1.0f, -sqrt(5.0f), -3.0f);			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	// 3x3 point and 2x2 bilinear
	float color=	blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_0, offset_0).r) +		// ###ctchou $PERF I wonder if it vectorizes these step's correctly (should be able to do 4 simultaneously with the correct vector packing)
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_1, offset_0).r) +		// ###ctchou I verified that it does vectorize these correctly
					blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_2, offset_0).r) +		// ###ctchou and it predicates this entire block (yay)
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_0, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow, texel1, offset_1, offset_1).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_2, offset_1).r) +
					blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_0, offset_2).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_1, offset_2).r) +
					blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_2, offset_2).r);

//	color *= 1.0f / 4.0f;			// 2x2 linear
//	color *= 1.0f / 9.0f;			// 4x4 linear, 3x3 point
//	color *= 1.0f / 16.0f;			// 4x4 point
//	color /= 1.0f;					// 4x4 gaussian
	
/* /					
#define offset_C -3.0f
#define offset_0 -2.0f
#define offset_A -1.0f
#define offset_1 0.0f
#define offset_B +1.0f
#define offset_2 +2.0f
#define offset_D +3.0f

	float3 max_depth= depth_bias;								// x= [1,1],    y=[0/2,1] or [1,0/2],     z=[0/2,0/2]
	max_depth *= float3(-1.0f, -sqrt(13.0f), -5.0f);			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	// 3x3 point and 2x2 bilinear
	float color=	step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_0, offset_0).r) +		// ###ctchou $PERF I wonder if it vectorizes these step's correctly (should be able to do 4 simultaneously with the correct vector packing)
					step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_2, offset_0).r) +		// ###ctchou and it predicates this entire block (yay)
					step(max_depth.x, tex2D_offset_point(shadow, texel1, offset_1, offset_1).r) +
					step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_0, offset_2).r) +
					step(max_depth.z, tex2D_offset_point(shadow, texel1, offset_2, offset_2).r);		// ###ctchou I verified that it does vectorize these correctly

//	clip(color - 0.1f);			// debug - show clipping regions
//	clip(8.9f - color);

	if ((color > 0.1f) && (color < 4.9f))		// if blurring is needed, complete the blur samples
	{		
		float3 max_depth2= depth_bias;
//		max_depth2 *= float3(-sqrt(5.0f), -3.0f, -sqrt(17.0f));								// x= [A/B,1],    y=[A/B, A/B],         z=[A/B,0/2] or [0/2, A/B]
		max_depth2 *= float3(-sqrt(25.0f), -3.0f, -sqrt(17.0f));							// x= [C/D,1],    y=[A/B, A/B],         z=[A/B,0/2] or [0/2, A/B]
		max_depth2 += fragment_shadow_position.z;

		color += step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_1, offset_0).r) +
				 step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_0, offset_1).r) +
				 step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_2, offset_1).r) +
				 step(max_depth.y, tex2D_offset_point(shadow, texel1, offset_1, offset_2).r) +

//				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_A, offset_1).r) +
//				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_1, offset_A).r) +
//				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_1, offset_B).r) +
//				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_B, offset_1).r) +

				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_C, offset_1).r) +
				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_1, offset_C).r) +
				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_1, offset_D).r) +
				 step(max_depth2.x, tex2D_offset_point(shadow, texel1, offset_D, offset_1).r) +

				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_0, offset_A).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_0, offset_B).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_A, offset_0).r) +
				 step(max_depth2.y, tex2D_offset_point(shadow, texel1, offset_A, offset_A).r) +
				 step(max_depth2.y, tex2D_offset_point(shadow, texel1, offset_A, offset_B).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_A, offset_2).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_B, offset_0).r) +
				 step(max_depth2.y, tex2D_offset_point(shadow, texel1, offset_B, offset_A).r) +
				 step(max_depth2.y, tex2D_offset_point(shadow, texel1, offset_B, offset_B).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_B, offset_2).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_2, offset_A).r) +
				 step(max_depth2.z, tex2D_offset_point(shadow, texel1, offset_2, offset_B).r);
				 
		color *= 5.0f / 25.0f;
	}
//	else
//	{
//		clip(-1.0f);
//	}
//*/
//	color *= 1.0f / 5.0f;			// 4x4 linear, 3x3 point

	return color;
}