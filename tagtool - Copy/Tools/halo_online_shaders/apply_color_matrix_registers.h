#ifndef _APPLY_COLOR_MATRIX_REGISTERS_H_
#ifndef DEFINE_CPP_CONSTANTS
#define _APPLY_COLOR_MATRIX_REGISTERS_H_
#endif

#if DX_VERSION == 9

#include "postprocess_registers.h"

#define	k_ps_apply_color_matrix_dest_red  POSTPROCESS_EXTRA_PIXEL_CONSTANT_0
#define	k_ps_apply_color_matrix_dest_green POSTPROCESS_EXTRA_PIXEL_CONSTANT_1
#define	k_ps_apply_color_matrix_dest_blue POSTPROCESS_EXTRA_PIXEL_CONSTANT_2
#define	k_ps_apply_color_matrix_dest_alpha POSTPROCESS_EXTRA_PIXEL_CONSTANT_3

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\apply_color_matrix_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
