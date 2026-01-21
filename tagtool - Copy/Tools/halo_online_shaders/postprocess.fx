#ifndef _POSTPROCESS_FX_
#define _POSTPROCESS_FX_

#include "postprocess_registers.fx"

#ifndef USE_CUSTOM_POSTPROCESS_CONSTANTS
#include "texture.fx"
#endif

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

#define ILLUM_SCALE (g_alt_exposure.r)
#define ILLUM_EXPOSURE (g_alt_exposure.g)


struct screen_output
{
	float4 position		:SV_Position;
	float2 texcoord		:TEXCOORD0;
#ifdef POSTPROCESS_COLOR				// ###ctchou $TODO fix shader patching?
	float4 color		:TEXCOORD1;
#endif // POSTPROCESS_COLOR
};

#ifdef VERTEX_SHADER

#ifndef POSTPROCESS_USE_CUSTOM_VERTEX_SHADER

screen_output default_vs(vertex_type IN)
{
	screen_output OUT;
	OUT.texcoord=		IN.texcoord;
	OUT.position.xy=	IN.position;
	OUT.position.zw=	1.0f;
#ifdef POSTPROCESS_COLOR	
	OUT.color=			IN.color;
#endif // POSTPROCESS_COLOR
	return OUT;
}

#endif

#endif

#endif //ifndef _POSTPROCESS_FX_
