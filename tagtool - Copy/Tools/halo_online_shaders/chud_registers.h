#ifndef _CHUD_CORTANA_REGISTERS_H_
#define _CHUD_CORTANA_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#ifndef BOOL_CONSTANT_NAME
#define BOOL_CONSTANT_NAME(n) n
#endif

#define k_vs_chud_widget_offset				CONSTANT_NAME(19)
#define k_vs_chud_widget_transform1			CONSTANT_NAME(20)
#define k_vs_chud_widget_transform2			CONSTANT_NAME(21)
#define k_vs_chud_widget_transform3			CONSTANT_NAME(22)
#define k_vs_chud_screen_size				CONSTANT_NAME(23)
#define k_vs_chud_basis_0			 		CONSTANT_NAME(24)
#define k_vs_chud_basis_1			 		CONSTANT_NAME(25)
#define k_vs_chud_basis_2			 		CONSTANT_NAME(26)
#define k_vs_chud_basis_3			 		CONSTANT_NAME(27)
#define k_vs_chud_screen_scale_and_offset 	CONSTANT_NAME(28)
#define k_vs_chud_project_scale_and_offset	CONSTANT_NAME(29)
#define k_vs_chud_widget_mirror				CONSTANT_NAME(30)
#define k_vs_chud_screenshot_info			CONSTANT_NAME(31)
#define k_vs_chud_texture_transform 		CONSTANT_NAME(32)
#define k_vs_chud_cortana_vertex			BOOL_CONSTANT_NAME(7) 

#define k_ps_chud_cortana_pixel				BOOL_CONSTANT_NAME(7)
#define k_ps_chud_color_output_A			CONSTANT_NAME(24)
#define k_ps_chud_color_output_B			CONSTANT_NAME(25)
#define k_ps_chud_color_output_C			CONSTANT_NAME(26)
#define k_ps_chud_color_output_D			CONSTANT_NAME(27)
#define k_ps_chud_color_output_E			CONSTANT_NAME(28)
#define k_ps_chud_color_output_F			CONSTANT_NAME(29)
#define k_ps_chud_scalar_output_ABCD		CONSTANT_NAME(30)
#define k_ps_chud_scalar_output_EF			CONSTANT_NAME(31)
#define k_ps_chud_texture_bounds			CONSTANT_NAME(32)
#define k_ps_chud_savedfilm_chap1			CONSTANT_NAME(33)
#define k_ps_chud_savedfilm_chap2			CONSTANT_NAME(34)
#define k_ps_chud_savedfilm_chap3			CONSTANT_NAME(35)
#define k_ps_chud_savedfilm_data			CONSTANT_NAME(36)

#define k_ps_chud_widget_transform1 		CONSTANT_NAME(50)
#define k_ps_chud_widget_transform2 		CONSTANT_NAME(51)
#define k_ps_chud_widget_transform3 		CONSTANT_NAME(52)
#define k_ps_chud_widget_mirror				CONSTANT_NAME(53)

#define k_ps_chud_screen_flash0_color		CONSTANT_NAME(34)
#define k_ps_chud_screen_flash0_data		CONSTANT_NAME(35)
#define k_ps_chud_screen_flash1_color		CONSTANT_NAME(36)
#define k_ps_chud_screen_flash1_data		CONSTANT_NAME(37)
#define k_ps_chud_screen_flash2_color		CONSTANT_NAME(38)
#define k_ps_chud_screen_flash2_data		CONSTANT_NAME(39)
#define k_ps_chud_screen_flash3_color		CONSTANT_NAME(40)
#define k_ps_chud_screen_flash3_data		CONSTANT_NAME(41)
#define k_ps_chud_screen_flash_center		CONSTANT_NAME(42)

#define k_ps_cortana_back_colormix_result 	CONSTANT_NAME(57)
#define k_ps_cortana_back_hsv_result 		CONSTANT_NAME(58)
#define k_ps_cortana_texcam_colormix_result CONSTANT_NAME(59)
#define k_ps_cortana_comp_solarize_inmix	CONSTANT_NAME(60)
#define k_ps_cortana_comp_solarize_outmix	CONSTANT_NAME(61)
#define k_ps_cortana_comp_solarize_result	CONSTANT_NAME(62)
#define k_ps_cortana_comp_doubling_inmix	CONSTANT_NAME(63)
#define k_ps_cortana_comp_doubling_outmix	CONSTANT_NAME(64)
#define k_ps_cortana_comp_doubling_result	CONSTANT_NAME(65)
#define k_ps_cortana_comp_colorize_inmix	CONSTANT_NAME(66)
#define k_ps_cortana_comp_colorize_outmix	CONSTANT_NAME(67)
#define k_ps_cortana_comp_colorize_result	CONSTANT_NAME(68)
#define k_ps_cortana_texcam_bloom_inmix		CONSTANT_NAME(69)
#define k_ps_cortana_texcam_bloom_outmix	CONSTANT_NAME(70)
#define k_ps_cortana_texcam_bloom_result	CONSTANT_NAME(71)
#define k_ps_cortana_vignette_data			CONSTANT_NAME(72)

#define k_ps_chud_comp_colorize_enabled		BOOL_CONSTANT_NAME(8)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\chud_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif