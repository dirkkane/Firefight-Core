#line 1 "source\rasterizer\hlsl\ssao.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "postprocess.fx"

//@generate screen

LOCAL_SAMPLER_2D(depth_sampler, 0);
LOCAL_SAMPLER_2D(ssao_sampler, 1);





float sampleDiag(in half4 sm_mask, in float depth,
                 in float2 texC, in float2 texC0, in float2 texC1)
{
   float dvX0 = tex2D_offset(depth_sampler, texC, texC0.x, texC0.y).r;
   float dvX1 = tex2D_offset(depth_sampler, texC, texC1.x, texC1.y).r;
   
   float dx0 = dvX0 - depth;
   float dx1 = depth - dvX1;
   
   float smX0 = tex2D_offset(ssao_sampler, texC, texC0.x, texC0.y).r;
   float smX1 = tex2D_offset(ssao_sampler, texC, texC1.x, texC1.y).r;
   
   float4 ret;// = sm_mask;
   
   if (abs(1.0f - dx1 / dx0) < 0.5)// this is assimetric formula
   {
      ret = (smX0 + smX1 + sm_mask*0.5) / 2.5;
   } else if (abs(dx0) < abs(dx1)) {
      ret = (smX0 + sm_mask) / 2;
   } else {
      ret = (smX1 + sm_mask) / 2;
   }
   
   return ret;
}



float4 default_ps(SCREEN_POSITION_INPUT(screen_position), in float2 texcoord : TEXCOORD0) : SV_Target
{
   float ssao = sample2D(ssao_sampler, texcoord).r;
   //return ssao * ssao;

   float depth = sample2D(depth_sampler, texcoord).r;


   float diagXY0 = sampleDiag(ssao, depth, texcoord,
              float2(-1.0, -1.0),
              float2(1.0, 1.0));
   
   float diagXY1 = sampleDiag(ssao, depth, texcoord,
              float2(-1, 1),
              float2(1, -1));
   
   ssao = (diagXY0 + diagXY1) * 0.5f;

   return ssao;
}
