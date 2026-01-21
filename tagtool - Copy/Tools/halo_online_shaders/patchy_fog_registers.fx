/*
PATCHY_FOG_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
4/05/2007 9:15:00 AM (kuttas)
	
*/

#if DX_VERSION == 9

#include "patchy_fog_registers.h"

// ensure that these don't conflict with oneshot/persist registers

// [global patchy fog constants]

PIXEL_CONSTANT(float4, inverse_z_transform, k_ps_patchy_fog_inverse_z_transform)
PIXEL_CONSTANT(float4, texcoord_basis, k_ps_patchy_fog_texcoord_basis)
// x= tallest height at which fog is still full intensity
// y= height attenuation rate above x (0=no attenuation, larger values attenuate sharper)
// z= depth-fade factor (fuzzier intersections as this approaches 0)
// w= distance between sheets
PIXEL_CONSTANT(float4, attenuation_data, k_ps_patchy_fog_attenuation_data)
PIXEL_CONSTANT(float4, eye_position, k_ps_patchy_fog_eye_position)
// {x,y}= normalized [0,1] coordinates of center of window
// {z,w}= normalized [0,1] half-extent of render window
PIXEL_CONSTANT(float4, window_pixel_bounds, k_ps_patchy_fog_window_pixel_bounds)

// [rayleigh/mie/etc scattering constants
PIXEL_CONSTANT(float4, atmosphere_constant_0, k_ps_patchy_fog_atmosphere_constant_0)
PIXEL_CONSTANT(float4, atmosphere_constant_1, k_ps_patchy_fog_atmosphere_constant_1)
PIXEL_CONSTANT(float4, atmosphere_constant_2, k_ps_patchy_fog_atmosphere_constant_2)
PIXEL_CONSTANT(float4, atmosphere_constant_3, k_ps_patchy_fog_atmosphere_constant_3)
PIXEL_CONSTANT(float4, atmosphere_constant_4, k_ps_patchy_fog_atmosphere_constant_4)
PIXEL_CONSTANT(float4, atmosphere_constant_5, k_ps_patchy_fog_atmosphere_constant_5)
PIXEL_CONSTANT(float4, atmosphere_constant_extra, k_ps_patchy_fog_atmosphere_constant_extra)

// [per-sheet patchy fog settings]

// special fading values for first & last sheet pre-multiplied by sheet density
PIXEL_CONSTANT(float4, sheet_fade_factors0, k_ps_patchy_fog_sheet_fade_factors0)
PIXEL_CONSTANT(float4, sheet_fade_factors1, k_ps_patchy_fog_sheet_fade_factors1)
// view-space depths of sheets
PIXEL_CONSTANT(float4, sheet_depths0, k_ps_patchy_fog_sheet_depths0)
PIXEL_CONSTANT(float4, sheet_depths1, k_ps_patchy_fog_sheet_depths1)
// texture coordinate transforms for each sheet
PIXEL_CONSTANT(float4, tex_coord_transform0, k_ps_patchy_fog_tex_coord_transform0)
PIXEL_CONSTANT(float4, tex_coord_transform1, k_ps_patchy_fog_tex_coord_transform1)
PIXEL_CONSTANT(float4, tex_coord_transform2, k_ps_patchy_fog_tex_coord_transform2)
PIXEL_CONSTANT(float4, tex_coord_transform3, k_ps_patchy_fog_tex_coord_transform3)
PIXEL_CONSTANT(float4, tex_coord_transform4, k_ps_patchy_fog_tex_coord_transform4)
PIXEL_CONSTANT(float4, tex_coord_transform5, k_ps_patchy_fog_tex_coord_transform5)
PIXEL_CONSTANT(float4, tex_coord_transform6, k_ps_patchy_fog_tex_coord_transform6)
PIXEL_CONSTANT(float4, tex_coord_transform7, k_ps_patchy_fog_tex_coord_transform7)

#elif DX_VERSION == 11

CBUFFER_BEGIN(PatchyFogPS)
	CBUFFER_CONST(PatchyFogPS,			float4,		inverse_z_transform,		k_ps_patchy_fog_inverse_z_transform)
	CBUFFER_CONST(PatchyFogPS,			float4, 	texcoord_basis, 			k_ps_patchy_fog_texcoord_basis)
	CBUFFER_CONST(PatchyFogPS,			float4, 	attenuation_data, 			k_ps_patchy_fog_attenuation_data)
	CBUFFER_CONST(PatchyFogPS,			float4, 	eye_position, 				k_ps_patchy_fog_eye_position)		
	CBUFFER_CONST(PatchyFogPS,			float4, 	window_pixel_bounds, 		k_ps_patchy_fog_window_pixel_bounds)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_0, 		k_ps_patchy_fog_atmosphere_constant_0)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_1, 		k_ps_patchy_fog_atmosphere_constant_1)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_2, 		k_ps_patchy_fog_atmosphere_constant_2)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_3, 		k_ps_patchy_fog_atmosphere_constant_3)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_4, 		k_ps_patchy_fog_atmosphere_constant_4)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_5, 		k_ps_patchy_fog_atmosphere_constant_5)
	CBUFFER_CONST(PatchyFogPS,			float4, 	atmosphere_constant_extra, 	k_ps_patchy_fog_atmosphere_constant_extra)
CBUFFER_END

CBUFFER_BEGIN(PatchyFogSheetPS)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	sheet_fade_factors0, 		k_ps_patchy_fog_sheet_fade_factors0)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	sheet_fade_factors1, 		k_ps_patchy_fog_sheet_fade_factors1)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	sheet_depths0, 				k_ps_patchy_fog_sheet_depths0)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	sheet_depths1, 				k_ps_patchy_fog_sheet_depths1)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform0, 		k_ps_patchy_fog_tex_coord_transform0)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform1, 		k_ps_patchy_fog_tex_coord_transform1)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform2, 		k_ps_patchy_fog_tex_coord_transform2)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform3, 		k_ps_patchy_fog_tex_coord_transform3)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform4, 		k_ps_patchy_fog_tex_coord_transform4)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform5, 		k_ps_patchy_fog_tex_coord_transform5)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform6, 		k_ps_patchy_fog_tex_coord_transform6)
	CBUFFER_CONST(PatchyFogSheetPS,		float4, 	tex_coord_transform7, 		k_ps_patchy_fog_tex_coord_transform7)
CBUFFER_END

#endif
