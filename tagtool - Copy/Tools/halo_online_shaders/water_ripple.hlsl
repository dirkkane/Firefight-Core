/*
WATER_RIPPLE.HLSL
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
04/12/2006 13:36 davcook	
*/

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

//This comment causes the shader compiler to be invoked for certain vertex types and entry points
//@generate s_ripple_vertex
//@entry default
//@entry albedo
//@entry dynamic_light
//@entry shadow_apply
//@entry active_camo
//@entry lightmap_debug_mode

#if DX_VERSION == 11
//@compute_shader
#endif

#include "global.fx"
#include "hlsl_constant_persist.fx"
#include "blend.fx"
#include "water_registers.fx"
#include "ripple.fx"

#ifndef PC_CPU
	#define LDR_ALPHA_ADJUST g_exposure.w
	#define HDR_ALPHA_ADJUST g_exposure.b
	#define DARK_COLOR_MULTIPLIER g_exposure.g
	#include "render_target.fx"


	// rename entry point of water passes 
	#define ripple_add_vs			active_camo_vs	
	#define ripple_add_ps			active_camo_ps	
	#define ripple_update_vs		default_vs
	#define ripple_update_ps		default_ps
#if DX_VERSION == 11
	#define ripple_update_cs		default_cs
#endif   
	#define ripple_apply_vs		albedo_vs
	#define ripple_apply_ps		albedo_ps
	#define ripple_slope_vs		dynamic_light_vs
	#define ripple_slope_ps		dynamic_light_ps
	#define underwater_vs			shadow_apply_vs
	#define underwater_ps			shadow_apply_ps
	#define underwater_new_vs       lightmap_debug_mode_vs
	#define underwater_new_ps       lightmap_debug_mode_ps
#endif

//#ifndef pc /* implementation of xenon version */

#ifdef pc
#define INDEX  BLENDINDICES  // quick fix, change later [25/01/2013 paul.smirnov]
#endif

//	ignore the vertex_type, input vertex type defined locally
struct s_ripple_vertex_input
{
#ifdef PC_CPU
   int index;
#else
	#if (DX_VERSION == 9) && defined(pc)
		float4 position_flow: POSITION0;
		float4 life_height	: TEXCOORD0;
		float4 shock_size	: TEXCOORD1;
		float4 pendulum		: TEXCOORD2;
		float4 pattern		: TEXCOORD3;
		float4 foam			: TEXCOORD4;
		float4 flags		: COLOR0;
		float4 funcs		: COLOR1;
	
		float2 index		: TEXCOORD5;
	#elif DX_VERSION == 11
		uint index : SV_VertexID;
	#else
		int index : SV_VertexID;
	#endif
#endif
};

// The following defines the protocol for passing interpolated data between vertex/pixel shaders
struct s_ripple_interpolators
{
#ifdef PC_CPU
	float4 position;
	float4 texcoord;
	float4 pendulum;
	float4 foam;
#else
	float4 position			:SV_Position;
	float4 texcoord			:TEXCOORD0;
	float4 pendulum			:TEXCOORD1;
	float4 foam				:TEXCOORD2;
#endif
};

struct s_underwater_interpolators
{
#ifdef PC_CPU
	float4 position;
	float4 position_ss;
#else
	float4 position			:SV_Position;
	float4 position_ss		:TEXCOORD0;
#endif
};

// magic number concentration camp, finally will be executed.
static const float k_ripple_time_per_frame= 0.03f;
static const int ripple_vertex_stream_block_num= 8; // number of float4 blocks inside structure

// grabbed from function.fx
#define _transition_function_linear		0
#define _transition_function_early		1 // x^0.5
#define _transition_function_very_early	2 // x^0.25
#define _transition_function_late		3 // x^2.0
#define _transition_function_very_late	4 // x^4.0
#define _transition_function_cosine		5 // accelerates in and out
#define _transition_function_one		6
#define _transition_function_zero		7
#define _transition_function_max		8

#define _2pi 6.28318530718f

#ifdef VERTEX_SHADER
// grabbed from function.fx
float evaluate_transition_internal(int transition_type, float input)
{
	float output;							
	if (transition_type==_transition_function_linear)
	{
		output= input;
	}
	else if (transition_type==_transition_function_early)
	{
		output= sqrt(input);
	}
	else if (transition_type==_transition_function_very_early)
	{
		output= sqrt(sqrt(input));
	}
	else if (transition_type==_transition_function_late)
	{
		output= input * input;
	}
	else if (transition_type==_transition_function_very_late)
	{
		output= input * input * input * input;
	}
	else if (transition_type==_transition_function_cosine)
	{
		output= cos(_2pi*(input+1));
	}
	else if (transition_type==_transition_function_one)
	{
		output= 1;
	}
	else //if (transition_type==_transition_function_zero)
	{
		output= 0;
	}
	return output;
}
#endif

