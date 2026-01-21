#line 2 "source\rasterizer\hlsl\gamma_correct.hlsl"

//#define USE_CUSTOM_POSTPROCESS_CONSTANTS
#define POSTPROCESS_COLOR

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "texture_xform.fx"
#include "custom_gamma_correct_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(surface_sampler, 0);

// pixel fragment entry points
float4 default_ps(screen_output IN) : SV_Target
{
	float4 pixel=		sample2D(surface_sampler, IN.texcoord);
	
	// remove xenon gamma curve
	float3 slope0= pixel.rgb * (1023.000f / 255.0f) + (  0.0000f / 255.0f);
	float3 slope1= pixel.rgb * ( 511.500f / 255.0f) + ( 31.7500f / 255.0f);
	float3 slope2= pixel.rgb * ( 255.750f / 255.0f) + ( 63.6250f / 255.0f);
	float3 slope3= pixel.rgb * ( 127.875f / 255.0f) + (127.5625f / 255.0f);
	pixel.rgb= min(slope0, min(slope1, min(slope2, slope3)));
	
	// apply custom gamma
	pixel.rgb= pow(pixel.rgb, 1.95f);
	return pixel*scale*IN.color;
}
