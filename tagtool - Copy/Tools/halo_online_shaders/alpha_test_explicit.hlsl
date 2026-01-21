#line 1 "source\rasterizer\hlsl\alpha_test.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "hlsl_constant_oneshot.fx"
#include "atmosphere.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

//@generate world
LOCAL_SAMPLER_2D(basemap_sampler, 0);

struct alpha_test_output
{
	float4 position		:SV_Position;
	float2 texcoord		:TEXCOORD0;
    float3 extinction	:COLOR0;// COLOR semantic will not clamp to [0,1].
    float3 inscatter	:COLOR1;// COLOR semantic will not clamp to [0,1].
};

alpha_test_output default_vs(vertex_type IN)
{
    alpha_test_output OUT;

    OUT.position= mul(float4(IN.position, 1.0f), View_Projection);
	OUT.texcoord= IN.texcoord;
	
	float3 extinction, inscatter;

	compute_scattering(Camera_Position, OUT.position.xyz, extinction, inscatter);

	//OUT.extinction.xyz= extinction * lighting.rgb;
	//OUT.inscatter.xyz= inscatter;
	OUT.extinction.xyz= extinction * lighting.rgb;
	OUT.inscatter.xyz= float3(0, 0, 0);
	
    return OUT;
}

// pixel fragment entry points
accum_pixel default_ps(alpha_test_output IN) : SV_Target
{
	float4 pixel= sample2D(basemap_sampler, IN.texcoord);
		
	clip(pixel.a-0.5f);
	
	pixel.rgb= (pixel.rgb * IN.extinction + IN.inscatter) * g_exposure.rrr;
	
	return convert_to_render_target(pixel, false, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
