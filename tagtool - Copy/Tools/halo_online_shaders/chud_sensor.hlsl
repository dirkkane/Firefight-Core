#line 1 "source\rasterizer\hlsl\chud_sensor.hlsl"

#define IGNORE_SKINNING_NODES

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"

#define LDR_ONLY
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

#include "chud_util.fx"

//@generate chud_fancy

// ==== SHADER DOCUMENTATION
// shader: chud_simple
// 
// ---- COLOR OUTPUTS
// color output A= solid color
// color output B= unused
// color output C= unused
// color output D= unused
// 
// ---- SCALAR OUTPUTS
// scalar output A= unused
// scalar output B= unused
// scalar output C= unused
// scalar output D= unused
// scalar output E= unused
// scalar output F= unused

// ---- BITMAP CHANNELS
// A: alpha
// R: unused
// G: selects between primary (0) and secondary (255) color
// B: highlight channel

struct chud_output_sensor
{
    float4 HPosition		: VS_POS_OUTPUT;
	float4 Color			: COLOR0;
	float2 Texcoord			: TEXCOORD0;
	float2 MicroTexcoord	: TEXCOORD1;
};

#ifdef VERTEX_SHADER
chud_output_sensor default_vs(vertex_type IN)
{
    chud_output_sensor OUT;
    
    //float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    float3 virtual_position= float3(IN.position.xy, 0);
    OUT.MicroTexcoord= virtual_position.xy/4;
    OUT.HPosition= chud_virtual_to_screen(virtual_position);
	OUT.Texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;
	OUT.Color= IN.color;
	
    return OUT;
}
#endif

// pixel fragment entry points
accum_pixel default_ps(chud_output_sensor IN) : SV_Target
{
	float4 bitmap_result= sample2D(basemap_sampler, IN.Texcoord);
	bitmap_result*= IN.Color;
	bitmap_result.a*=chud_scalar_output_EF.w;
	return chud_compute_result_pixel(bitmap_result);
}
