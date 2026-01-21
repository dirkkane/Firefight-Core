#ifndef _WATER_REGISTERS_H_
#define _WATER_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_water_memexport_addr CONSTANT_NAME(130)
#define k_vs_water_index_offset CONSTANT_NAME(131)

//#define k_ps_water_view_depth_constant CONSTANT_NAME(217)

#define k_ps_water_is_lightmap_exist 0
#define k_ps_water_is_interaction 1
#define k_ps_water_is_tessellated 2
#define k_ps_water_is_camera_underwater 3

#define k_ps_water_tex_ripple_buffer_slope_height 1

#define k_vs_water_tess_camera_position CONSTANT_NAME(132)
#define k_vs_water_tess_camera_forward CONSTANT_NAME(133)
#define k_vs_water_tess_camera_diagonal CONSTANT_NAME(134)

#define k_vs_water_ripple_memexport_addr CONSTANT_NAME(130)
#define k_vs_water_camera_position CONSTANT_NAME(131)
#define k_vs_water_ripple_pattern_count CONSTANT_NAME(132)
#define k_vs_water_ripple_real_frametime_ratio CONSTANT_NAME(133)
#define k_vs_water_ripple_particle_index_start CONSTANT_NAME(138)
#define k_vs_water_maximum_ripple_particle_number CONSTANT_NAME(139)

#define k_vs_water_is_under_screenshot 104

#define k_ps_water_tex_ripple_pattern 0
#define k_ps_water_tex_ripple_buffer_height 1

#define k_ps_water_tex_ldr_buffer 0
#define k_ps_water_tex_depth_buffer 1

#define k_vs_water_ripple_buffer_radius CONSTANT_NAME(133)
#define k_vs_water_ripple_buffer_center CONSTANT_NAME(134)
#define k_vs_water_hidden_from_compiler CONSTANT_NAME(135)

//#define k_ps_water_view_xform_inverse CONSTANT_NAME(213)
//#define k_ps_water_player_view_constant CONSTANT_NAME(218)
//#define k_ps_water_camera_position CONSTANT_NAME(219)
//#define k_ps_water_underwater_murkiness CONSTANT_NAME(220)
//#define k_ps_water_underwater_fog_color CONSTANT_NAME(221)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\water_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif