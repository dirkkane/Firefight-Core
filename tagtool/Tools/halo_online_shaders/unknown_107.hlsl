
#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#define POSTPROCESS_USE_CUSTOM_VERTEX_SHADER

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(color_sampler, 0);
LOCAL_SAMPLER_2D(gbuf_sampler, 1);

screen_output default_vs(screen_output IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.z=     0.5f;
	OUT.position.w=     1.0f;
	return OUT;
}

accum_pixel default_ps(vertex_type IN) : SV_Target
{
    float4 color_sample = sample2Dlod(color_sampler, IN.texcoord, 0);
    float4 gbuf_sample = sample2Dlod(gbuf_sampler, IN.texcoord, 0);

    color_sample.rgb *= color_sample.a;
    color_sample.rgb *= gbuf_sample.rgb;

    return convert_to_render_target(color_sample, true, false
    #ifdef SSR_ENABLE
    , 0
    #endif
    );
}