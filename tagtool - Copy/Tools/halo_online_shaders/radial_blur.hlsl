#line 1 "source\rasterizer\hlsl\radial_blur.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "postprocess.fx"
#include "radial_blur_registers.fx"

//@generate screen

LOCAL_SAMPLER_2D(color_sampler, 0);

float4 default_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float2 texcoord : TEXCOORD0) : SV_Target
{
   float2 center     = g_center_scale.xy;
   float2 scale      = g_center_scale.zw;
   float  offset     = -15.0f;
   float  fadeOffset = 1.0f;

   float2 vec = texcoord - center;

   static const float sampleWeights[16] = { BLUR_WEIGHTS0, BLUR_WEIGHTS1, BLUR_WEIGHTS2, BLUR_WEIGHTS3 };
   static const int   sampleN = 16;
   
   float3 blurred = 0;
   for(int i = 0; i < sampleN; ++i) {
      float2 uv = center + vec *  pow(1 + scale, float(i + offset) / sampleN);
      float mask = saturate(12 * uv.x * (1 - uv.x) + fadeOffset) * saturate(12 * uv.y * (1 - uv.y) + fadeOffset);
      blurred += sample2D(color_sampler, uv).rgb * sampleWeights[i] * mask;
   }

   return float4(blurred.rgb * g_tint.rgb, 0.0f);
}
