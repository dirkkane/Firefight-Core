#ifndef _PARTICLE_RENDER_REGISTERS_H_
#define _PARTICLE_RENDER_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_vs_particle_render_hidden_from_compiler CONSTANT_NAME(32)
#define k_vs_particle_render_local_to_world CONSTANT_NAME(33)
#define k_ps_particle_render_depth_constants CONSTANT_NAME(201)
#define k_vs_particle_render_occlusion_to_world CONSTANT_NAME(37)
#define k_vs_particle_render_world_to_occlusion CONSTANT_NAME(40)	
#define k_vs_particle_render_collision 15

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\particle_render_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
