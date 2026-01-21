#line 2 "source\rasterizer\hlsl\texture.fx"
#ifndef __TEXTURE_FX
#define __TEXTURE_FX


#if defined(pc) || defined(PIXEL_SIZE)
float4 tex2D_offset_exact(texture_sampler_2d s, const float2 texc, const float offsetx, const float offsety)
{
	return sample2D(s, texc + float2(offsetx, offsety) * pixel_size.xy);
}
#endif

float4 tex2D_offset(texture_sampler_2d s, float2 texc, const float offsetx, const float offsety)
{
	float4 value= 0.0f;
#ifdef pc
	value= tex2D_offset_exact(s, texc, offsetx, offsety);
#else
#ifndef VERTEX_SHADER
	asm {
		tfetch2D value, texc, s, MinFilter=linear, MagFilter=linear, OffsetX=offsetx, OffsetY=offsety
	};
#endif
#endif
	return value; 
}

#if DX_VERSION == 11
float4 texCmp2D_offset(texture_sampler_comparison_2d s, float2 texc, const float offsetx, const float offsety, const float compareValue)
{
	float4 value= 0.0f;
#if defined(pc) || !defined(VERTEX_SHADER)
	value = sampleCmp2D(s, texc + float2(offsetx, offsety) * pixel_size.xy, compareValue);
#endif
	return value;
}
#endif // DX_VERSION == 11

float4 tex2D_offset_point(texture_sampler_2d s, float2 texc, const float offsetx, const float offsety)
{
	float4 value= 0.0f;
#ifdef pc
	value= tex2D_offset_exact(s, texc, offsetx, offsety);
#else
#ifndef VERTEX_SHADER
	asm {
		tfetch2D value, texc, s, MinFilter=point, MagFilter=point, OffsetX=offsetx, OffsetY=offsety
	};
#endif
#endif
	return value;
}

float4 calculate_weights_bicubic(float4 dist)
{
	//
	//  bicubic is a smooth sampling method
	//  it is smoother than bilinear, but can have ringing around high-contrast edges (because of it's weights can go negative)
	//	bicubic in linear space is not the best..
	//

	// input vector contains the distance of 4 sample pixels [-1.5, -0.5, +0.5, +1.5] to our sample point
	// output vector contains the weights for each of the corresponding pixels

	// bicubic parameter 'A'
#define A -0.75f
	
	float4 weights;
	weights.yz= (((A + 2.0f) * dist.yz - (A + 3.0f)) * dist.yz * dist.yz + 1.0f);					// 'photoshop' style bicubic
	weights.xw= (((A * dist.xw - 5.0f * A ) * dist.xw + 8.0f * A ) * dist.xw - 4.0f * A);
	return weights;
}

float4 calculate_weights_bspline(float4 dist)
{
	//
	//  bspline is a super-smooth sampling method
	//  it is smoother than bicubic (much smoother than bilinear)
	//  and, unlike bicubic, is guaranteed not to have ringing around high-contrast edges (because it has no negative weights)
	//  the downside is it gives everything a slight blur so you lose a bit of the high frequencies
	//

	float4 weights;
	weights.yz= (4.0f + (-6.0f + 3.0f * dist.yz) * dist.yz * dist.yz) / 6.0f;						// bspline
	weights.xw= (2.0f - dist.xw) * (2.0f - dist.xw) * (2.0f - dist.xw) / 6.0f;
	return weights;
}

