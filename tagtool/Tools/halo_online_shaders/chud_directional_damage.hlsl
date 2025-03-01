#line 1 "source\rasterizer\hlsl\chud_directional_damage.hlsl"

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

#define IGNORE_SCREENSHOT_TILING
#include "chud_util.fx"

//@generate chud_simple


// ==== SHADER DOCUMENTATION
// shader: chud_directional_damage
// 
// special case shader, called manually in code.  not for chud widget use

chud_output default_vs(vertex_type IN)
{
    chud_output OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    OUT.MicroTexcoord= virtual_position.xy/4;
    OUT.HPosition= chud_virtual_to_screen(virtual_position);
	OUT.Texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;
	
    return OUT;
}

float4 handle_screen_flash(float2 position, float4 data, float4 color, float center_fade)
{
	float dist= distance(position, data.xy);
	float size= data.z;
	
	if (size>0)
	{
		float t_to_center= max(0.0, 1.0 - dist/(size));
		float inner_outer_blend= cos(t_to_center*3.141592)*-0.5 + 0.5;
		float4 result;
		result.a= inner_outer_blend*color.a + (1.0f - inner_outer_blend)*data.w;
		result.rgb= color * result.a;
		
		return result;
	}
	else
	{
		return float4(0,0,0,0);
	}
}

float get_screen_flash_alpha(float2 position)
{
	float2 difference_vector= position - chud_screen_flash_center.xy;
	difference_vector.xy/= (chud_screen_flash_center.zz);
	float dist= distance(difference_vector, float2(0,0));
	
	float t_to_center= max(0.0, 1.0 - dist);
	float t= t_to_center;
	float intensity= cos(t*3.141592)*-0.5 + 0.5;
	intensity= pow(intensity, 0.5);
	
	float result= 1.0f - (intensity*0.4+0.0);
	
	return result;	
}

// pixel fragment entry points
float4 default_ps(chud_output IN) : SV_Target
{
	float center_fade= get_screen_flash_alpha(IN.Texcoord.xy);
	
	float4 result=		 handle_screen_flash(	IN.Texcoord.xy,	chud_screen_flash0_data, chud_screen_flash0_color, center_fade);
	result=		result + handle_screen_flash(	IN.Texcoord.xy,	chud_screen_flash1_data, chud_screen_flash1_color, center_fade);
	result=		result + handle_screen_flash(	IN.Texcoord.xy,	chud_screen_flash2_data, chud_screen_flash2_color, center_fade);
	result=		result + handle_screen_flash(	IN.Texcoord.xy,	chud_screen_flash3_data, chud_screen_flash3_color, center_fade);

	// clamp maximum total alpha	
	float clamped_alpha= min(result.a, 0.3);
	
	// re-scale weighted colors to match the clamped alpha
	result.rgba= result.rgba * clamped_alpha / max(result.a, 0.0001);
	
	return result;
}
