#line 1 "source\rasterizer\hlsl\lightshafts.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "postprocess.fx"
#include "lightshafts_registers.fx"

//@generate screen

LOCAL_SAMPLER_2D(color_sampler, 0);
LOCAL_SAMPLER_2D(depth_sampler, 1);

float4 default_ps(SCREEN_POSITION_INPUT(screen_position), in float2 texcoord : TEXCOORD0) : SV_Target
{
   float3 color = sample2D(color_sampler, texcoord).rgb;
   float depth = sample2D(depth_sampler, texcoord).r;

   float2 offs = texcoord - g_sun_pos.xy;
   float2 offsInner = offs * g_inner_size.xy;
   offs *= g_sun_pos.zw;
   float falloff = pow(saturate(1.0f - dot(offs, offs)), 2);
   float innerFalloff = saturate(pow( saturate(dot(offsInner, offsInner)), 2) );
   float lum = dot(color, float3(0.299f, 0.587f, 0.114f));

   // intensity clamp
   color *= saturate((lum - g_tint.w) * 10.0f);

   // depth clamp
   color *= saturate(depth * g_inner_size.z + g_inner_size.w);

   // falloff clamp
   color *= falloff;
   color *= innerFalloff;

   // tint
   //color *= g_tint.xyz;

   return float4(color, 0.0f);
}
