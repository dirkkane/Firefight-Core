#line 2 "source\rasterizer\hlsl\exposure_downsample.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);
LOCAL_SAMPLER_2D(weight_sampler, 1);

float4 default_ps(screen_output IN) : SV_Target
{
	float3 average= 0.0f;		// weighted_sum(log(intensity)), log(weighted_sum(intensity)), total_weight

	for (int x= -3; x <= 3; x += 2)
	{
		for (int y= -7; y <= 7; y += 2)
		{
			float weight= tex2D_offset(weight_sampler, IN.texcoord, x, y).g;		
//			float intensity= color_to_intensity( tex2D_offset(source_sampler, IN.texcoord, x, y));
			float intensity= tex2D_offset(source_sampler, IN.texcoord, x, y).a;						// actual intensity stored in the alpha channel
			average.xyz += weight * float3(log2( 0.00001f + intensity ), intensity, 1.0f);
		}
	}

//	average /= (8.0f * 4.0f);
	average.xy /= average.z;
	average.y= log2( 0.00001f + average.y );
	
	return (average.y * scale.x + average.x * (1.0f - scale.x));
}
