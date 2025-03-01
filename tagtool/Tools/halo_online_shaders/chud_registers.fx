#ifndef _CHUD_UTIL_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _CHUD_UTIL_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "chud_registers.h"

// vertex shader/constant decl for all chud shaders

VERTEX_CONSTANT(float4, chud_widget_offset, k_vs_chud_widget_offset);
VERTEX_CONSTANT(float4, chud_widget_transform1, k_vs_chud_widget_transform1);
VERTEX_CONSTANT(float4, chud_widget_transform2, k_vs_chud_widget_transform2);
VERTEX_CONSTANT(float4, chud_widget_transform3, k_vs_chud_widget_transform3);
VERTEX_CONSTANT(float4, chud_screen_size, k_vs_chud_screen_size); // final_size_x, final_size_y, virtual_size_x, virtual_size_y
VERTEX_CONSTANT(float4, chud_basis_0, k_vs_chud_basis_0);
VERTEX_CONSTANT(float4, chud_basis_1, k_vs_chud_basis_1);
VERTEX_CONSTANT(float4, chud_basis_2, k_vs_chud_basis_2);
VERTEX_CONSTANT(float4, chud_basis_3, k_vs_chud_basis_3);
VERTEX_CONSTANT(float4, chud_screen_scale_and_offset, k_vs_chud_screen_scale_and_offset); // screen_offset_x, screen_half_scale_x, screen_offset_y, screen_half_scale_y
VERTEX_CONSTANT(float4, chud_project_scale_and_offset, k_vs_chud_project_scale_and_offset); // x_scale, y_scale, offset_z, z_value_scale
VERTEX_CONSTANT(float4, chud_widget_mirror, k_vs_chud_widget_mirror); // <mirror_x, mirror_y, 0, 0>
VERTEX_CONSTANT(float4, chud_screenshot_info, k_vs_chud_screenshot_info); // <scale_x, scale_y, offset_x, offset_y>
VERTEX_CONSTANT(float4, chud_texture_transform, k_vs_chud_texture_transform); // <scale_x, scale_y, offset_x, offset_y>
VERTEX_CONSTANT(bool, chud_cortana_vertex, k_vs_chud_cortana_vertex); 

PIXEL_CONSTANT(bool, chud_cortana_pixel, k_ps_chud_cortana_pixel);
PIXEL_CONSTANT(float4, chud_color_output_A, k_ps_chud_color_output_A);
PIXEL_CONSTANT(float4, chud_color_output_B, k_ps_chud_color_output_B);
PIXEL_CONSTANT(float4, chud_color_output_C, k_ps_chud_color_output_C);
PIXEL_CONSTANT(float4, chud_color_output_D, k_ps_chud_color_output_D);
PIXEL_CONSTANT(float4, chud_color_output_E, k_ps_chud_color_output_E);
PIXEL_CONSTANT(float4, chud_color_output_F, k_ps_chud_color_output_F);
PIXEL_CONSTANT(float4, chud_scalar_output_ABCD, k_ps_chud_scalar_output_ABCD);// [a, b, c, d]
PIXEL_CONSTANT(float4, chud_scalar_output_EF, k_ps_chud_scalar_output_EF);// [e, f, 0, global_hud_alpha]
PIXEL_CONSTANT(float4, chud_texture_bounds, k_ps_chud_texture_bounds); // <x0, x1, y0, y1>
PIXEL_CONSTANT(float4, chud_savedfilm_chap1, k_ps_chud_savedfilm_chap1); // <chap0..3>
PIXEL_CONSTANT(float4, chud_savedfilm_chap2, k_ps_chud_savedfilm_chap2); // <chap4..7>
PIXEL_CONSTANT(float4, chud_savedfilm_chap3, k_ps_chud_savedfilm_chap3); // <chap8,9,-1,-1>
PIXEL_CONSTANT(float4, chud_savedfilm_data, k_ps_chud_savedfilm_data); // <record_min, buffered_theta, bar_theta, 0.0>


PIXEL_CONSTANT(float4, chud_widget_transform1_ps, k_ps_chud_widget_transform1);
PIXEL_CONSTANT(float4, chud_widget_transform2_ps, k_ps_chud_widget_transform2);
PIXEL_CONSTANT(float4, chud_widget_transform3_ps, k_ps_chud_widget_transform3);
PIXEL_CONSTANT(float4, chud_widget_mirror_ps, k_ps_chud_widget_mirror);

// these can overlap saved film, but be careful about everything else!
PIXEL_CONSTANT(float4, chud_screen_flash0_color, k_ps_chud_screen_flash0_color); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash0_data, k_ps_chud_screen_flash0_data); // virtual_x, virtual_y, size, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash1_color, k_ps_chud_screen_flash1_color); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash1_data, k_ps_chud_screen_flash1_data); // virtual_x, virtual_y, size, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash2_color, k_ps_chud_screen_flash2_color); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash2_data, k_ps_chud_screen_flash2_data); // virtual_x, virtual_y, size, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash3_color, k_ps_chud_screen_flash3_color); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash3_data, k_ps_chud_screen_flash3_data); // virtual_x, virtual_y, size, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash_center, k_ps_chud_screen_flash_center); // virtual_x, virtual_y, radius_x, radius_y


// cortana constants
/*VERTEX_CONSTANT(float4, chud_cortana_basis_0, c35); // origin.x, origin.y, basis0.x, basis0.y
VERTEX_CONSTANT(float4, chud_cortana_basis_1, c36); // origin.x, origin.y, basis0.x, basis0.y
VERTEX_CONSTANT(float4, chud_cortana_c37, c37); // <noise_scale_x, noise_scale_y, noise_b_scale_x, noise_b_scale_y>
#define cortana_noise_a_scale_x			chud_cortana_c37.x
#define cortana_noise_a_scale_y			chud_cortana_c37.y
#define cortana_noise_b_scale_x			chud_cortana_c37.z
#define cortana_noise_b_scale_y			chud_cortana_c37.w
VERTEX_CONSTANT(float4, chud_cortana_basis_2, c38); // origin.x, origin.y, basis0.x, basis0.y
VERTEX_CONSTANT(float4, chud_cortana_basis_3, c39); // origin.x, origin.y, basis0.x, basis0.y

PIXEL_CONSTANT(float4, chud_cortana_c38, c38); // <position.x, position.y, noise_a_interpolant, noise_b_interpolant>
PIXEL_CONSTANT(float4, chud_cortana_c39, c39); // <pix.thresh, pix.persistence, pix.velocity, pix.turbulence>
PIXEL_CONSTANT(float4, chud_cortana_c40, c40); // <translation_scale_x, translation_scale_y, cortana_distance_t, 0>
#define cortana_position				chud_cortana_c38.xy
#define cortana_noise_interpolant		chud_cortana_c38.z
#define cortana_other_noise_interpolant	chud_cortana_c38.w
#define cortana_pixelation_threshold	chud_cortana_c39.x
#define cortana_pixelation_persistence	chud_cortana_c39.y
#define cortana_pixelation_velocity		chud_cortana_c39.z
#define cortana_pixelation_turbulence	chud_cortana_c39.w
#define cortana_translation_scale_x		chud_cortana_c40.x
#define cortana_translation_scale_y		chud_cortana_c40.y
#define cortana_distance_t				chud_cortana_c40.z*/

