#line 2 "source\rasterizer\hlsl\shadow_apply_faster.hlsl"

//@generate tiny_position_only

//#define FASTER_SHADOWS

#define SAMPLE_PERCENTAGE_CLOSER sample_percentage_closer_PCF_2x2_block
float sample_percentage_closer_PCF_2x2_block(float3 fragment_shadow_position, float depth_bias);

#include "shadow_apply.hlsl"


float sample_percentage_closer_PCF_2x2_block(float3 fragment_shadow_position, float depth_bias)					// 9 samples, 0 predicated
{
#ifndef pc
	[isolate]		// optimization - reduces GPRs
#endif // !pc

	float2 texel= fragment_shadow_position.xy;

	float4 blend= 1.0f;
	float scale= 1.0f / 4.0f;
//#ifdef BILINEAR_SHADOWS
   #ifdef pc
      float2 frac_pos = fragment_shadow_position.xy / pixel_size + float2(0.5, 0.5);
      blend.xy = frac(frac_pos);
   #else
	   asm {
		   getWeights2D blend.xy, fragment_shadow_position.xy, shadow, MagFilter=linear, MinFilter=linear, OffsetX=0.5, OffsetY=0.5
	   };
   #endif
	blend.zw= 1.0f - blend.xy;
	scale = 1.0f;
//#endif // BILINEAR_SHADOWS

	float4 max_depth= depth_bias;											// x= [0,0],    y=[-1/1,0] or [0,-1/1],     z=[-1/1,-1/1],		w=[-2/2,0] or [0,-2/2]
	max_depth *= float4(-1.0f, -sqrt(20.0f), -3.0f, -sqrt(26.0f));			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;
	
	float color=blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel, -0.5f, -0.5f).r) + 
					blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel, +0.5f, -0.5f).r) +
					blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel, -0.5f, +0.5f).r) +
					blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel, +0.5f, +0.5f).r);
					
	return color * scale;
}