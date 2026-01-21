#ifndef _DISPLACEMENT_REGISTERS_H_
#define _DISPLACEMENT_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_displacement_screen_constants CONSTANT_NAME(203)
#define k_ps_displacement_window_bounds CONSTANT_NAME(204)
#define k_ps_displacement_current_view_projection CONSTANT_NAME(160)
#define k_ps_displacement_previous_view_projection CONSTANT_NAME(164)
#define k_ps_displacement_screen_to_world CONSTANT_NAME(168)
#define k_ps_displacement_num_taps 2
#define k_ps_displacement_misc_values CONSTANT_NAME(172)
#define k_ps_displacement_blur_max_and_scale CONSTANT_NAME(173)
#define k_ps_displacement_crosshair_center CONSTANT_NAME(174)
#define k_ps_displacement_zbuffer_xform CONSTANT_NAME(175)
#define k_ps_displacement_do_distortion 2

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\displacement_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif