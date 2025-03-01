#ifndef _SCREENSHOT_DISPLAY_REGISTERS_H_
#define _SCREENSHOT_DISPLAY_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_screenshot_display_swap_color_channels		POSTPROCESS_EXTRA_PIXEL_CONSTANT_2

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\screenshot_display_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif