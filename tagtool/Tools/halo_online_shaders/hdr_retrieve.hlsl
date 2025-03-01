#line 1 "source\rasterizer\hlsl\hdr_retrieve.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"

//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

#define HDR_RETRIEVE_TEX_SIZE 256

struct screen_output
{
   float4 HPosition	:SV_Position;
   //float2 Texcoord	:TEXCOORD0;
   //float3 color		:COLOR0;
};

screen_output default_vs(vertex_type IN)
{
   screen_output OUT;

   //OUT.Texcoord = IN.texcoord;
   OUT.HPosition.xy= IN.position;
   OUT.HPosition.z = 0.5f;
   OUT.HPosition.w = 1.0f;
   //OUT.color= IN.color;

   return OUT;
}


// pixel fragment entry points

float4 default_ps(screen_output IN, SCREEN_POSITION_INPUT(screen_pos)) : SV_Target
{
   float val = -sample2D(source_sampler, float2(0.5f, 0.5f) ).r;
   
   float index = (val + 8.0f) / 24.0f * HDR_RETRIEVE_TEX_SIZE * HDR_RETRIEVE_TEX_SIZE;
   
   float screen_index = screen_pos.y * HDR_RETRIEVE_TEX_SIZE + screen_pos.x;
   
   clip(index - screen_index);
   
   return 1.0f;
}