//  new cortana effect
PIXEL_CONSTANT(float4, cortana_back_colormix_result, k_ps_cortana_back_colormix_result);
PIXEL_CONSTANT(float4, cortana_back_hsv_result, k_ps_cortana_back_hsv_result);
PIXEL_CONSTANT(float4, cortana_texcam_colormix_result, k_ps_cortana_texcam_colormix_result);
PIXEL_CONSTANT(float4, cortana_comp_solarize_inmix, k_ps_cortana_comp_solarize_inmix);
PIXEL_CONSTANT(float4, cortana_comp_solarize_outmix, k_ps_cortana_comp_solarize_outmix);
PIXEL_CONSTANT(float4, cortana_comp_solarize_result, k_ps_cortana_comp_solarize_result);
PIXEL_CONSTANT(float4, cortana_comp_doubling_inmix, k_ps_cortana_comp_doubling_inmix);
PIXEL_CONSTANT(float4, cortana_comp_doubling_outmix, k_ps_cortana_comp_doubling_outmix);
PIXEL_CONSTANT(float4, cortana_comp_doubling_result, k_ps_cortana_comp_doubling_result);
PIXEL_CONSTANT(float4, cortana_comp_colorize_inmix, k_ps_cortana_comp_colorize_inmix);
PIXEL_CONSTANT(float4, cortana_comp_colorize_outmix, k_ps_cortana_comp_colorize_outmix);
PIXEL_CONSTANT(float4, cortana_comp_colorize_result, k_ps_cortana_comp_colorize_result);
PIXEL_CONSTANT(float4, cortana_texcam_bloom_inmix, k_ps_cortana_texcam_bloom_inmix);
PIXEL_CONSTANT(float4, cortana_texcam_bloom_outmix, k_ps_cortana_texcam_bloom_outmix);
PIXEL_CONSTANT(float4, cortana_texcam_bloom_result, k_ps_cortana_texcam_bloom_result);
PIXEL_CONSTANT(float4, cortana_vignette_data, k_ps_cortana_vignette_data);

PIXEL_CONSTANT(bool, chud_comp_colorize_enabled, k_ps_chud_comp_colorize_enabled);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CHUDVS)
	CBUFFER_CONST(CHUDVS,				float4,		chud_widget_offset,				k_vs_chud_widget_offset)
	CBUFFER_CONST(CHUDVS,				float4,		chud_widget_transform1,			k_vs_chud_widget_transform1)
	CBUFFER_CONST(CHUDVS,				float4,		chud_widget_transform2,			k_vs_chud_widget_transform2)
	CBUFFER_CONST(CHUDVS,				float4,		chud_widget_transform3,			k_vs_chud_widget_transform3)
	CBUFFER_CONST(CHUDVS,				float4,		chud_screen_size,				k_vs_chud_screen_size)
	CBUFFER_CONST(CHUDVS,				float4,		chud_basis_0,					k_vs_chud_basis_0)
	CBUFFER_CONST(CHUDVS,				float4,		chud_basis_1,					k_vs_chud_basis_1)
	CBUFFER_CONST(CHUDVS,				float4,		chud_basis_2,					k_vs_chud_basis_2)
	CBUFFER_CONST(CHUDVS,				float4,		chud_basis_3,					k_vs_chud_basis_3)
	CBUFFER_CONST(CHUDVS,				float4,		chud_screen_scale_and_offset,	k_vs_chud_screen_scale_and_offset)
	CBUFFER_CONST(CHUDVS,				float4,		chud_project_scale_and_offset,	k_vs_chud_project_scale_and_offset)
	CBUFFER_CONST(CHUDVS,				float4,		chud_widget_mirror,				k_vs_chud_widget_mirror)
	CBUFFER_CONST(CHUDVS,				float4,		chud_screenshot_info,			k_vs_chud_screenshot_info)
	CBUFFER_CONST(CHUDVS,				float4,		chud_texture_transform,			k_vs_chud_texture_transform)
	CBUFFER_CONST(CHUDVS,				bool,		chud_cortana_vertex,			k_vs_chud_cortana_vertex)
CBUFFER_END			
			
CBUFFER_BEGIN(CHUDPS)			
	CBUFFER_CONST(CHUDPS,				float4,		chud_color_output_A,			k_ps_chud_color_output_A)
	CBUFFER_CONST(CHUDPS,				float4,		chud_color_output_B,			k_ps_chud_color_output_B)
	CBUFFER_CONST(CHUDPS,				float4,		chud_color_output_C,			k_ps_chud_color_output_C)
	CBUFFER_CONST(CHUDPS,				float4,		chud_color_output_D,			k_ps_chud_color_output_D)
	CBUFFER_CONST(CHUDPS,				float4,		chud_color_output_E,			k_ps_chud_color_output_E)
	CBUFFER_CONST(CHUDPS,				float4,		chud_color_output_F,			k_ps_chud_color_output_F)
	CBUFFER_CONST(CHUDPS,				float4,		chud_scalar_output_ABCD,		k_ps_chud_scalar_output_ABCD)
	CBUFFER_CONST(CHUDPS,				float4,		chud_scalar_output_EF,			k_ps_chud_scalar_output_EF)
	CBUFFER_CONST(CHUDPS,				float4,		chud_texture_bounds,			k_ps_chud_texture_bounds)
	CBUFFER_CONST(CHUDPS,				float4,		chud_savedfilm_chap1,			k_ps_chud_savedfilm_chap1)
	CBUFFER_CONST(CHUDPS,				float4,		chud_savedfilm_chap2,			k_ps_chud_savedfilm_chap2)
	CBUFFER_CONST(CHUDPS,				float4,		chud_savedfilm_chap3,			k_ps_chud_savedfilm_chap3)
	CBUFFER_CONST(CHUDPS,				float4,		chud_savedfilm_data,			k_ps_chud_savedfilm_data)
	CBUFFER_CONST(CHUDPS,				bool,		chud_cortana_pixel,				k_ps_chud_cortana_pixel)
	CBUFFER_CONST(CHUDPS,				bool, 		chud_comp_colorize_enabled,		k_ps_chud_comp_colorize_enabled)
CBUFFER_END		
		
CBUFFER_BEGIN(CHUDWidgetPS)		
	CBUFFER_CONST(CHUDWidgetPS,			float4,		chud_widget_transform1_ps,		k_ps_chud_widget_transform1)
	CBUFFER_CONST(CHUDWidgetPS,			float4,		chud_widget_transform2_ps,		k_ps_chud_widget_transform2)
	CBUFFER_CONST(CHUDWidgetPS,			float4,		chud_widget_transform3_ps,		k_ps_chud_widget_transform3)
	CBUFFER_CONST(CHUDWidgetPS,			float4,		chud_widget_mirror_ps,			k_ps_chud_widget_mirror)
CBUFFER_END

CBUFFER_BEGIN(CHUDScreenFlashPS)
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash0_color, 		k_ps_chud_screen_flash0_color)
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash0_data, 		k_ps_chud_screen_flash0_data)		
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash1_color, 		k_ps_chud_screen_flash1_color)
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash1_data, 		k_ps_chud_screen_flash1_data)		
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash2_color, 		k_ps_chud_screen_flash2_color)	
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash2_data, 		k_ps_chud_screen_flash2_data)		
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash3_color, 		k_ps_chud_screen_flash3_color)
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash3_data, 		k_ps_chud_screen_flash3_data)
	CBUFFER_CONST(CHUDScreenFlashPS,	float4, 	chud_screen_flash_center, 		k_ps_chud_screen_flash_center)
CBUFFER_END

CBUFFER_BEGIN(CHUDCortanaPS)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_back_colormix_result, 	k_ps_cortana_back_colormix_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_back_hsv_result, 		k_ps_cortana_back_hsv_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_texcam_colormix_result, k_ps_cortana_texcam_colormix_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_solarize_inmix, 	k_ps_cortana_comp_solarize_inmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_solarize_outmix, 	k_ps_cortana_comp_solarize_outmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_solarize_result, 	k_ps_cortana_comp_solarize_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_doubling_inmix, 	k_ps_cortana_comp_doubling_inmix)	
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_doubling_outmix, 	k_ps_cortana_comp_doubling_outmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_doubling_result, 	k_ps_cortana_comp_doubling_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_colorize_inmix, 	k_ps_cortana_comp_colorize_inmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_colorize_outmix, 	k_ps_cortana_comp_colorize_outmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_comp_colorize_result, 	k_ps_cortana_comp_colorize_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_texcam_bloom_inmix, 	k_ps_cortana_texcam_bloom_inmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_texcam_bloom_outmix, 	k_ps_cortana_texcam_bloom_outmix)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_texcam_bloom_result, 	k_ps_cortana_texcam_bloom_result)
	CBUFFER_CONST(CHUDCortanaPS,		float4, 	cortana_vignette_data, 			k_ps_cortana_vignette_data)
CBUFFER_END

#endif

#endif