#if ((DX_VERSION == 9) && defined(VERTEX_SHADER)) || ((DX_VERSION == 11) && defined(COMPUTE_SHADER))

#if DX_VERSION == 9
// fetch a ripple particle
s_ripple fetch_ripple(int index)
{
	float4 position_flow;
	float4 life_height;
	float4 shock_size;
	float4 pendulum;
	float4 pattern;
	float4 foam;
	float4 flags;
	float4 funcs;
	
#ifdef PC_CPU
	byte* p = (byte*)g_cur_vertex_input_data;
   position_flow  = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
   life_height    = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	shock_size     = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	pendulum       = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	pattern        = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	foam           = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	flags          = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d
	funcs          = s_gpu_storage_4x32f::unpack(  *(real_vector4d*)p );   p += sizeof(real_vector4d);   // real_vector4d

#elif pc
	position_flow = float4(0,0,0,0);
	position_flow = float4(0,0,0,0);
	life_height = float4(0,0,0,0);
	shock_size = float4(0,0,0,0);
	pendulum = float4(0,0,0,0);
	pattern = float4(0,0,0,0);
	foam = float4(0,0,0,0);
	flags = float4(0,0,0,0);
	funcs = float4(0,0,0,0);
#else
	asm {
		vfetch position_flow,	index,	position0
		vfetch life_height,		index,	texcoord0
		vfetch shock_size,		index,	texcoord1
		vfetch pendulum,		index,	texcoord2
		vfetch pattern,			index,	texcoord3
		vfetch foam,			index,	texcoord4
		vfetch flags,			index,	color0
		vfetch funcs,			index,	color1
	};
#endif

	s_ripple _OUT;
	_OUT.position= position_flow.xy;
	_OUT.flow= position_flow.zw;

	_OUT.life= life_height.x;
	_OUT.duration= life_height.y;
	_OUT.rise_period= life_height.z;
	_OUT.height= life_height.w;

	_OUT.shock= shock_size.xy;
	_OUT.size= shock_size.z;
	_OUT.spread= shock_size.w;

	_OUT.pendulum_phase= pendulum.x;
	_OUT.pendulum_revolution= pendulum.y;
	_OUT.pendulum_repeat= pendulum.z;

	_OUT.pattern_start_index= pattern.x;
	_OUT.pattern_end_index= pattern.y;

	_OUT.foam_out_radius= foam.x;
	_OUT.foam_fade_distance= foam.y;
	_OUT.foam_life= foam.z;
	_OUT.foam_duration= foam.w;

#ifdef PC_CPU
	_OUT.flag_drift= (flags.x != 0.0f);
	_OUT.flag_pendulum= (flags.y != 0.0f);
	_OUT.flag_foam= (flags.z != 0.0f);
	_OUT.flag_foam_game_unit= (flags.w != 0.0f);
#else
	_OUT.flag_drift= flags.x;
	_OUT.flag_pendulum= flags.y;
	_OUT.flag_foam= flags.z;	
	_OUT.flag_foam_game_unit= flags.w;
#endif

	_OUT.func_rise= funcs.x;
	_OUT.func_descend= funcs.y;
	_OUT.func_pattern= funcs.z;
	_OUT.func_foam= funcs.w;

	return _OUT;
}


