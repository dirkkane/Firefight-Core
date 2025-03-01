/*
PARTICLE_UPDATE.HLSL
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/11/2005 11:38:58 AM (davcook)

Shaders for particle physics, state updates
*/

#if DX_VERSION == 11
// @compute_shader
#endif

#define PARTICLE_WRITE 1

#include "global.fx"

#if ((DX_VERSION == 9) && defined(VERTEX_SHADER)) || ((DX_VERSION == 11) && defined(COMPUTE_SHADER)) || defined(PC_CPU)

#include "hlsl_vertex_types.fx"
#include "particle_update_registers.fx"	// must come before particle_common.fx
#if DX_VERSION == 11
#include "particle_state_buffer.fx"
#include "particle_index_registers.fx"
#endif
#include "particle_state.fx"
#include "particle_common.fx"
#include "particle_update_state.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_particle_vertex

typedef s_particle_vertex s_particle_in;
typedef void s_particle_out;

//#ifndef pc
#if DX_VERSION == 9
PARAM_STRUCT(s_update_state, g_update_state);
#endif

// Assumes position is above the tile in world space.
#ifndef PC_CPU
   void clamp_to_tile(inout float3 position)
#else
   void clamp_to_tile(float3& position)
#endif
{
#ifdef CLAMP_IN_WORLD_Z_DIRECTION	// This leads to particle clumping
	float3 tile_pos= frac(mul(float4(position, 1.0f), world_to_tile));
	float3 tile_z= mul(float4(0.0f, 0.0f, 1.0f, 0.0f), world_to_tile);
	
	// Clamp down to the three positive planes.  Should have no effect on things already below.
	float3 lift_to_pos_planes= (1.0f - tile_pos)/tile_z;
	float min_lift= min(lift_to_pos_planes.x, lift_to_pos_planes.z);	// only need y if there's roll; otherwise this is divide-by-zero
	tile_pos+= tile_z * min_lift;
	
	position= mul(float4(tile_pos, 1.0f), tile_to_world);
#else	//if CLAMP_IN_TILE_Z_DIRECTION
	position= mul(float4(frac(mul(float4(position, 1.0f), world_to_tile)).xy, 1.0f, 1.0f), tile_to_world);
#endif
}
#ifndef PC_CPU
   void wrap_to_tile(inout float3 position)
#else
   void wrap_to_tile(float3& position)
#endif
{
	// This code compiles to 9 ALU instructions
	position= mul(float4(frac(mul(float4(position, 1.0f), world_to_tile)), 1.0f), tile_to_world);
}

// Used to recycle particles to near the camera
#ifndef PC_CPU
   void update_particle_state_tiling(inout s_particle_state STATE)
#else
   void update_particle_state_tiling(s_particle_state& STATE)
#endif
{
	if (tiled)
	{
		wrap_to_tile(STATE.m_position);
	}
}

#define HIDE_OCCLUDED_PARTICLES

#ifndef PC_CPU
   void update_particle_state_collision(inout s_particle_state STATE)
#else
   void update_particle_state_collision(s_particle_state& STATE)
#endif
{
	// This code compiles to 2 sequencer blocks and 9 ALU instructions.  We can get to 7 ALU by putting the 1.0f and 2.0f below into
	// the matrix
	if (collision)
	{
		float3 weather_space_pos= mul(float4(STATE.m_position, 1.0f), world_to_occlusion);
		
#ifndef PC_CPU
		float occlusion_z= sample2Dlod(sampler_weather_occlusion, weather_space_pos.xy, 0).x;
#else
		//assert(false);
		float occlusion_z= 0;//tex2Dlod(sampler_weather_occlusion, float4(weather_space_pos.xy, 0, 0)).x;
#endif
		
		if (occlusion_z< weather_space_pos.z)
		{
			// particle is occluded by geometry...
#if defined(TINT_OCCLUDED_PARTICLES)
			STATE.m_color= float4(1.0f, 0.0f, 0.0f, 1.0f);	// Make particle easily visible for debugging
#elif defined(KILL_OCCLUDED_PARTICLES)
			STATE.m_age= 1.0f;	// Kill particle
#elif defined(HIDE_OCCLUDED_PARTICLES)
			STATE.m_color.w= 0.0f;	// These get killed in the render, but are allowed to continue in the update until they tile
#else	//if defined(ATTACH_OCCLUDED_PARTICLES)
			weather_space_pos.z= occlusion_z;
			STATE.m_position= mul(float4(weather_space_pos, 1.0f), occlusion_to_world).xyz;
			STATE.m_velocity= float3(0.0f, 0.0f, -0.001f);
			if (!STATE.m_collided)
			{
				STATE.m_age= 0.0f;
				STATE.m_collided= true;
			}
#endif
		}
	}
}

#ifndef PC_CPU
   void update_particle_looping(inout s_particle_state STATE)
#else
   void update_particle_looping(s_particle_state& STATE)
#endif
{
#if defined(ATTACH_OCCLUDED_PARTICLES)
	if (looping)
	{
		if (STATE.m_age>= 1.0f)
		{
			STATE.m_age= frac(STATE.m_age);
			if (STATE.m_collided)
			{
				clamp_to_tile(STATE.m_position);
				STATE.m_collided= false;
			}
		}
	}
#endif
}

#ifndef PC_CPU
   void update_particle_state(inout s_particle_state STATE)
#else
   void update_particle_state(s_particle_state& STATE)
#endif
{
	// This is a hack to allow one frame of no updating after spawn.
	float dt= (STATE.m_size>= 0.0f) ? delta_time : 0.0f;

	// Update particle life
	STATE.m_age+= STATE.m_inverse_lifespan * dt;

   #ifndef PC_CPU
	   float pre_evaluated_scalar[_index_max]= preevaluate_particle_functions(STATE);
   #else
      float pre_evaluated_scalar[_index_max];
      preevaluate_particle_functions(STATE, pre_evaluated_scalar);
   #endif

	if (STATE.m_age< 1.0f)
	{
		// Update particle pos
		//STATE.m_position.xyz+= STATE.m_velocity.xyz * dt;
		STATE.m_position += STATE.m_velocity * dt;

		// Update velocity (saturate is so friction can't cause reverse of direction)
		STATE.m_velocity+= particle_map_to_vector3d_range(_index_particle_self_acceleration, pre_evaluated_scalar[_index_particle_self_acceleration])
			* dt;
		STATE.m_velocity.z-= g_update_state.m_gravity * dt;
		//STATE.m_velocity.xyz-= saturate(g_update_state.m_air_friction * dt) * STATE.m_velocity.xyz;
		STATE.m_velocity -= saturate(g_update_state.m_air_friction * dt) * STATE.m_velocity;
		
		// Update rotational velocity (saturate is so friction can't cause reverse of direction)
		STATE.m_rotational_velocity-= saturate(g_update_state.m_rotational_friction * dt) * STATE.m_rotational_velocity;
		
		// Update rotation (only stored as [0,1], and "frac" is necessary to avoid clamping)
		STATE.m_physical_rotation= 
			frac(STATE.m_physical_rotation + STATE.m_rotational_velocity * dt);
		STATE.m_manual_rotation= frac(pre_evaluated_scalar[_index_particle_rotation]);
		
		// Update frame animation (only stored as [0,1], and "frac" is necessary to avoid clamping)
		STATE.m_animated_frame= frac(STATE.m_animated_frame + STATE.m_frame_velocity * dt);
		STATE.m_manual_frame= frac(pre_evaluated_scalar[_index_particle_frame]);
		
		// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
		STATE.m_color.xyz= particle_map_to_color_range(_index_emitter_tint, pre_evaluated_scalar[_index_emitter_tint])
			* particle_map_to_color_range(_index_particle_color, pre_evaluated_scalar[_index_particle_color]);
		STATE.m_color.w= pre_evaluated_scalar[_index_emitter_alpha] 
			* pre_evaluated_scalar[_index_particle_alpha];
			
		// Update other particle state
		STATE.m_size= pre_evaluated_scalar[_index_emitter_size] * pre_evaluated_scalar[_index_particle_scale];
		STATE.m_aspect= pre_evaluated_scalar[_index_particle_aspect];
		STATE.m_intensity= pre_evaluated_scalar[_index_particle_intensity];
		STATE.m_black_point= saturate(pre_evaluated_scalar[_index_particle_black_point])*_1_minus_epsilon; // avoid wrap
		STATE.m_palette_v= saturate(pre_evaluated_scalar[_index_particle_palette])*_1_minus_epsilon;// avoid wrap
	}
	else
	{
		// Particle death, kill pixel
		// Can't do this for EDRAM, since anything we write gets resolved back
		// For MemExport, should skip the writeback in this case.
	}
}

s_particle_out particle_main( s_particle_in INv )
{
	s_particle_state STATE;
#if !defined(PC_CPU)
	s_particle_out OUT;
#endif

	STATE= read_particle_state(INv.index);

	update_particle_state(STATE);
	update_particle_state_tiling(STATE);
#if !defined(PC_CPU)
	update_particle_state_collision(STATE);
#endif
	update_particle_looping(STATE);

	//return 
	write_particle_state(STATE, INv.index);
}
//#endif	// #ifndef pc

// For EDRAM method, the main work must go in the pixel shader, since only 
// pixel shaders can write to EDRAM.
// For the MemExport method, we don't need a pixel shader at all.
// This is signalled by a "void" return type or "multipass" config?

#if defined(pc) && (DX_VERSION == 9)
float4 default_vs( vertex_type IN ) :SV_Position
{
	return float4(1, 2, 3, 4);
}
#elif DX_VERSION == 11
[numthreads(CS_PARTICLE_UPDATE_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		s_particle_in input;
		input.index = index;
		particle_main(input);
	}
}
#else
void default_vs( vertex_type INv )
{
//	asm {
//		config VsExportMode=multipass   // export only shader
//	};
	particle_main(INv);
}
#endif

#else	//#if defined(VERTEX_SHADER) || defined(PC_CPU)
#if DX_VERSION == 9
// Should never be executed
float4 default_ps( SCREEN_POSITION_INPUT(screen_position) ) :SV_Target0
{
	return float4(0,1,2,3);
}
#endif
#endif
