#line 1 "source\rasterizer\hlsl\chud_texture_cam.hlsl"

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
// color output A= primary background color
// color output B= secondary background color
// color output C= highlight color
// color output D= flash color
// 
// ---- SCALAR OUTPUTS
// scalar output A= flash value; if 1, uses 'flash color', if 0 uses blended primary/secondary background
// scalar output B= unused
// scalar output C= unused
// scalar output D= unused
// scalar output E= unused
// scalar output F= unused

// ---- BITMAP CHANNELS
// A: alpha
// R: unused
// G: selects between primary (255) and secondary (0) color
// B: highlight channel

LOCAL_SAMPLER_2D(texturecam_sampler, 1);

chud_output default_vs(vertex_type IN)
{
    chud_output OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    OUT.MicroTexcoord= virtual_position.xy/4;
    OUT.HPosition= chud_virtual_to_screen(virtual_position);
	OUT.Texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;
	
    return OUT;
}

float4 build_subpixel_result(float2 texcoord)
{
	float4 bitmap_result= sample2D(basemap_sampler, texcoord);
	float4 texcam_result= sample2D(texturecam_sampler, texcoord);
	bitmap_result.rgb*=texcam_result.rgb;
	return bitmap_result;
}

// pixel fragment entry points
accum_pixel default_ps(chud_output IN) : SV_Target
{
	float4 result= build_subpixel_result(IN.Texcoord);

	return chud_compute_result_pixel(result);
}
