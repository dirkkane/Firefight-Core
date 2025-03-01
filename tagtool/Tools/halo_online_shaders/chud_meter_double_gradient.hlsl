#line 1 "source\rasterizer\hlsl\chud_meter_double_gradient.hlsl"

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
// color output A= normal meter color
// color output B= record meter color
// color output C= chapter color
// color output D= buffer'd theta color
// 
// ---- SCALAR OUTPUTS
// scalar output A= meter amount
// scalar output B= meter max
// scalar output C= gradient alpha scale (>1 makes flash less opaque)
// scalar output D= empty alpha scale (<1 makes empty more opaque)
// scalar output E= gradient width (absolute, so 0.5 would be half the meter width)
// scalar output F= other meter amount

// ---- BITMAP CHANNELS
// A: alpha (except for empty meter regions, which multiply by empty alpha scale)
// R: unused
// G: highlight channel; 128 keeps the same, > screens, < multiplies
// B: meter mask



chud_output default_vs(vertex_type IN)
{
    chud_output OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);
    OUT.MicroTexcoord= virtual_position.xy/4;
    OUT.HPosition= chud_virtual_to_screen(virtual_position);
	OUT.Texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;
	
    return OUT;
}

float get_overlap(float t, float min, float max)
{
	float above_min= step(min, t);
	float below_max= step(t, max);
	
	return above_min*below_max;	
}

float get_chapter_overlap(float t_min, float t_max, float4 chapvec)
{
	float4 tvec_min= float4(t_min, t_min, t_min, t_min);
	float4 tvec_max= float4(t_max, t_max, t_max, t_max);
	float4 above_min= step(tvec_min, chapvec);
	float4 below_max= step(chapvec, tvec_max);
	
	return dot(above_min*below_max, float4(1,1,1,1));	
}

float get_cusp_fade(float t_val, float min, float max)
{
	float above_min= step(min, t_val);
	float below_max= step(t_val, max);
	float in_range= above_min*below_max;
	float range_t= 1.0 - pow((t_val - min)/(max - min), 1.5);
	
	return in_range*range_t + (1.0-in_range); 	
}

#define record_min chud_savedfilm_data.x
#define buffered_theta chud_savedfilm_data.y
#define bar_theta chud_savedfilm_data.z

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

	float chapter_size= 1.0/chud_scalar_output_ABCD.x;
	float pixel_meter_min= texcoord.x;
	float pixel_meter_max= pixel_meter_min+chapter_size;
	
	float chapter_overlap= get_chapter_overlap(pixel_meter_min, pixel_meter_max, chud_savedfilm_chap1);
	chapter_overlap+= get_chapter_overlap(pixel_meter_min, pixel_meter_max, chud_savedfilm_chap2);
	chapter_overlap+= get_chapter_overlap(pixel_meter_min, pixel_meter_max, chud_savedfilm_chap3);
	float record_overlap= get_overlap(pixel_meter_min, record_min, bar_theta);
	float buffered_boundary_overlap= get_chapter_overlap(pixel_meter_min, pixel_meter_max, float4(buffered_theta, -1, -1, -1));
	float normal_overlap= get_overlap(pixel_meter_min, 0.0, bar_theta)*(1.0 - record_overlap);
	float null_overlap= 1.0 - min(1.0, chapter_overlap+record_overlap+normal_overlap);
	float cusp_fade= get_cusp_fade(pixel_meter_min, buffered_theta-0.05, buffered_theta);
		
	float4 result= float4(0,0,0,0);
	float4 bar_alpha= float4(0, 0, 0, cusp_fade*bitmap_result.a);
	
	result+= ((chud_color_output_A+bar_alpha)*normal_overlap + (chud_color_output_B+bar_alpha)*record_overlap);
	
	result+= buffered_boundary_overlap*(chud_color_output_D + float4(0,0,0,bitmap_result.a));
	result+= chapter_overlap*(chud_color_output_C + float4(0,0,0,bitmap_result.a));
	//result+= chud_color_output_A*normal_overlap + chud_color_output_B*record_overlap;
	
	//result.a= (1.0 - null_overlap)*bitmap_result.a;

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
	float4 result= float4(0,0,0,0);
#endif // pc

	//float4 result= build_subpixel_result(IN.Texcoord);
	//result.a*=chud_scalar_output_EF.w;

	return chud_compute_result_pixel(result);
}