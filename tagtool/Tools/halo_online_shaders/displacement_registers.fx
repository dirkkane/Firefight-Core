/*
DISPLACEMENT_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
3/21/2007 4:57:42 PM (davcook)
	
*/

#if DX_VERSION == 9

#include "displacement_registers.h"

PIXEL_CONSTANT(float4, screen_constants, k_ps_displacement_screen_constants)
PIXEL_CONSTANT(float4, window_bounds, k_ps_displacement_window_bounds)

PIXEL_CONSTANT(float4x4, current_view_projection, k_ps_displacement_current_view_projection)
PIXEL_CONSTANT(float4x4, previous_view_projection, k_ps_displacement_previous_view_projection)
PIXEL_CONSTANT(float4x4, screen_to_world, k_ps_displacement_screen_to_world)

INT_CONSTANT(num_taps, k_ps_displacement_num_taps)

// .x= num taps
// .y= motion blur time scale adjustment, for really slow or really long frames [unused due to optimization]
// .z= expected DT between frames [unused due to optimization]
// .w= blur center falloff
PIXEL_CONSTANT(float4, misc_values, k_ps_displacement_misc_values)

// .x= max blur X
// .y= max blur Y
// .z= blur scale X * misc_values.y (optimization; premultiplied)
// .w= blur scale Y * misc_values.y (optimization; premultiplied)
PIXEL_CONSTANT(float4, blur_max_and_scale, k_ps_displacement_blur_max_and_scale)

PIXEL_CONSTANT(float4, crosshair_center, k_ps_displacement_crosshair_center)

PIXEL_CONSTANT(float4, zbuffer_xform, k_ps_displacement_zbuffer_xform)

BOOL_CONSTANT(do_distortion, k_ps_displacement_do_distortion)

#elif DX_VERSION == 11

CBUFFER_BEGIN(DisplacementPS)
	CBUFFER_CONST(DisplacementPS,			float4,		screen_constants,			k_ps_displacement_screen_constants)
	CBUFFER_CONST(DisplacementPS,			float4, 	window_bounds, 				k_ps_displacement_window_bounds)
	CBUFFER_CONST(DisplacementPS,			float4x4, 	current_view_projection, 	k_ps_displacement_current_view_projection)
	CBUFFER_CONST(DisplacementPS,			float4x4, 	previous_view_projection, 	k_ps_displacement_previous_view_projection)
	CBUFFER_CONST(DisplacementPS,			float4x4, 	screen_to_world, 			k_ps_displacement_screen_to_world)
CBUFFER_END

CBUFFER_BEGIN(DisplacementMotionBlurPS)
	CBUFFER_CONST(DisplacementMotionBlurPS,	int,		num_taps,					k_ps_displacement_num_taps)
	CBUFFER_CONST(DisplacementMotionBlurPS,	int3,		num_taps_pad,				k_ps_displacement_num_taps_pad)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4, 	misc_values, 				k_ps_displacement_misc_values)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4, 	blur_max_and_scale, 		k_ps_displacement_blur_max_and_scale)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4, 	crosshair_center, 			k_ps_displacement_crosshair_center)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4, 	zbuffer_xform, 				k_ps_displacement_zbuffer_xform)
	CBUFFER_CONST(DisplacementMotionBlurPS,	bool,		do_distortion,				k_ps_displacement_do_distortion)
CBUFFER_END

#endif
