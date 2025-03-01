/*
PARTICLE_RENDER_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
12/5/2005 11:50:57 AM (davcook)
	
*/

#if DX_VERSION == 9

#include "particle_render_registers.h"

VERTEX_CONSTANT(float4, hidden_from_compiler, k_vs_particle_render_hidden_from_compiler)	// the compiler will complain if these are literals
VERTEX_CONSTANT(float3x4, local_to_world, k_vs_particle_render_local_to_world)	// local_to_world[0] is a column not a row!

// These corresponding to global externs in the particle render_method_definition
PIXEL_CONSTANT(float3, depth_constants, k_ps_particle_render_depth_constants)

#ifdef VERTEX_SHADER
#ifndef XENON
VERTEX_CONSTANT(float4x3, occlusion_to_world, k_vs_particle_render_occlusion_to_world)
VERTEX_CONSTANT(float4x3, world_to_occlusion, k_vs_particle_render_world_to_occlusion)	
BOOL_CONSTANT(collision, k_vs_particle_render_collision)   
#endif
#endif

#elif DX_VERSION == 11

#include "particle_render_state.fx"

CBUFFER_BEGIN(ParticleRenderVS)
	CBUFFER_CONST(ParticleRenderVS,		float4,					hidden_from_compiler,		k_vs_particle_render_hidden_from_compiler)
	CBUFFER_CONST(ParticleRenderVS,		float3x4,				local_to_world,				k_vs_particle_render_local_to_world)
	CBUFFER_CONST(ParticleRenderVS,		float,					local_to_world_pad,			k_vs_particle_render_local_to_world_pad)
	CBUFFER_CONST(ParticleRenderVS,		s_motion_blur_state,	g_motion_blur_state,		k_vs_particle_render_motion_blur_state)	
	CBUFFER_CONST(ParticleRenderVS,		s_sprite_definition,	g_sprite,					k_vs_particle_render_sprite)
	CBUFFER_CONST(ParticleRenderVS,		s_render_state,			g_render_state,				k_vs_particle_render_state)
	CBUFFER_CONST(ParticleRenderVS,		s_sprite_frame_list,	g_all_sprite_frames,		k_vs_particle_render_sprite_frames)
	CBUFFER_CONST(ParticleRenderVS,		bool,					collision,					k_vs_particle_render_collision)
CBUFFER_END

CBUFFER_BEGIN(ParticleRenderMeshVS)
	CBUFFER_CONST(ParticleRenderMeshVS,	s_mesh_variant_list,	g_all_mesh_variants,		k_vs_particle_render_mesh_variants)
CBUFFER_END

CBUFFER_BEGIN(ParticleRenderPS)
	CBUFFER_CONST(ParticleRenderPS,		float3,		depth_constants,			k_ps_particle_render_depth_constants)
CBUFFER_END

BYTE_ADDRESS_BUFFER(mesh_vertices,	k_vs_mesh_vertices, 17)

#endif
