#line 2 "source\rasterizer\hlsl\downsample_4x4_gaussian_bloom_LDR.hlsl"


#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "downsample_registers.fx"
//@generate screen


LOCAL_SAMPLER_2D(source_sampler, 1);
LOCAL_SAMPLER_2D(bloom_sampler, 0);


float4 default_ps(screen_output IN, SCREEN_POSITION_INPUT(screen_pos)) : SV_Target
{
#ifdef pc
	float3 color= 0.00000001f;						// hack to keep divide by zero from happening on the nVidia cards
#else
	float3 color= 0.0f;
#endif

	// this is a 6x6 gaussian filter (slightly better than 4x4 box filter)
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, -2, -2);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, +0, -2);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, +2, -2);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, -2, +0);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, +0, +0);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, +2, +0);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, -2, +2);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, +0, +2);
	color += (0.33f * 0.33f) * tex2D_offset(source_sampler, IN.texcoord, +2, +2);


/*	float sample_intensity, sample_curved;
	float intensity= 0;
	
	float4 sample= tex2D_offset(source_sampler, IN.texcoord, -1, -1);
		sample_intensity= dot(sample.rgb, intensity_vector.rgb);
		intensity += sample_intensity * 0.25f;
		sample_curved= max(sample_intensity*scale.y, sample_intensity-scale.x);		// ###ctchou $PERF could compute both parameters with a single mad followed by max
		color += sample.rgb * sample_curved / sample_intensity;
		
	sample= tex2D_offset(source_sampler, IN.texcoord, +1, -1);
		sample_intensity= dot(sample.rgb, intensity_vector.rgb);
		intensity += sample_intensity * 0.25f;
		sample_curved= max(sample_intensity*scale.y, sample_intensity-scale.x);		// ###ctchou $PERF could compute both parameters with a single mad followed by max
		color += sample.rgb * sample_curved / sample_intensity;
		
	sample= tex2D_offset(source_sampler, IN.texcoord, -1, +1);
		sample_intensity= dot(sample.rgb, intensity_vector.rgb);
		intensity += sample_intensity * 0.25f;
		sample_curved= max(sample_intensity*scale.y, sample_intensity-scale.x);		// ###ctchou $PERF could compute both parameters with a single mad followed by max
		color += sample.rgb * sample_curved / sample_intensity;
		
	sample= tex2D_offset(source_sampler, IN.texcoord, +1, +1);
		sample_intensity= dot(sample.rgb, intensity_vector.rgb);
		intensity += sample_intensity * 0.25f;
		sample_curved= max(sample_intensity*scale.y, sample_intensity-scale.x);		// ###ctchou $PERF could compute both parameters with a single mad followed by max
		color += sample.rgb * sample_curved / sample_intensity;
	color= color / 4.0f;

	float3 bloom_color= color;
*/

	// calculate 'intensity'		(max or dot product?)
	float intensity= dot(color.rgb, intensity_vector.rgb);					// max(max(color.r, color.g), color.b);
	
	// calculate bloom curve intensity
	float bloom_intensity= max(intensity*scale.y, intensity-scale.x);		// ###ctchou $PERF could compute both parameters with a single mad followed by max
	
	// calculate bloom color
	float3 bloom_color= color * (bloom_intensity / intensity);
		
	return max(float4(bloom_color.rgb, intensity), tex2D_offset_point(bloom_sampler, (screen_pos + 0.5f) * pixel_size.xy, 0, 0));
}
