#ifndef _SCREENSHOT_DISPLAY_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SCREENSHOT_DISPLAY_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "screenshot_display_registers.h"

PIXEL_CONSTANT( float4, swap_color_channels,	k_ps_screenshot_display_swap_color_channels);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenshotDisplayPS)
	CBUFFER_CONST(ScreenshotDisplayPS,		float4, 	swap_color_channels,	k_ps_screenshot_display_swap_color_channels)
CBUFFER_END

#endif

#endif