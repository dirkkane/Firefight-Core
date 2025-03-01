#ifndef _DECORATORS_REGISTERS_H_
#define _DECORATORS_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_decorators_light_count k_register_node_per_vertex_count
#define k_vs_decorators_lights k_register_node_start
#define k_vs_decorators_instance_compression_offset CONSTANT_NAME(240)
#define k_vs_decorators_instance_compression_scale CONSTANT_NAME(241)
#define k_vs_decorators_instance_data CONSTANT_NAME(242)
#define k_vs_decorators_lod_constants CONSTANT_NAME(245)
#define k_vs_decorators_translucency CONSTANT_NAME(246)
#define k_vs_decorators_sun_direction CONSTANT_NAME(247)
#define k_vs_decorators_sun_color CONSTANT_NAME(248)
#define k_ps_decorators_contrast CONSTANT_NAME(13)
#define k_vs_decorators_wave_flow CONSTANT_NAME(249)
#define k_vs_decorators_instance_position_and_scale CONSTANT_NAME(17)
#define k_vs_decorators_instance_quaternion CONSTANT_NAME(18)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\decorators_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FIL

#endif

#endif