#if (!defined(PC_CPU) && defined(pc))
s_ripple fetch_ripple_from_input(s_ripple_vertex_input vIN)
{
	float4 position_flow = vIN.position_flow;
	float4 life_height	 = vIN.life_height;
	float4 shock_size	 = vIN.shock_size;
	float4 pendulum		 = vIN.pendulum;
	float4 pattern		 = vIN.pattern;
	float4 foam			 = vIN.foam;
	float4 flags		 = vIN.flags;
	float4 funcs		 = vIN.funcs;

	s_ripple _OUT;
	_OUT.position= position_flow.xy;
	_OUT.flow= position_flow.zw;

	_OUT.life= life_height.x;
	_OUT.duration= life_height.y;
	_OUT.rise_period= life_height.z;
	_OUT.height= life_height.w;

	_OUT.shock= shock_size.xy;
	_OUT.size= shock_size.z;
	_OUT.spread= shock_size.w;

	_OUT.pendulum_phase= pendulum.x;
	_OUT.pendulum_revolution= pendulum.y;
	_OUT.pendulum_repeat= pendulum.z;

	_OUT.pattern_start_index= pattern.x;
	_OUT.pattern_end_index= pattern.y;

	_OUT.foam_out_radius= foam.x;
	_OUT.foam_fade_distance= foam.y;
	_OUT.foam_life= foam.z;
	_OUT.foam_duration= foam.w;

	_OUT.flag_drift= flags.x;
	_OUT.flag_pendulum= flags.y;
	_OUT.flag_foam= flags.z;	
	_OUT.flag_foam_game_unit= flags.w;

	_OUT.func_rise= funcs.x;
	_OUT.func_descend= funcs.y;
	_OUT.func_pattern= funcs.z;
	_OUT.func_foam= funcs.w;
	
	return _OUT;
}
#endif // (!defined(PC_CPU) && defined(pc))



#ifdef pc
   float4 ripple_add_vs(s_ripple_vertex_input _IN) : SV_Position
#else
   void ripple_add_vs(s_ripple_vertex_input _IN)
#endif
{
#ifdef PC_CPU
	const float4 k_offset_const(0, 1, 0, 0);
#else
   const float4 k_offset_const= { 0, 1, 0, 0 };
#endif
	int index= _IN.index;

	s_ripple ripple= fetch_ripple(index);

	// pack data
	float4 position_flow= float4(ripple.position, ripple.flow);
	float4 life_height= float4(ripple.life, ripple.duration, ripple.rise_period, ripple.height);
	float4 shock_spread= float4(ripple.shock, ripple.size, ripple.spread);
	float4 pendulum= float4(ripple.pendulum_phase, ripple.pendulum_revolution, ripple.pendulum_repeat, 0.0f);
	float4 pattern= float4(ripple.pattern_start_index, ripple.pattern_end_index, 0.0f, 0.0f);
	float4 foam= float4(ripple.foam_out_radius, ripple.foam_fade_distance, ripple.foam_life, ripple.foam_duration);
	float4 flags= float4(ripple.flag_drift, ripple.flag_pendulum, ripple.flag_foam, ripple.flag_foam_game_unit);
	float4 funcs= float4(ripple.func_rise, ripple.func_descend, ripple.func_pattern, ripple.func_foam);

	int dst_index= index + k_vs_ripple_particle_index_start;
	if ( dst_index >= k_vs_maximum_ripple_particle_number )
	{
		dst_index -= k_vs_maximum_ripple_particle_number;
	}

	// export to stream	
	int out_index_0= dst_index * ripple_vertex_stream_block_num;
	int out_index_1= out_index_0 + 1;
	int out_index_2= out_index_0 + 2;
	int out_index_3= out_index_0 + 3;
	int out_index_4= out_index_0 + 4;
	int out_index_5= out_index_0 + 5;		
	int out_index_6= out_index_0 + 6;		
	int out_index_7= out_index_0 + 7;		

	// only update, when ripple is alive
#ifdef PC_CPU
	out_index_0;
	out_index_1;
	out_index_2;
	out_index_3;
	out_index_4;
	out_index_5;
	out_index_6;
	out_index_7;

	byte* p = (byte*)g_cur_vertex_output_data;

	*(float4*)p = position_flow; p += sizeof(float4);
	*(float4*)p = life_height; p += sizeof(float4);
	*(float4*)p = shock_spread; p += sizeof(float4);
	*(float4*)p = pendulum; p += sizeof(float4);
	*(float4*)p = pattern; p += sizeof(float4);
	*(float4*)p = foam; p += sizeof(float4);
	*(float4*)p = flags; p += sizeof(float4);
	*(float4*)p = funcs; p += sizeof(float4);

#elif pc
#else
	asm
	{
		alloc export= 1
		mad eA, out_index_0, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, position_flow

		alloc export= 1
		mad eA, out_index_1, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, life_height

		alloc export= 1
		mad eA, out_index_2, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, shock_spread

		alloc export= 1
		mad eA, out_index_3, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, pendulum

		alloc export= 1
		mad eA, out_index_4, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, pattern

		alloc export= 1
		mad eA, out_index_5, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, foam

		alloc export= 1
		mad eA, out_index_6, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, flags

		alloc export= 1
		mad eA, out_index_7, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, funcs
	};
#endif

	// This is a workaround for a bug in >=Profile builds.  Without it, we get occasional 
	// bogus memexports from nowhere during effect-heavy scenes.
#ifdef PC_CPU
   return;
#elif pc
	return float4(0,0,0,0);
#else
	asm {
	alloc export=1
		mad eA.xyzw, hidden_from_compiler.y, hidden_from_compiler.yyyy, hidden_from_compiler.yyyy
	};
	asm {
	alloc export=1
		mad eA.xyzw, hidden_from_compiler.z, hidden_from_compiler.zzzz, hidden_from_compiler.zzzz
	};
#endif
}

#endif


void ripple_update_main(inout s_ripple ripple)
{
	if (ripple.life > 0)
	{		
		ripple.size+= ripple.spread * k_vs_ripple_real_frametime_ratio;
		ripple.pendulum_phase+= ripple.pendulum_revolution * k_vs_ripple_real_frametime_ratio;

		if ( ripple.flag_drift )
		{
			ripple.position+= float2(ripple.flow) * float(k_vs_ripple_real_frametime_ratio);
		}

		ripple.life-= k_ripple_time_per_frame * k_vs_ripple_real_frametime_ratio;
		ripple.foam_life-= k_ripple_time_per_frame * k_vs_ripple_real_frametime_ratio;
	}
}

#if DX_VERSION == 9

#ifdef PC_CPU
	float4 ripple_update_vs(s_ripple_vertex_input _IN)   
#elif (DX_VERSION == 9) && defined(pc)
	float4 ripple_update_vs(s_ripple_vertex_input _IN) : SV_Position
#else
	void ripple_update_vs(s_ripple_vertex_input _IN)
#endif
{
   #ifdef PC_CPU
	   const float4 k_offset_const(0, 1, 0, 0);
	#else
	   const float4 k_offset_const= { 0, 1, 0, 0 };
	#endif
	int index= _IN.index;

	s_ripple ripple= fetch_ripple(index);
	
	ripple_update_main(ripple);

	// pack data
	float4 position_flow= float4(ripple.position, ripple.flow);
	float4 life_height= float4(ripple.life, ripple.duration, ripple.rise_period, ripple.height);
	float4 shock_spread= float4(ripple.shock, ripple.size, ripple.spread);
	float4 pendulum= float4(ripple.pendulum_phase, ripple.pendulum_revolution, ripple.pendulum_repeat, 0.0f);
	float4 foam= float4(ripple.foam_out_radius, ripple.foam_fade_distance, ripple.foam_life, ripple.foam_duration);

	// export to stream	
	int out_index_0= index * ripple_vertex_stream_block_num;
	int out_index_1= out_index_0 + 1;
	int out_index_2= out_index_0 + 2;
	int out_index_3= out_index_0 + 3;
	// skip 4
	int out_index_5= out_index_0 + 5;		
	// skip 6
	// skip 7
	

	// only update, when ripple is alive
#ifdef PC_CPU
   out_index_0;
   out_index_1;
   out_index_2;
   out_index_3;
   out_index_5;

	byte* p = (byte*)g_cur_vertex_output_data;

	*(float4*)p = position_flow; p += sizeof(float4);
	*(float4*)p = life_height; p += sizeof(float4);
	*(float4*)p = shock_spread; p += sizeof(float4);
	*(float4*)p = pendulum; p += sizeof(float4);
	/**(float4*)p = pattern;*/ p += sizeof(float4);
	*(float4*)p = foam; p += sizeof(float4);
	/**(float4*)p = flags;*/ p += sizeof(float4);
	/**(float4*)p = funcs;*/ p += sizeof(float4);

#elif pc
#else
	asm
	{
		alloc export= 1
		mad eA, out_index_0, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, position_flow

		alloc export= 1
		mad eA, out_index_1, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, life_height

		alloc export= 1
		mad eA, out_index_2, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, shock_spread

		alloc export= 1
		mad eA, out_index_3, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, pendulum

		alloc export= 1
		mad eA, out_index_5, k_offset_const, k_vs_ripple_memexport_addr
		mov eM0, foam
	};
#endif

	// This is a workaround for a bug in >=Profile builds.  Without it, we get occasional 
	// bogus memexports from nowhere during effect-heavy scenes.
#ifdef PC_CPU
	return float4(0,0,0,0);
#elif pc
	return float4(0,0,0,0);
#else
	asm {
	alloc export=1
		mad eA.xyzw, hidden_from_compiler.y, hidden_from_compiler.yyyy, hidden_from_compiler.yyyy
	};
	asm {
	alloc export=1
		mad eA.xyzw, hidden_from_compiler.z, hidden_from_compiler.zzzz, hidden_from_compiler.zzzz
	};
#endif
}

#elif DX_VERSION == 11

[numthreads(CS_RIPPLE_UPDATE_THREADS,1,1)]
void ripple_update_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + ripple_index_range.x;
	if (index < ripple_index_range.y)
	{
		s_ripple ripple = cs_ripple_buffer[index];
		ripple_update_main(ripple);
		cs_ripple_buffer[index] = ripple;
	}
}

#endif

#endif

#ifdef VERTEX_SHADER

#define k_ripple_corners_number 16
static const float2 k_ripple_corners[k_ripple_corners_number]= 
{ 
#if DX_VERSION == 9
	float2(-1, -1), float2(0, -1), float2(0, 0), float2(-1, 0),
	float2(0, -1), float2(1, -1), float2(1, 0), float2(0, 0),
	float2(0, 0), float2(1, 0), float2(1, 1), float2(0, 1),
	float2(-1, 0), float2(0, 0), float2(0, 1), float2(-1, 1)
#elif DX_VERSION == 11
	float2(-1, -1), float2(0, -1),  float2(-1, 0), float2(0, 0),
	float2(0, -1), float2(1, -1),  float2(0, 0), float2(1, 0),
	float2(0, 0), float2(1, 0),  float2(0, 1), float2(1, 1),
	float2(-1, 0), float2(0, 0),  float2(-1, 1), float2(0, 1),
#endif
};


s_ripple_interpolators ripple_apply_vs(
#if DX_VERSION == 9
	s_ripple_vertex_input _IN
#elif DX_VERSION == 11
	uint instance_id : SV_InstanceID,
	uint vertex_id : SV_VertexID
#endif
)
{
#if (DX_VERSION == 9) && defined(pc)
	s_ripple ripple = fetch_ripple_from_input(_IN);
#elif DX_VERSION == 11
	int ripple_index = instance_id / 4;	
	s_ripple ripple = vs_ripple_buffer[ripple_index];
#else
	// fetch ripple
	int ripple_index= (_IN.index + 0.5) / k_ripple_corners_number;
	s_ripple ripple= fetch_ripple(ripple_index);
#endif

	s_ripple_interpolators _OUT;
	if (ripple.life > 0)
	{
#if (DX_VERSION == 9) && defined(pc)
		int corner_index= _IN.index.x;
#elif DX_VERSION == 11
		int corner_index = vertex_id + ((instance_id & 3) * 4);
#else
		int corner_index= _IN.index - ripple_index * k_ripple_corners_number;
#endif
		float2 corner= k_ripple_corners[corner_index];

		float3 shock_dir;
		if ( length(ripple.shock) < 0.01f ) 
		{
			shock_dir= float3(1.0f, 0.0f, 0.0f);
		}
		else
		{
			shock_dir= normalize(float3(ripple.shock, 0.0f));
		}

		

		float2 position;
		//position.x= -corner.x * shock_dir.x - corner.y * shock_dir.y;
		//position.y= corner.x * shock_dir.y - corner.y * shock_dir.x;

		position.y= -corner.x * shock_dir.x - corner.y * shock_dir.y;
		position.x= corner.x * shock_dir.y - corner.y * shock_dir.x;

		position= position*ripple.size + ripple.position;		

		position= (position - k_vs_camera_position.xy) / k_ripple_buffer_radius;					
		float len= length(position);
		position*= rsqrt(len);		

		position+= k_ripple_buffer_center;		

		float period_in_life= 1.0f - ripple.life/ripple.duration;
		float pattern_index= lerp(ripple.pattern_start_index, ripple.pattern_end_index, evaluate_transition_internal(ripple.func_pattern, period_in_life));
#if DX_VERSION == 9		
		pattern_index= (pattern_index+0.5f) / k_vs_ripple_pattern_count;
#endif


		float ripple_height;
		if ( period_in_life < ripple.rise_period )
		{
			float rise_percentage= max(ripple.rise_period, 0.001f); // avoid to be divded by zero
			ripple_height= lerp(0.0f, ripple.height, evaluate_transition_internal(ripple.func_rise, period_in_life / rise_percentage));
		}
		else
		{
			float descend_percentage= max(1.0f-ripple.rise_period, 0.001f); // avoid to be divded by zero
			ripple_height= lerp(ripple.height, 0.0f, evaluate_transition_internal(ripple.func_descend, (period_in_life - ripple.rise_period)/descend_percentage));			
		}

		// calculate foam 
		float foam_opacity= 0.0f;
		float foam_out_radius= 0.0f;
		float foam_fade_distance= 0.0f; 
		if (ripple.flag_foam && ripple.foam_life>0)		
		{
			float period_in_foam_life= 1.0f - ripple.foam_life/ripple.foam_duration;
			foam_opacity= lerp(1.0f, 0.0f, evaluate_transition_internal(ripple.func_foam, period_in_foam_life));						

			// convert distances from object space into texture space
			if (ripple.flag_foam_game_unit)
			{
				foam_out_radius= ripple.foam_out_radius / ripple.size;
				foam_fade_distance= ripple.foam_fade_distance / ripple.size;
			}
			else
			{
				foam_out_radius= ripple.foam_out_radius;
				foam_fade_distance= ripple.foam_fade_distance;
			}
		}				

		// calculate pendulum
		if ( ripple.flag_pendulum )
		{
			ripple.pendulum_phase= abs(ripple.pendulum_phase); // guarantee always positive
		}
		else
		{
			ripple.pendulum_phase= -1.0f;	
		}

		// output
		_OUT.position= float4(position, 0.0f, 1.0f);
		_OUT.texcoord= float4(corner*0.5f + float2(0.5f, 0.5f), pattern_index, ripple_height);
		_OUT.pendulum= float4(ripple.pendulum_phase, ripple.pendulum_repeat, 0.0f, 0.0f); 
		_OUT.foam= float4(foam_opacity, foam_out_radius, foam_fade_distance, 0.0f);

	}
	else 
	{
		_OUT.position= 0.0f;	// invalidate position, kill primitive
		_OUT.texcoord= 0.0f;
		_OUT.pendulum= 0.0f;
		_OUT.foam= 0.0f;
	}
	return _OUT;
}

static const float2 k_screen_corners[4]= 
{ 
	float2(-1, -1), 
	float2(1, -1), 
#if DX_VERSION == 9
	float2(1, 1), 
	float2(-1, 1)
#elif DX_VERSION == 11
	float2(-1, 1),
	float2(1, 1)
#endif
};

s_ripple_interpolators ripple_slope_vs(s_ripple_vertex_input _IN)
{
#if (DX_VERSION == 9) && defined(pc)
	float2 corner= k_screen_corners[int(_IN.index.x)];
#else
	float2 corner= k_screen_corners[_IN.index];
#endif
	s_ripple_interpolators _OUT;
	_OUT.position= float4(corner, 0, 1);
	_OUT.texcoord= float4(corner / 2 + float2(0.5, 0.5), 0.0f, 0.0f);
	_OUT.pendulum= 0.0f;
	_OUT.foam= 0.0f;
	return _OUT;
}

#ifndef PC_CPU
s_underwater_interpolators underwater_vs(s_ripple_vertex_input _IN)
{
#if (DX_VERSION == 9) && defined(pc)
	float2 corner= k_screen_corners[int(_IN.index.x)];
#else
	float2 corner= k_screen_corners[_IN.index];
#endif
	
	s_underwater_interpolators _OUT;
	_OUT.position= float4(corner, 0, 1);
	_OUT.position_ss= _OUT.position;
	return _OUT;
}
#endif //PC_CPU

s_underwater_interpolators underwater_new_vs(s_underwater_interpolators _IN)
{
	s_underwater_interpolators _OUT;
	_OUT.position = float4(_IN.position.xy, 0, 1);
	_OUT.position_ss = float4(_IN.position_ss.xy, 0, 0);
	return _OUT;
}

#endif //VERTEX_SHADER



#ifdef PIXEL_SHADER

#if DX_VERSION == 9
//	should never been executed
float4 ripple_add_ps( SCREEN_POSITION_INPUT(screen_position) ) : SV_Target
{
	return float4(0,1,2,3);
}

//	should never been executed
float4 ripple_update_ps( SCREEN_POSITION_INPUT(screen_position) ) : SV_Target
{
	return float4(0,1,2,3);
}
#endif

