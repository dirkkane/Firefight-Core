#line 1 "source\rasterizer\hlsl\debug2d.hlsl"

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "debug_2d_registers.fx"

//@generate debug

struct debug_output
{
   float4 HPosition	:SV_Position;
   float3 Color		:COLOR0;
};

#ifdef VERTEX_SHADER

debug_output default_vs(vertex_type IN)
{
   debug_output OUT;

   OUT.HPosition.xy= IN.position.xy;
   OUT.HPosition.zw= 1.f;
   OUT.Color= IN.color;

   return OUT;
}

#endif

// pixel fragment entry points

float4 default_ps(debug_output IN) : SV_Target
{
   return float4(IN.Color * fill_color.r, 1.0f);
}
