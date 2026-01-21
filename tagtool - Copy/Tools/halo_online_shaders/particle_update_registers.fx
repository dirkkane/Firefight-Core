/*
PARTICLE_UPDATE_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
12/5/2005 11:50:57 AM (davcook)
	
*/

#ifdef PC_CPU

float    delta_time;
float4   hidden_from_compiler;
float4x3 tile_to_world;
float4x3 world_to_tile;
float4x3 occlusion_to_world;
float4x3 world_to_occlusion;
BOOL     tiled;
BOOL     collision;
   
#elif DX_VERSION == 9

#include "particle_update_registers.h"

VERTEX_CONSTANT(float, delta_time, k_vs_particle_update_delta_time)
VERTEX_CONSTANT(float4, hidden_from_compiler, k_vs_particle_update_hidden_from_compiler)	// the compiler will complain if these are literals
VERTEX_CONSTANT(float4x3, tile_to_world, k_vs_particle_update_tile_to_world)	//= {float3x3(Camera_Forward, Camera_Left, Camera_Up) * tile_size, Camera_Position};
VERTEX_CONSTANT(float4x3, world_to_tile, k_vs_particle_update_world_to_tile)	//= {transpose(float3x3(Camera_Forward, Camera_Left, Camera_Up) * inverse_tile_size), -Camera_Position};
VERTEX_CONSTANT(float4x3, occlusion_to_world, k_vs_particle_update_occlusion_to_world)
VERTEX_CONSTANT(float4x3, world_to_occlusion, k_vs_particle_update_world_to_occlusion)	
BOOL_CONSTANT(tiled, k_vs_particle_update_tiled)
BOOL_CONSTANT(collision, k_vs_particle_update_collision)   

#elif DX_VERSION == 11

#include "particle_property.fx"
#include "function_definition.fx"
#include "particle_state_list.fx"
#include "particle_update_state.fx"

#define CS_PARTICLE_UPDATE_THREADS 64

CBUFFER_BEGIN(ParticleUpdateVS)
	CBUFFER_CONST(ParticleUpdateVS,			float,					delta_time,						k_vs_particle_update_delta_time)
	CBUFFER_CONST(ParticleUpdateVS,			float3,					delta_time_pad,					k_vs_particle_update_delta_time_pad)
	CBUFFER_CONST(ParticleUpdateVS,			float4,					hidden_from_compiler,			k_vs_particle_update_hidden_from_compiler)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,				tile_to_world,					k_vs_particle_update_tile_to_world)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,				world_to_tile,					k_vs_particle_update_world_to_tile)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,				occlusion_to_world,				k_vs_particle_update_occlusion_to_world)
	CBUFFER_CONST(ParticleUpdateVS,			float4x3,				world_to_occlusion,				k_vs_particle_update_world_to_occlusion)	
	CBUFFER_CONST(ParticleUpdateVS,			s_update_state,			g_update_state,					k_vs_particle_update_state)
	CBUFFER_CONST(ParticleUpdateVS,			bool,					tiled,							k_vs_particle_update_tiled)
	CBUFFER_CONST(ParticleUpdateVS,			bool,					collision,						k_vs_particle_update_collision)
CBUFFER_END	
	
CBUFFER_BEGIN(ParticleEmitter)	
	CBUFFER_CONST_ARRAY(ParticleEmitter,	s_property,				g_all_properties, [_index_max],						k_particle_emitter_all_properties)
	CBUFFER_CONST_ARRAY(ParticleEmitter,	s_function_definition,	g_all_functions, [_maximum_overall_function_count],	k_particle_emitter_all_functions)
	CBUFFER_CONST_ARRAY(ParticleEmitter,	float4,					g_all_colors, [_maximum_overall_color_count],		k_particle_emitter_all_colors)
CBUFFER_END

CBUFFER_BEGIN(ParticleState)
	CBUFFER_CONST(ParticleState,			s_all_state,			g_all_state,					k_particle_state_all_state)
CBUFFER_END

COMPUTE_TEXTURE_AND_SAMPLER(_2D,			sampler_weather_occlusion,		k_cs_sampler_weather_occlusion,			1)

#endif
