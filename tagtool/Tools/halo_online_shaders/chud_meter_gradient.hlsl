#line 1 "source\rasterizer\hlsl\chud_meter_gradient.hlsl"

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
// shader: chud_meter_gradient
//
// note: the 'meter value' for this shader is implicit, not defined 
// in the texture! it's derived from the 'x' value of the texcoord,
// if the bitmap sequence is it's own bitmap (not a sub-rectangle of 
// a larger bitmap) then the left edge will have a meter value of '0'
// and the right edge will have a meter value of 'meter max' which
// is stored in [scalar output E]
// 
// ---- COLOR OUTPUTS
// color output A= primary color
// color output B= secondary color
// color output C= gradient color
// color output D= empty color
// 
// ---- SCALAR OUTPUTS
// scalar output A= meter amount
// scalar output B= gradient width
// scalar output C= gradient alpha scale (>1 makes flash less opaque)
// scalar output D= empty alpha scale (<1 makes empty more opaque)
// scalar output E= meter max
// scalar output F= unused

// ---- BITMAP CHANNELS
// A: alpha
// R: unused
// G: selects between primary (0) and secondary (255) color
// B: unused

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
#ifndef pc
	asm{
	tfetch2D bitmap_result, texcoord, basemap_sampler, MinFilter=linear, MagFilter=linear
	};
#else
	bitmap_result= sample2D(basemap_sampler, texcoord);
#endif
	//float this_meter_value= 255.0*bitmap_result.b;
	float this_meter_value= chud_scalar_output_EF.x*texcoord;
	float edge_meter_value= chud_scalar_output_ABCD.x;
	float gradient_width= chud_scalar_output_ABCD.y;
	float edge_to_end= chud_scalar_output_EF.x - edge_meter_value; 
	float gradient_min= edge_meter_value-gradient_width;
	float gradient_max= edge_meter_value;
	float blendout_gradient_width= gradient_width*0.25;
	
	if (edge_to_end<blendout_gradient_width)
	{
		gradient_min+= blendout_gradient_width-edge_to_end;
		gradient_max+= blendout_gradient_width-edge_to_end;
	}
	
	float flash_amount= 0;
	
	if (this_meter_value>gradient_min)
	{
		if (this_meter_value<=gradient_max)
		{
			flash_amount= (this_meter_value - gradient_min)/(gradient_max-gradient_min);
		}
		else
		{
			flash_amount= 1.0;
		}		
	}
	
	flash_amount= pow(flash_amount, 4.0);
	
	float4 result= chud_color_output_D;
	result.a= bitmap_result.a*chud_scalar_output_ABCD.w;
	
	if (this_meter_value<=edge_meter_value)
	{
		float4 base_color= chud_color_output_A * (1.0f - bitmap_result.g) + chud_color_output_B*bitmap_result.g;
	
		result= base_color + chud_color_output_C*(flash_amount);
		result.a= bitmap_result.a*(1.0 - flash_amount) + (bitmap_result.a*chud_scalar_output_ABCD.z)*flash_amount;
	}
	
	//result.a*=chud_scalar_output_EF.w;
		
	return result;
}

float2 build_subsample_texcoord(float2 texcoord, float4 gradients, float dh, float dv)
{
	float2 result= texcoord;
	result+= gradients.xz*dh;
	result+= gradients.yw*dv;
	
	return result;
}

// pixel fragment entry points
accum_pixel default_ps(chud_output IN) : SV_Target
{
#ifndef pc
	//float subsample_scale= 1.0/9.0;
	//float4 result= subsample_scale*build_subpixel_result(IN.Texcoord);

	float4 gradients;
	float2 texcoord= IN.Texcoord;
	
	asm {
		getGradients gradients, texcoord, basemap_sampler 
	};
	
	//gradients*=2.0;
	
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 1.0/3.0, -1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 1.0/3.0, 0.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 1.0/3.0, 1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -1.0/3.0, -1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -1.0/3.0, 0.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -1.0/3.0, 1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 0.0, -1.0/3.0));
	//result+= subsample_scale*build_subpixel_result(build_subsample_texcoord(texcoord, gradients, 0.0, 1.0/3.0));
	
	float4 result= 0.0;
	result+= build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -2.0/9.0,  2.0/9.0));
	result+= build_subpixel_result(build_subsample_texcoord(texcoord, gradients, -2.0/9.0, -2.0/9.0));
	result+= build_subpixel_result(build_subsample_texcoord(texcoord, gradients,  2.0/9.0, -2.0/9.0));
	result+= build_subpixel_result(build_subsample_texcoord(texcoord, gradients,  2.0/9.0,  2.0/9.0));
	result /= 4.0;
	result.a*=chud_scalar_output_EF.w;


#else // pc
	float4 result= build_subpixel_result(IN.Texcoord);
	result.a*=chud_scalar_output_EF.w;
#endif // pc

	return chud_compute_result_pixel(result);
}