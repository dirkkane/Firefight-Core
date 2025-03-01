#ifndef _UNKNOWN_101_UNKNOWN_102_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _UNKNOWN_101_UNKNOWN_102_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "unknown_101_unknown_102_registers.h"

VERTEX_CONSTANT(float4, vs_ref_reflections_cam_vec_0, k_vs_ref_reflections_cam_vec_0);
VERTEX_CONSTANT(float4, vs_reg_uv_scale_offset, k_vs_reg_uv_scale_offset);

PIXEL_CONSTANT(float4, ps_reg_blur_dir, k_ps_reg_blur_dir);
PIXEL_CONSTANT(float4, ps_reg_reflections_cam_vec_1, k_ps_reg_reflections_cam_vec_1);
PIXEL_CONSTANT(float4, ps_reg_reflections_params2_0, k_ps_reg_reflections_params2_0);
PIXEL_CONSTANT(float4, ps_reg_reflections_matrview_0, k_ps_reg_reflections_matrview_0);
PIXEL_CONSTANT(float4, ps_reg_reflections_matrview_1, k_ps_reg_reflections_matrview_1);
PIXEL_CONSTANT(float4, ps_reg_reflections_matrview_2, k_ps_reg_reflections_matrview_2);
PIXEL_CONSTANT(float4, ps_reg_reflections_params_0, k_ps_reg_reflections_params_0);

#endif

#endif
