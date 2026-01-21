#ifndef _PARTICLE_UPDATE_REGISTERS_H_
#define _PARTICLE_UPDATE_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#ifndef BOOL_CONSTANT_NAME
#define BOOL_CONSTANT_NAME(n) n
#endif

#define k_vs_particle_update_delta_time CONSTANT_NAME(21)
#define k_vs_particle_update_hidden_from_compiler CONSTANT_NAME(22)	// the compiler will complain if these are literals
#define k_vs_particle_update_tile_to_world CONSTANT_NAME(23)	//= {float3x3(Camera_Forward, Camera_Left, Camera_Up) * tile_size, Camera_Position};
#define k_vs_particle_update_world_to_tile CONSTANT_NAME(26)	//= {transpose(float3x3(Camera_Forward, Camera_Left, Camera_Up) * inverse_tile_size), -Camera_Position};
#define k_vs_particle_update_occlusion_to_world CONSTANT_NAME(29)
#define k_vs_particle_update_world_to_occlusion CONSTANT_NAME(32)	
#define k_vs_particle_update_tiled 20
#define k_vs_particle_update_collision 21

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\particle_update_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif

