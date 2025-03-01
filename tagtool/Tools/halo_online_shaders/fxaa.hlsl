#line 1 "source\rasterizer\hlsl\fxaa.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "fxaa_registers.fx"
#include "postprocess_registers.fx"

//@generate screen

#define SCREEN_WIDTH_RCP   k_postprocess_pixel_size.x
#define SCREEN_HEIGHT_RCP  k_postprocess_pixel_size.y


#define HLSL_ATTRIB_ISOLATE [isolate]
#define HLSL_ATTRIB_UNROLL  [unroll]
#define HLSL_ATTRIB_BRANCH  [branch]


#define FXAA_PC 1
#if DX_VERSION == 9
#define FXAA_HLSL_3 1
#elif DX_VERSION == 11
#define FXAA_HLSL_5 1
#endif
#define FXAA_QUALITY__PRESET 12
//#define FXAA_GREEN_AS_LUMA 1


#define __fxaaQualitySubpix  0.25f
#define __fxaaQualityEdgeThreshold 0.166f
#define __fxaaQualityEdgeThresholdMin 0.0833f
         
#include "edge_aa_vsout.fx"

#ifndef VERTEX_SHADER
#include "fxaa3_11.fx"
#endif

LOCAL_SAMPLER_2D(source_sampler, 0);

struct VS_OUTPUT
{
   float4 hpos : SV_Position;
   EDGE_AA_VS_OUTPUT edge_aa;
};


VS_OUTPUT default_vs(vertex_type IN)
{
   VS_OUTPUT   res;

   res.hpos.xy = IN.position;
   res.hpos.z  = 0.5f;
   res.hpos.w  = 1.0f;

   //float2 TEXEL_SIZE = float2(1.0f / 1280.0f, 1.0f / 720.0f);

   float2 C  = IN.texcoord.xy;
   float2 L  = C + float2(-TEXEL_SIZE.x, 0);
   float2 R  = C + float2(TEXEL_SIZE.x, 0);
   float2 T  = C + float2(0, -TEXEL_SIZE.y);
   float2 B  = C + float2(0, TEXEL_SIZE.y);
   float2 RT = float2(R.x, T.y);
   float2 LT = float2(L.x, T.y);
   float2 RB = float2(R.x, B.y);
   float2 LB = float2(L.x, B.y);
   res.edge_aa.uv = C;
   res.edge_aa.uv1.xy = L;
   res.edge_aa.uv1.zw = R;
   res.edge_aa.uv2.xy = T;
   res.edge_aa.uv2.zw = B;
   res.edge_aa.uv3.xy = LT;
   res.edge_aa.uv3.zw = RB;
   res.edge_aa.uv4.xy = LB;
   res.edge_aa.uv4.zw = RT;   
   
   return res;
}


// pixel fragment entry points
#ifndef VERTEX_SHADER

float4 default_ps(
	SCREEN_POSITION_INPUT(screen_position), 
	EDGE_AA_VS_OUTPUT input) : SV_Target
{
   //return tex2D(source_sampler, input.uv.xy);
   //return FxaaPixelShader(source_sampler, input);
   
   return FxaaPixelShader(input.uv.xy,
      source_sampler,
      pixel_size.xy,
      __fxaaQualitySubpix,
      __fxaaQualityEdgeThreshold,
      __fxaaQualityEdgeThresholdMin
   );
}

#endif