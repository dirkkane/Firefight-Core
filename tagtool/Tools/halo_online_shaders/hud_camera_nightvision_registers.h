#ifndef _HUD_CAMERA_NIGHTVISION_REGISTERS_H_
#define _HUD_CAMERA_NIGHTVISION_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_hud_camera_nightvision_falloff                         CONSTANT_NAME(94)
#define k_ps_hud_camera_nightvision_screen_to_world                 CONSTANT_NAME(95)
#define k_ps_hud_camera_nightvision_ping                            CONSTANT_NAME(99)
#define k_ps_hud_camera_nightvision_colors                          CONSTANT_NAME(100)
#define k_ps_hud_camera_nightvision_overlapping_dimming_factor      CONSTANT_NAME(114)
#define k_ps_hud_camera_nightvision_falloff_throught_the_wall       CONSTANT_NAME(120)
#define k_ps_hud_camera_nightvision_zbuf_params                     CONSTANT_NAME(121)
#define k_ps_hud_camera_nightvision_float_index                     CONSTANT_NAME(122)
#define k_ps_hud_camera_nightvision_screenspace_xform               CONSTANT_NAME(251)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\hud_camera_nightvision_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