#ifndef pc
#define DECLARE_TEX2D_4x4_METHOD(name, calculate_weights_func)																\
float4 name(texture_sampler_2d s, float2 texc)																						\
{																															\
    float4 subpixel_dist;																									\
    asm {																													\
        getWeights2D subpixel_dist, texc, s																					\
    };																														\
  	float4 x_dist= float4(1.0f+subpixel_dist.x, subpixel_dist.x, 1.0f-subpixel_dist.x, 2.0f-subpixel_dist.x);				\
	float4 x_weights= calculate_weights_func(x_dist);																		\
																															\
	float4 vert_colors[4];																									\
	for (int y= 0; y < 4; y++)																								\
	{																														\
		float y_offset= y - 1.5f;																							\
		float4 color0, color1, color2, color3;																				\
		asm {																												\
			tfetch2D color0, texc, s, MinFilter=point, MagFilter=point, OffsetX=-1.5, OffsetY=y_offset						\
			tfetch2D color1, texc, s, MinFilter=point, MagFilter=point, OffsetX=-0.5, OffsetY=y_offset						\
			tfetch2D color2, texc, s, MinFilter=point, MagFilter=point, OffsetX=+0.5, OffsetY=y_offset						\
			tfetch2D color3, texc, s, MinFilter=point, MagFilter=point, OffsetX=+1.5, OffsetY=y_offset						\
		};																													\
		vert_colors[y]=	x_weights.x * color0 +																				\
						x_weights.y * color1 +																				\
						x_weights.z * color2 +																				\
						x_weights.w * color3;																				\
	}																														\
																															\
	float4 y_dist= float4(1.0f+subpixel_dist.y, subpixel_dist.y, 1.0f-subpixel_dist.y, 2.0f-subpixel_dist.y);				\
	float4 y_weights= calculate_weights_func(y_dist);																		\
																															\
	float4 color=	y_weights.x * vert_colors[0] +																			\
					y_weights.y * vert_colors[1] +																			\
					y_weights.z * vert_colors[2] +																			\
					y_weights.w * vert_colors[3];																			\
	return color;																											\
}
#elif DX_VERSION == 11
#define DECLARE_TEX2D_4x4_METHOD(name, calculate_weights_func)															\
float4 name(texture_sampler_2d s, float2 texc)																				\
{																															\
    float2 subpixel_dist;																									\
	uint width,height;																										\
	s.t.GetDimensions(width, height);																						\
	subpixel_dist = frac(texc * float2(width, height));																		\
  	float4 x_dist= float4(1.0f+subpixel_dist.x, subpixel_dist.x, 1.0f-subpixel_dist.x, 2.0f-subpixel_dist.x);				\
	float4 x_weights= calculate_weights_func(x_dist);																		\
																															\
	float4 vert_colors[4];																									\
	for (int y= 0; y < 4; y++)																								\
	{																														\
		int y_offset= y - 2;																								\
		float4 color0, color1, color2, color3;																				\
		color0 = s.t.Sample(s.s, texc, int2(-2, y_offset));																	\
		color1 = s.t.Sample(s.s, texc, int2(-1, y_offset));																	\
		color2 = s.t.Sample(s.s, texc, int2(0, y_offset));																	\
		color3 = s.t.Sample(s.s, texc, int2(1, y_offset));																	\
		vert_colors[y]=	x_weights.x * color0 +																				\
						x_weights.y * color1 +																				\
						x_weights.z * color2 +																				\
						x_weights.w * color3;																				\
	}																														\
																															\
	float4 y_dist= float4(1.0f+subpixel_dist.y, subpixel_dist.y, 1.0f-subpixel_dist.y, 2.0f-subpixel_dist.y);				\
	float4 y_weights= calculate_weights_func(y_dist);																		\
																															\
	float4 color=	y_weights.x * vert_colors[0] +																			\
					y_weights.y * vert_colors[1] +																			\
					y_weights.z * vert_colors[2] +																			\
					y_weights.w * vert_colors[3];																			\
	return color;																											\
}
#else  // pc
#define DECLARE_TEX2D_4x4_METHOD(name, calculate_weights_func) float4 name(texture_sampler_2d s, float2 texc) { return 0.0f; }
#endif // pc

DECLARE_TEX2D_4x4_METHOD(tex2D_bspline, calculate_weights_bspline)
DECLARE_TEX2D_4x4_METHOD(tex2D_bicubic, calculate_weights_bicubic)


#endif // __TEXTURE_FX
