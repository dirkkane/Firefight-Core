#ifndef _SHIELD_METER_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SHIELD_METER_REGISTERS_FX_
#endif

#if DX_VERSION == 9

PIXEL_CONSTANT(float4, flash_color,			POSTPROCESS_EXTRA_PIXEL_CONSTANT_0);
PIXEL_CONSTANT(float4, gradient_min_color,	POSTPROCESS_EXTRA_PIXEL_CONSTANT_1);
PIXEL_CONSTANT(float4, gradient_max_color,	POSTPROCESS_EXTRA_PIXEL_CONSTANT_2);
PIXEL_CONSTANT(float4, misc_parameters,		POSTPROCESS_EXTRA_PIXEL_CONSTANT_3);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShieldMeterPS)
	CBUFFER_CONST(ShieldMeterPS,	float4, 	flash_color,			k_ps_shield_meter_flash_color)
	CBUFFER_CONST(ShieldMeterPS,	float4, 	gradient_min_color,		k_ps_shield_meter_gradient_min_color)
	CBUFFER_CONST(ShieldMeterPS,	float4, 	gradient_max_color,		k_ps_shield_meter_gradient_max_color)
	CBUFFER_CONST(ShieldMeterPS,	float4, 	misc_parameters,		k_ps_shield_meter_misc_parameters)
CBUFFER_END

#endif

#endif
