#ifndef _SCREENSHOT_MEMEXPORT_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SCREENSHOT_MEMEXPORT_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "screenshot_memexport_registers.h"

PIXEL_CONSTANT( float4, vpos_to_pixel_xform,		k_ps_screenshot_memexport_vpos_to_pixel_xform);
PIXEL_CONSTANT( float4, pixel_to_source_xform,		k_ps_screenshot_memexport_pixel_to_source_xform);
PIXEL_CONSTANT( float4, export_info,				k_ps_screenshot_memexport_export_info);		// row stride in pixels, maximum pixel index, screenshot gamma
PIXEL_CONSTANT( float4, export_stream_constant,		k_ps_screenshot_memexport_export_stream_constant);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenshotMemExportPS)
	CBUFFER_CONST(ScreenshotMemExportPS,		float4, 	vpos_to_pixel_xform,		k_ps_screenshot_memexport_vpos_to_pixel_xform)
	CBUFFER_CONST(ScreenshotMemExportPS,		float4, 	pixel_to_source_xform,		k_ps_screenshot_memexport_pixel_to_source_xform)
	CBUFFER_CONST(ScreenshotMemExportPS,		float4, 	export_info,				k_ps_screenshot_memexport_export_info)
CBUFFER_END

#endif

#endif