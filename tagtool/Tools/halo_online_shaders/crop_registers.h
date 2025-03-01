#ifndef _CROP_REGISTERS_H
#define _CROP_REGISTERS_H

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define k_ps_crop_texcoord_xform POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define k_ps_crop_bounds POSTPROCESS_EXTRA_PIXEL_CONSTANT_1

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\crop_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
