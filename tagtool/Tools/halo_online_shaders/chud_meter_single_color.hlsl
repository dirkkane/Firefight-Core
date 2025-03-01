#line 1 "source\rasterizer\hlsl\chud_meter_single_color.hlsl"

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
// shader: chud_meter_single_color
//
// for things like the scoreboard meters, or other meters that are
// restricted to only a single color input
//
// ---- COLOR OUTPUTS
// color output A= the single color
// color output B= unused
// color output C= unused
// color output D= unused
// 
// ---- SCALAR OUTPUTS
// scalar output A= meter amount
// scalar output B= meter max
// scalar output C= gradient alpha scale (>1 makes flash less opaque)
// scalar output D= empty alpha scale (<1 makes empty more opaque)
// scalar output E= gradient width (absolute, so 0.5 would be half the meter width)
// scalar output F= unused

// ---- BITMAP CHANNELS
// A: alpha (except for empty meter regions, which multiply by empty alpha scale)
// R: unused
// G: highlight channel; 128 keeps the same, > screens, < multiplies
// B: meter mask

#define METER_AMOUNT chud_scalar_output_ABCD.x
#define METER_MAX chud_scalar_output_ABCD.y
#define GRADIENT_ALPHA_SCALE chud_scalar_output_ABCD.z
#define EMPTY_ALPHA_SCALE chud_scalar_output_ABCD.w
#define GRADIENT_WIDTH chud_scalar_output_EF.x
//#define METER_AMOUNT chud_scalar_output_EF.y

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

	float tex_t_value= (texcoord.x - chud_texture_bounds.x)/(chud_texture_bounds.y - chud_texture_bounds.x);
	float this_meter_value= METER_MAX*tex_t_value;
	float edge_meter_value= METER_AMOUNT;
	float tint_parameter= 2.0*bitmap_result.g;
	float add_amount= max(1.0f, tint_parameter) - 1.0f;
	float multiply_amount= min(1.0f, tint_parameter);
	float3 multiply_color= chud_blend3(chud_color_output_A.rgb, float3(1, 1, 1), multiply_amount);
	
	float gradient_max= edge_meter_value;
	float gradient_min= gradient_max - GRADIENT_WIDTH*METER_MAX;
	
	float4 result;
	result.rgb= chud_color_output_A*multiply_color + chud_color_output_A*add_amount;
	result.a= bitmap_result.a;
	
	if (this_meter_value>edge_meter_value)
	{
		float meter_alpha_ding= chud_blend(1.0f, EMPTY_ALPHA_SCALE, bitmap_result.b);
		result.a= result.a*meter_alpha_ding;
	}
	else
	{
		float gradient_t= (this_meter_value - gradient_min)/(gradient_max - gradient_min);
		gradient_t= max(0, gradient_t)*bitmap_result.b;
		
		float gradient_amount= pow(gradient_t, 16.f);
		
		result.rgb= result.rgb + float3(gradient_amount, gradient_amount, gradient_amount);
	}
		
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
	float subsample_scale= 1.0/9.0;
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