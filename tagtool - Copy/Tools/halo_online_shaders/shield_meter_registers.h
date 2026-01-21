#ifndef _SHIELD_METER_REGISTERS_H_
#define _SHIELD_METER_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_shield_meter_flash_color			POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_shield_meter_gradient_min_color	POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define k_ps_shield_meter_gradient_max_color	POSTPROCESS_EXTRA_PIXEL_CONSTANT_2
#define k_ps_shield_meter_misc_parameters		POSTPROCESS_EXTRA_PIXEL_CONSTANT_3

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\shield_meter_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
