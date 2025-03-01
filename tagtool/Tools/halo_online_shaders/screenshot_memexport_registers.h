#ifndef _SCREENSHOT_MEMEXPORT_REGISTERS_H_
#define _SCREENSHOT_MEMEXPORT_REGISTERS_H_

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_screenshot_memexport_vpos_to_pixel_xform		POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_ps_screenshot_memexport_pixel_to_source_xform		POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_screenshot_memexport_export_info				POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define k_ps_screenshot_memexport_export_stream_constant	POSTPROCESS_EXTRA_PIXEL_CONSTANT_2

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\screenshot_memexport_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif