#line 1 "source\rasterizer\hlsl\chud_cortana_composite.hlsl"

#define IGNORE_SKINNING_NODES
#define SKIP_POSTPROCESS_EXPOSURE_REGISTERS

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
#include "postprocess_registers.fx"


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

LOCAL_SAMPLER_2D(cortana_sampler, 1);
LOCAL_SAMPLER_2D(goo_sampler, 2);

struct chud_output_cortana
{
	float4 HPosition	 :SV_Position;
	float2 Texcoord		 :TEXCOORD0;
	float4 VirtualPos	 :TEXCOORD1; // <>
	float2 GooTexcoord	 :TEXCOORD2;
	float  hposition_z	 :TEXCOORD3;
};

chud_output_cortana default_vs(vertex_type IN)
{
    chud_output_cortana OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    float3 virtual_position_unity= float3(
		virtual_position.x/chud_screen_size.z,
		virtual_position.y/chud_screen_size.w,
		virtual_position.z);
    
	OUT.VirtualPos= float4(virtual_position_unity, 0);
	float4 hposition= chud_virtual_to_screen(virtual_position);
    OUT.HPosition= hposition;
	OUT.Texcoord= float2((hposition.x + 0.5)/hposition.z, (1.0 - (hposition.y + 0.5))/hposition.z);
	OUT.GooTexcoord= IN.texcoord;
	OUT.hposition_z= hposition.z;
	
    return OUT;
}

float4 huesat(float4 in_color)
{
	return float4(mul(float4(in_color.x, in_color.y, in_color.z, 1.0f), p_postprocess_hue_saturation_matrix), 1.0);
}

float4 thresh(float4 in_color)
{
	float t_in= min(1.0, dot(in_color, cortana_comp_solarize_inmix));
	float one_minus_solarize = 1.0 - cortana_comp_solarize_result.x;
#if DX_VERSION == 11
	one_minus_solarize = max(0.000001, one_minus_solarize);
#endif	
	
#if APPLY_FIXES
	float result= step(cortana_comp_solarize_result.x, t_in)*pow(abs((t_in - cortana_comp_solarize_result.x)/one_minus_solarize), cortana_comp_solarize_result.y);
#else
	float result= step(cortana_comp_solarize_result.x, t_in)*pow(((t_in - cortana_comp_solarize_result.x)/one_minus_solarize), cortana_comp_solarize_result.y);
#endif
	
	return float4(result*cortana_comp_solarize_outmix);
}

float4 centered_sample(float2 centered_texcoord, float scale, float t_value)
{
	float2 texcoord= (centered_texcoord*scale)*0.5 + float2(0.5, 0.5);
	return sample2D(cortana_sampler, texcoord);
}

float4 doubling(float2 texcoord)
{
	float2 centered= texcoord*2.0 - 1.0;
	
	float4 partial_result= 
		centered_sample(
			centered, 
			0.8*cortana_comp_doubling_result.z,
			0.75) + 
		centered_sample(
			centered, 
			0.5*cortana_comp_doubling_result.z,
			0.25);
			
	float val= dot(partial_result, cortana_comp_doubling_inmix);
	return cortana_comp_doubling_result.x*cortana_comp_doubling_outmix*val;
}

float4 comp_colorize(float4 in_color)
{
	float lum= min(1.0, dot(in_color, cortana_comp_colorize_inmix));
	float4 hsv_color= cortana_comp_colorize_result*float4(lum, lum, lum, lum);
	
	return hsv_color*cortana_comp_colorize_outmix;
}

float4 death_effect(float4 color, float key)
{
	float inten= color.r*(0.212671) + color.g*(0.715160) + color.b*(0.072169);
	float4 result= lerp(color, float4(inten, inten, inten, 0.0f), key);
	
	return result;
}

#define vignette_min cortana_vignette_data.x
#define vignette_max cortana_vignette_data.y

float4 gravemind_effect(float4 background, float4 foreground, float4 goo, float4 virtual_texcoord)
{
	float dist= distance(virtual_texcoord.xy, float2(0.5, 0.5));
	float vignette_t= (dist - vignette_min)/(vignette_max - vignette_min);
	vignette_t= clamp(vignette_t, 0.0, 1.0);
	float vignette= pow(vignette_t, 2.0);
	float floodification= 0.5*foreground.r+vignette;

	//background= death_effect(background, foreground.r, virtual_texcoord);
	background= background * (1.0 - (0.4*floodification*goo + 0.6*floodification));
	
	return background;
}

float3 d3dSRGBInvGamma(float3 CSRGB)
{
   return (CSRGB <= .04045f) ? (CSRGB / 12.92f) : pow((CSRGB + 0.055f) / 1.055f, 2.4f);
}

// pixel fragment entry points
accum_pixel default_ps(chud_output_cortana IN) : SV_Target
{
	float2 adjusted_texcoord= IN.Texcoord*IN.hposition_z;
	float4 background= cortana_back_colormix_result*sample2D(basemap_sampler, adjusted_texcoord);
	float4 foreground= sample2D(cortana_sampler, adjusted_texcoord);
	float4 goo= sample2D(goo_sampler, IN.GooTexcoord);
	
	background= huesat(background);
	
	float4 background_gravemind= gravemind_effect(background, foreground, goo, IN.VirtualPos);
	
	foreground+= doubling(adjusted_texcoord);
	foreground+= thresh(foreground);
	
	if (chud_comp_colorize_enabled)
	{
		foreground= comp_colorize(foreground);
	}

	accum_pixel result_pixel;
	result_pixel.color= background_gravemind+foreground;

	// there is a difference here but i dont think it matters

#ifdef pc	
	result_pixel.color.rgb = d3dSRGBInvGamma(result_pixel.color.rgb);
#endif
	
	return result_pixel;
	
	//return chud_compute_result_pixel(background+foreground);
}