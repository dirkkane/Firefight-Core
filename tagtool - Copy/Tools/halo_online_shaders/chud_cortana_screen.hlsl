#line 1 "source\rasterizer\hlsl\chud_cortana_screen.hlsl"

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

chud_output default_vs(vertex_type IN)
{
    chud_output OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    OUT.MicroTexcoord= virtual_position.xy/4;
    OUT.HPosition= chud_virtual_to_screen(virtual_position);
	OUT.Texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;
	
    return OUT;
}

float4 build_subpixel_result_shared(float4 result)
{
	result.a*=chud_scalar_output_EF.w;	
	return result;
}

float3 d3dSRGBInvGamma(float3 CSRGB)
{
   return (CSRGB <= .04045f) ? (CSRGB / 12.92f) : pow((CSRGB + 0.055f) / 1.055f, 2.4f);
}

float4 build_subpixel_result(float2 texcoord)
{
	float4 result= sample2D(basemap_sampler, texcoord);	

#ifdef pc
  result.rgb = d3dSRGBInvGamma(result.rgb);
#endif

	return build_subpixel_result_shared(result);
}

float2 build_subsample_texcoord(float2 texcoord, float4 gradients, float dh, float dv)
{
	float2 result= texcoord;
	result+= gradients.xz*dh;
	result+= gradients.yw*dv;
	
	return result;
}

float4 texture_lookup(float2 texcoord)
{
#ifndef pc
	float4 bitmap_result;
	asm{
	tfetch2D bitmap_result, texcoord, basemap_sampler, MinFilter=linear, MagFilter=linear
	};
	return bitmap_result;
#else
	float4 bitmap_result= sample2D(basemap_sampler, texcoord);
	return bitmap_result;
#endif
}

float4 bloom_sample_helper(float2 texcoord, float offset, float scale)
{
	return scale*0.5*(texture_lookup(float2(texcoord.x+offset, texcoord.y)) +
				  texture_lookup(float2(texcoord.x-offset, texcoord.y)));
}

float4 handle_bloom(float2 texcoord)
{
	float width= cortana_texcam_bloom_result.x;
	float exponent= cortana_texcam_bloom_result.y;
	float scale= cortana_texcam_bloom_result.z;
	float4 bloom_color= 
		bloom_sample_helper(texcoord, width*0.0, pow(1.0, exponent))+
		bloom_sample_helper(texcoord, width*0.05, pow(0.95, exponent))+
		bloom_sample_helper(texcoord, width*0.1, pow(0.9, exponent))+
		bloom_sample_helper(texcoord, width*0.15, pow(0.85, exponent))+
		bloom_sample_helper(texcoord, width*0.2, pow(0.8, exponent))+
		bloom_sample_helper(texcoord, width*0.25, pow(0.75, exponent))+
		bloom_sample_helper(texcoord, width*0.3, pow(0.7, exponent))+
		bloom_sample_helper(texcoord, width*0.35, pow(0.65, exponent))+
		bloom_sample_helper(texcoord, width*0.4, pow(0.6, exponent))+
		bloom_sample_helper(texcoord, width*0.45, pow(0.55, exponent))+
		bloom_sample_helper(texcoord, width*0.5, pow(0.5, exponent))+
		bloom_sample_helper(texcoord, width*0.55, pow(0.45, exponent))+
		bloom_sample_helper(texcoord, width*0.6, pow(0.4, exponent))+
		bloom_sample_helper(texcoord, width*0.65, pow(0.35, exponent))+
		bloom_sample_helper(texcoord, width*0.7, pow(0.3, exponent))+
		bloom_sample_helper(texcoord, width*0.75, pow(0.25, exponent))+
		bloom_sample_helper(texcoord, width*0.8, pow(0.2, exponent))+
		bloom_sample_helper(texcoord, width*0.85, pow(0.15, exponent))+
		bloom_sample_helper(texcoord, width*0.9, pow(0.1, exponent))+
		bloom_sample_helper(texcoord, width*0.95, pow(0.05, exponent))+
		bloom_sample_helper(texcoord, width*1.0, pow(0.0, exponent));
		
	float bloom_scalar= min(1.0, dot(bloom_color, cortana_texcam_bloom_inmix));	
	return scale*float4(bloom_scalar*cortana_texcam_bloom_outmix);	
}

// pixel fragment entry points
accum_pixel default_ps(chud_output IN) : SV_Target
{
	float4 result= build_subpixel_result(IN.Texcoord);

	//float4 bloom_result= handle_bloom(IN.Texcoord);
	//return chud_compute_result_pixel(result*cortana_texcam_colormix_result+bloom_result);
	return chud_compute_result_pixel(result*cortana_texcam_colormix_result);
}