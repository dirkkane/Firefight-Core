#line 2 "source\rasterizer\hlsl\downsample_4x4_block_bloom_LDR.hlsl"


#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "downsample_registers.fx"
//@generate screen


LOCAL_SAMPLER_2D(source_sampler, 1);
LOCAL_SAMPLER_2D(bloom_sampler, 0);

#define TEXEL_SIZE (scale.zw) // s1 pixel size

float4 sample2D_offset_texel_size(sampler2D tex, float2 texcoord, float x, float y)
{
    //return tex2D(tex, texcoord + (pixel_size.xy * float2(x, y)));
    return tex2D(tex, texcoord + (TEXEL_SIZE * float2(x, y)));
}

float4 default_ps(screen_output IN, SCREEN_POSITION_INPUT(screen_pos)) : SV_Target
{
#ifdef pc
	float3 color= 0.00000001f;						// hack to keep divide by zero from happening on the nVidia cards
#else
	float3 color= 0.0f;
#endif

	//float4 sample= sample2D_offset_texel_size(source_sampler, IN.texcoord, -1, -1);
	//	color += sample.rgb;
	//sample= sample2D_offset_texel_size(source_sampler, IN.texcoord, +1, -1);
	//	color += sample.rgb;
	//sample= sample2D_offset_texel_size(source_sampler, IN.texcoord, -1, +1);
	//	color += sample.rgb;
	//sample= sample2D_offset_texel_size(source_sampler, IN.texcoord, +1, +1);
	//	color += sample.rgb;
	//color= color / 4.0f;

// Switched to ODST version of this shader:
	// this is a 6x6 gaussian filter (slightly better than 4x4 box filter)
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, -2, -2);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, +0, -2);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, +2, -2);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, -2, +0);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, +0, +0);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, +2, +0);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, -2, +2);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, +0, +2);
	color += (0.33f * 0.33f) * sample2D_offset_texel_size(source_sampler, IN.texcoord, +2, +2);

	// calculate 'intensity'		(max or dot product?)
	float intensity= dot(color.rgb, intensity_vector.rgb);					// max(max(color.r, color.g), color.b);
	
	// calculate bloom curve intensity
	float bloom_intensity= max(intensity*scale.y, intensity-scale.x);		// ###ctchou $PERF could compute both parameters with a single mad followed by max
	
	// calculate bloom color
	float3 bloom_color= color * (bloom_intensity / intensity);
	
	return max(float4(bloom_color.rgb, intensity), tex2D_offset_point(bloom_sampler, (screen_pos + 0.5f) * pixel_size.xy, 0, 0));
}