float4 ripple_apply_ps( s_ripple_interpolators _IN ) : SV_Target
{	
	//float height= sample3D(tex_ripple_pattern, _IN.texcoord.xyz).r ;	
	float4 height_tex;
	float4 texcoord= _IN.texcoord;
#if (DX_VERSION == 9) && defined(pc)
	height_tex = sample3D(tex_ripple_pattern, float4(texcoord.xyz, 0));
#elif DX_VERSION == 11
	float4 ripple_texcoord = convert_3d_texture_coord_to_array_texture(tex_ripple_pattern, texcoord.xyz);
	height_tex = lerp(
		tex_ripple_pattern.t.Sample(tex_ripple_pattern.s, ripple_texcoord.xyz),
		tex_ripple_pattern.t.Sample(tex_ripple_pattern.s, ripple_texcoord.xyw),
		frac(ripple_texcoord.z));
#else
	asm
	{
		tfetch3D height_tex, texcoord.xyz, tex_ripple_pattern, MagFilter= linear, MinFilter= linear, MipFilter= linear, VolMagFilter= linear, VolMinFilter= linear
	};
#endif
	float height= (height_tex.r - 0.5f) * _IN.texcoord.w;				
	
	// for pendulum
	[branch]
	if ( _IN.pendulum.x > -0.01f)
	{
		float2 direction= _IN.texcoord.xy*2.0f - 1.0f;
		float phase= _IN.pendulum.x - length(direction) * _IN.pendulum.y;
		height*= cos(phase);	
	}

	float4 _OUT= 0.0f;	
	_OUT.r= height.r;

	// for foam
	[branch]
	if ( _IN.foam.x > 0.01f )
	{
		float2 direction= _IN.texcoord.xy*2.0f - 1.0f;
		float distance= length(direction);

		distance= max(_IN.foam.y - distance, 0.0f);
		float edge_fade= min( distance/max(_IN.foam.z, 0.001f), 1.0f);
		_OUT.g= edge_fade * _IN.foam.x * height_tex.a;			
	}

	return _OUT;
}

float4 ripple_slope_ps( s_ripple_interpolators _IN ) : SV_Target
{	
	float4 _OUT= float4(0.5f, 0.5f, 0.5f, 0.0f);
	float4 texcoord= _IN.texcoord;
	float4 tex_x1_y1;
#ifdef pc
	tex_x1_y1 = sample2D(tex_ripple_buffer_height, float4(texcoord.xy, 0, 0));
#else
	asm{ tfetch2D tex_x1_y1, texcoord, tex_ripple_buffer_height, MagFilter= point, MinFilter= point };
#endif

	//[branch]
	//if ( tex_x1_y1.a > 0.1f )
	{
		float4 tex_x2_y1, tex_x1_y2;
#ifdef pc
		tex_x2_y1 = sample2D(tex_ripple_buffer_height, float4(texcoord.x + 1.0/800.0, texcoord.y, 0, 0));
		tex_x1_y2 = sample2D(tex_ripple_buffer_height, float4(texcoord.x, texcoord.y + 1.0/800.0, 0, 0));
#else
		asm{ tfetch2D tex_x2_y1, texcoord, tex_ripple_buffer_height, OffsetX= 1.0f, MagFilter= point, MinFilter= point };
		asm{ tfetch2D tex_x1_y2, texcoord, tex_ripple_buffer_height, OffsetY= 1.0f, MagFilter= point, MinFilter= point };
#endif

		float2 slope;
		slope.x= tex_x2_y1.r - tex_x1_y1.r;
		slope.y= tex_x1_y2.r - tex_x1_y1.r;
	   
		// Scale to [0 .. 1]		
		slope= saturate(slope * 0.5f + 0.5f);
		
		float4 org_OUT;
		org_OUT.r= saturate( (tex_x1_y1.r + 1.0f) * 0.5f );
		org_OUT.g= slope.x;
		org_OUT.b= slope.y;
		org_OUT.a= tex_x1_y1.g;

		// damping the brim	
		float2 distance_to_brim= saturate(100.0f *(0.497f - abs(_IN.texcoord.xy-0.5f)));
		float lerp_weight= min(distance_to_brim.x, distance_to_brim.y);
		_OUT= lerp(_OUT, org_OUT, lerp_weight);
	}
	
	return _OUT;
}

float compute_fog_factor( 
			float murkiness,
			float depth)
{
	return 1.0f - saturate(1.0f / exp(murkiness * depth));	
}


accum_pixel underwater_ps( s_underwater_interpolators INTERPOLATORS )
{	
	float3 output_color= 0;	

	// calcuate texcoord in screen space
	INTERPOLATORS.position_ss/= INTERPOLATORS.position_ss.w;
	
#if DX_VERSION == 9
	float2 texcoord_ss= INTERPOLATORS.position_ss.xy;
	texcoord_ss= texcoord_ss / 2 + 0.5;
	texcoord_ss.y= 1 - texcoord_ss.y;
	texcoord_ss= k_ps_water_player_view_constant.xy + texcoord_ss*k_ps_water_player_view_constant.zw;
#endif

	// get pixel position in world space
	float distance= 0.0f;
	
#if DX_VERSION == 9	
	float pixel_depth= sample2D(tex_depth_buffer, texcoord_ss).r;		
#elif DX_VERSION == 11
	int3 iscreen_pos = int3(INTERPOLATORS.position.xy, 0);
	float pixel_depth = tex_depth_buffer.t.Load(iscreen_pos).r;
#endif
	
	float4 pixel_position= float4(INTERPOLATORS.position_ss.xy, pixel_depth, 1.0f);		
	pixel_position= mul(pixel_position, k_ps_water_view_xform_inverse);
	pixel_position.xyz/= pixel_position.w;
	distance= length(k_ps_camera_position - pixel_position.xyz);	

	// get pixel color
#if DX_VERSION == 9	
	float3 pixel_color= sample2D(tex_ldr_buffer, texcoord_ss).rgb;
#elif DX_VERSION == 11
	float3 pixel_color = tex_ldr_buffer.t.Load(iscreen_pos).rgb;
#endif

	// calc under water fog
	float transparence= 0.5f * saturate(1.0f - compute_fog_factor(k_ps_underwater_murkiness, distance));						
	output_color= lerp(k_ps_underwater_fog_color, pixel_color, transparence);	
		
	return convert_to_render_target(float4(output_color, 1.0f), true, true
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}

#define k_underwater_murkiness_multiplier 1.44269502;

accum_pixel underwater_new_ps( s_underwater_interpolators INTERPOLATORS ) : COLOR
{
	float scene_depth = (k_ps_water_view_depth_constant.x / tex2D(tex_depth_buffer, INTERPOLATORS.position_ss.xy).r) + k_ps_water_view_depth_constant.y;
    float3 scene_color = tex2D(tex_ldr_buffer, INTERPOLATORS.position_ss.xy).rgb;

	float4 transform_tex = float4(INTERPOLATORS.position_ss.xy, 1.0f - scene_depth, 1.0f);
    transform_tex.y = 1.0f - transform_tex.y;
    transform_tex.xy -= 0.5f;
    transform_tex.xy /= 0.5f;
    
    float4 water_view = mul(transform_tex, k_ps_water_view_xform_inverse);
    
    water_view.xyz = water_view.xyz / water_view.w - k_ps_camera_position.xyz;
    float view_murkiness = rcp(rsqrt(dot(water_view.xyz, water_view.xyz))) * k_ps_underwater_murkiness;
    view_murkiness *= k_underwater_murkiness_multiplier;
    view_murkiness = saturate(1.0f / exp2(view_murkiness));
    
    view_murkiness = -view_murkiness + 1.0f;
    view_murkiness = -view_murkiness + 1.0f;
    view_murkiness *= 0.5f;
    
    float3 fog_color = lerp(k_ps_underwater_fog_color, scene_color, view_murkiness);
    
    fog_color = max(fog_color, 0);
    
    return convert_to_render_target(float4(fog_color, 1.0f), true, true
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}

#endif //PIXEL_SHADER



// #else /* implementation of pc version */
// 
// struct s_ripple_interpolators
// {
// 	float4 position	:POSITION0;
// };
// 
// s_ripple_interpolators ripple_add_vs()
// {
// 	s_ripple_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// s_ripple_interpolators ripple_update_vs()
// {
// 	s_ripple_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// s_ripple_interpolators ripple_apply_vs()
// {
// 	s_ripple_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// s_ripple_interpolators ripple_slope_vs()
// {
// 	s_ripple_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// s_ripple_interpolators underwater_vs()
// {
// 	s_ripple_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// 
// float4 ripple_add_ps(s_ripple_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// float4 ripple_update_ps(s_ripple_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// float4 ripple_apply_ps(s_ripple_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// float4 ripple_slope_ps(s_ripple_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// float4 underwater_ps(s_ripple_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// #endif //pc/xenon

// end of rename marco
#undef ripple_update_vs
#undef ripple_update_ps
#undef ripple_update_cs
#undef ripple_apply_vs	
#undef ripple_apply_ps	
#undef ripple_slope_vs	
#undef ripple_slope_ps	
#undef underwater_vs
#undef underwater_ps