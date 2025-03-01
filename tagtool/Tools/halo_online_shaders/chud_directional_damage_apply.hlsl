#line 1 "source\rasterizer\hlsl\chud_cortana_composite.hlsl"

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


//@generate chud_simple

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

LOCAL_SAMPLER_2D(damage_sampler, 1);

struct chud_output_cortana
{
	float4 HPosition	 :SV_Position;
	float2 Texcoord		 :TEXCOORD0;
	float2 Texcoord2	 :TEXCOORD1; // <>
};

chud_output_cortana default_vs(vertex_type IN)
{
    chud_output_cortana OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    float3 virtual_position_unity= float3(
		virtual_position.x/chud_screen_size.z,
		virtual_position.y/chud_screen_size.w,
		virtual_position.z);
    
	//OUT.VirtualPos= float4(virtual_position_unity, 0);
	float4 hposition= chud_virtual_to_screen(virtual_position);
    OUT.HPosition= hposition;
    OUT.Texcoord= (IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw);
	OUT.Texcoord2= (float2(hposition.x + 0.5, 1.0 - (hposition.y + 0.5)) - chud_screenshot_info.zw / chud_screen_size.xy) / chud_screenshot_info.xy;
	
    return OUT;
}

// pixel fragment entry points
float4 default_ps(chud_output_cortana IN) : SV_Target
{
	float4 foreground= sample2D(damage_sampler, IN.Texcoord2);		// damage blend
	float4 other_guy= sample2D(basemap_sampler, IN.Texcoord);		// microtexture
	float4 result= float4(foreground.rgb * other_guy.rgb, other_guy.a * foreground.a * LDR_ALPHA_ADJUST);
	
	return result;
}