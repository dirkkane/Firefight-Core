#line 1 "source\rasterizer\hlsl\chud_cortana_camera.hlsl"
// note- this got deprecated and replaced with the contents of chud_simple

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

chud_output default_vs(vertex_type IN)
{
    chud_output OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    OUT.MicroTexcoord= virtual_position.xy/4;
    OUT.HPosition= chud_virtual_to_screen(virtual_position);
	OUT.Texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;
	
    return OUT;
}

float4 build_subpixel_result_shared(float4 bitmap_result )
{
	float4 background= chud_color_output_A*bitmap_result.g + chud_color_output_B*(1.0 - bitmap_result.g);
	background= background*(1.0 - chud_scalar_output_ABCD.x) + chud_color_output_D*chud_scalar_output_ABCD.x;
	float4 result= (background + chud_color_output_C*bitmap_result.b);
	result.a= bitmap_result.a;
	
	result.a*=chud_scalar_output_EF.w;
	
	return result;
}

float4 build_subpixel_result(float2 texcoord)
{
	float4 bitmap_result= sample2D(basemap_sampler, texcoord);
	return build_subpixel_result_shared(bitmap_result);
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

// pixel fragment entry points
accum_pixel default_ps(chud_output IN) : SV_Target
{
#ifndef pc
	float subsample_scale= 1.0/9.0;

	float4 gradients;
	float2 texcoord= IN.Texcoord;
	
	asm {
		getGradients gradients, texcoord, basemap_sampler 
	};
	
	//gradients*=2.0;
	//float4 result= subsample_scale*build_subpixel_result(IN.Texcoord);
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 1.0/3.0, -1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 1.0/3.0, 0.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 1.0/3.0, 1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -1.0/3.0, -1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -1.0/3.0, 0.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -1.0/3.0, 1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 0.0, -1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 0.0, 1.0/3.0));
	
	//float4 result= tex2D(basemap_sampler, IN.Texcoord);
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, 1.0/3.0, -1.0/3.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, 1.0/3.0, 0.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, 1.0/3.0, 1.0/3.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, -1.0/3.0, -1.0/3.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, -1.0/3.0, 0.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, -1.0/3.0, 1.0/3.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, 0.0, -1.0/3.0));
	//result+= tex2D(basemap_sampler, build_subsample_texcoord(texcoord, gradients, 0.0, 1.0/3.0));
	//result= build_subpixel_result_shared(result * subsample_scale);	
	
	float4 result= 0.0;
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients, -2.0/9.0,  2.0/9.0));
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients, -2.0/9.0, -2.0/9.0));
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients,  2.0/9.0, -2.0/9.0));
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients,  2.0/9.0,  2.0/9.0));
	result /= 4.0;
	result= build_subpixel_result_shared(result);	


#else // pc
	float4 result= build_subpixel_result(IN.Texcoord);
#endif // pc

	return chud_compute_result_pixel(result);
}
