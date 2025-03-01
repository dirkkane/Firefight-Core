#ifndef __POSTPROCESS_REGISTERS_H
#define __POSTPROCESS_REGISTERS_H

// declares layout of GPU constants for postprocess effects

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

// the pixel size (in texcoords) of the render target is passed to every postprocess function.
#define POSTPROCESS_PIXELSIZE_PIXEL_CONSTANT	CONSTANT_NAME(1)

// the default pixel constant is passed to every postprocess function.  It is also defined as 'scale' below
#define POSTPROCESS_DEFAULT_PIXEL_CONSTANT		CONSTANT_NAME(2)

// extra pixel constants you must set explicitly before calling postprocess functions
#define POSTPROCESS_EXTRA_PIXEL_CONSTANT_0		CONSTANT_NAME(3)
#define POSTPROCESS_EXTRA_PIXEL_CONSTANT_1		CONSTANT_NAME(4)
#define POSTPROCESS_EXTRA_PIXEL_CONSTANT_2		CONSTANT_NAME(5)
#define POSTPROCESS_EXTRA_PIXEL_CONSTANT_3		CONSTANT_NAME(6)
#define POSTPROCESS_EXTRA_PIXEL_CONSTANT_4		CONSTANT_NAME(7)
#define POSTPROCESS_EXTRA_PIXEL_CONSTANT_5		CONSTANT_NAME(8)

#if DX_VERSION == 9

#define k_postprocess_pixel_size				POSTPROCESS_PIXELSIZE_PIXEL_CONSTANT
#define k_postprocess_scale						POSTPROCESS_DEFAULT_PIXEL_CONSTANT
#define k_postprocess_hue_saturation_matrix		CONSTANT_NAME(218)
#define k_postprocess_contrast					CONSTANT_NAME(222)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\postprocess_registers.fx"
#include "rasterizer\\dx11\\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif // __POSTPROCESS_REGISTERS_H