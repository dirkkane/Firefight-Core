#ifndef _PATCHY_FOG_REGISTERS_H_
#define _PATCHY_FOG_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_patchy_fog_inverse_z_transform			CONSTANT_NAME(32)
#define k_ps_patchy_fog_texcoord_basis				CONSTANT_NAME(33)
#define k_ps_patchy_fog_attenuation_data			CONSTANT_NAME(34)
#define k_ps_patchy_fog_eye_position				CONSTANT_NAME(35)
#define k_ps_patchy_fog_window_pixel_bounds			CONSTANT_NAME(36)
#define k_ps_patchy_fog_atmosphere_constant_0		CONSTANT_NAME(215)
#define k_ps_patchy_fog_atmosphere_constant_1		CONSTANT_NAME(216)
#define k_ps_patchy_fog_atmosphere_constant_2		CONSTANT_NAME(217)
#define k_ps_patchy_fog_atmosphere_constant_3		CONSTANT_NAME(218)
#define k_ps_patchy_fog_atmosphere_constant_4		CONSTANT_NAME(219)
#define k_ps_patchy_fog_atmosphere_constant_5		CONSTANT_NAME(220)
#define k_ps_patchy_fog_atmosphere_constant_extra	CONSTANT_NAME(221)
#define k_ps_patchy_fog_sheet_fade_factors0			CONSTANT_NAME(40)
#define k_ps_patchy_fog_sheet_fade_factors1			CONSTANT_NAME(41)
#define k_ps_patchy_fog_sheet_depths0				CONSTANT_NAME(42)
#define k_ps_patchy_fog_sheet_depths1				CONSTANT_NAME(43)
#define k_ps_patchy_fog_tex_coord_transform0		CONSTANT_NAME(44)
#define k_ps_patchy_fog_tex_coord_transform1		CONSTANT_NAME(45)
#define k_ps_patchy_fog_tex_coord_transform2		CONSTANT_NAME(46)
#define k_ps_patchy_fog_tex_coord_transform3		CONSTANT_NAME(47)
#define k_ps_patchy_fog_tex_coord_transform4		CONSTANT_NAME(48)
#define k_ps_patchy_fog_tex_coord_transform5		CONSTANT_NAME(49)
#define k_ps_patchy_fog_tex_coord_transform6		CONSTANT_NAME(50)
#define k_ps_patchy_fog_tex_coord_transform7		CONSTANT_NAME(51)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\patchy_fog_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif