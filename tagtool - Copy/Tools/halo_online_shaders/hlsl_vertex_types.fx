
#ifndef PC_CPU
#line 2 "source\rasterizer\hlsl\hlsl_vertex_types.fx"
#endif

#ifndef _HLSL_VERTEX_TYPES_FX_
#define _HLSL_VERTEX_TYPES_FX_

#ifndef vertex_type
#error You need to define 'vertex_type' in the preprocessor
#endif

#define VERTEX_TYPE(type) VERTEX_TYPE_##type
#define IS_VERTEX_TYPE(type) (VERTEX_TYPE(vertex_type)== VERTEX_TYPE(type))

#define VERTEX_TYPE_s_world_vertex			0
#define VERTEX_TYPE_s_rigid_vertex			1
#define VERTEX_TYPE_s_skinned_vertex		2
#define VERTEX_TYPE_s_particle_model_vertex	3
#define VERTEX_TYPE_s_flat_world_vertex		4
#define VERTEX_TYPE_s_flat_rigid_vertex		5
#define VERTEX_TYPE_s_flat_skinned_vertex	6
#define VERTEX_TYPE_s_screen_vertex			7
#define VERTEX_TYPE_s_debug_vertex			8
#define VERTEX_TYPE_s_transparent_vertex	9
#define VERTEX_TYPE_s_particle_vertex		10
#define VERTEX_TYPE_s_contrail_vertex		11
#define VERTEX_TYPE_s_light_volume_vertex	12
#define VERTEX_TYPE_s_chud_vertex_simple	13
#define VERTEX_TYPE_s_chud_vertex_fancy		14
#define VERTEX_TYPE_s_decorator_vertex		15
#define VERTEX_TYPE_s_tiny_position_vertex	16
#define VERTEX_TYPE_s_patchy_fog_vertex		17
#define VERTEX_TYPE_s_water_vertex			18
#define VERTEX_TYPE_s_ripple_vertex			19
#define VERTEX_TYPE_s_implicit_vertex		20

// data from application vertex buffer
struct s_world_vertex 
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float2 texcoord		:TEXCOORD0;
	float3 normal		:NORMAL;
	float3 tangent		:TANGENT;
	float3 binormal		:BINORMAL;
#else
	float3 position;
	float2 texcoord;
	float3 normal;
	float3 tangent;
	float3 binormal;
#endif
};
typedef s_world_vertex s_flat_world_vertex;	// the normal/binormal/tangent are present, but ignored

struct s_rigid_vertex 
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float2 texcoord		:TEXCOORD0; 
	float3 normal		:NORMAL;
	float3 tangent		:TANGENT;
	float3 binormal		:BINORMAL;
#else
    float3 position;
    float2 texcoord; 
    float3 normal;
    float3 tangent;
    float3 binormal;
#endif
};
typedef s_rigid_vertex s_flat_rigid_vertex;	// the normal/binormal/tangent are present, but ignored

struct s_skinned_vertex 
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float2 texcoord		:TEXCOORD0;
	float3 normal		:NORMAL;
	float3 tangent		:TANGENT;
	float3 binormal		:BINORMAL;
#if DX_VERSION == 11
	uint4 node_indices 	:BLENDINDICES;
#else
	float4 node_indices :BLENDINDICES;
#endif
	float4 node_weights :BLENDWEIGHT;
#else
	float3 position;
	float2 texcoord;
	float3 normal;
	float3 tangent;
	float3 binormal;
	float4 node_indices;
	float4 node_weights;
#endif
};
typedef s_skinned_vertex s_flat_skinned_vertex;	// the normal/binormal/tangent are present, but ignored

struct s_screen_vertex 
{
#ifndef PC_CPU
   float2 position		:POSITION;
   float2 texcoord		:TEXCOORD0;
   float4 color			:COLOR0;
#else
   float2 position;
   float2 texcoord;
   float4 color;
#endif
};

struct s_debug_vertex
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float4 color		:COLOR0;
#else
	float3 position;
	float4 color;
#endif
};

struct s_transparent_vertex
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float2 texcoord		:TEXCOORD0;
	float4 color		:COLOR0;
#else
	float3 position;
	float2 texcoord;
	float4 color;
#endif
};

// lighting model vertex structures
struct s_lightmap_per_pixel
{
#ifndef PC_CPU
	float2 texcoord		:TEXCOORD1;	
#else
	float2 texcoord;	
#endif
};

struct s_lightmap_per_vertex
{
#ifndef PC_CPU
	float3 color		:COLOR0;
#else
	float3 color;
#endif
};

struct s_particle_vertex
{
#ifndef PC_CPU
	#if DX_VERSION == 11
		int index;
		uint2 address;
	#elif defined(pc)
		// model data
		float4 model_pos_sample		:POSITION0;
		float4 model_uv_sample		:TEXCOORD0;
		float4 model_normal_sample	:NORMAL0;
		
		// vertex index [x, 0]
		float2 index				:TEXCOORD1;
			
		// instanced data	
		float4 pos_sample    		:POSITION1;
		float4 vel_sample    		:POSITION2;
		float4 rot_sample    		:TEXCOORD2;
		float4 time_sample   		:TEXCOORD3;
		float4 anm_sample    		:TEXCOORD4;
		float4 anm2_sample   		:TEXCOORD5;
		float4 rnd_sample    		:POSITION3;
		float4 rnd2_sample   		:POSITION4;
		float4 axis_sample   		:NORMAL1;
		float4 col_sample    		:COLOR0;
		float4 col2_sample   		:COLOR1;
	#else
		int index		:INDEX;
		// This is only present for the spawning particles
		float2 address	:TEXCOORD1;	// location within the particle storage buffer
	#endif
#else
	int index;
	float2 address;
#endif
	// The remaining fields are always accessed via explicit vfetches instead of implicitly
};

struct s_particle_model_vertex	// should be the same as s_particle_vertex
{
#ifndef PC_CPU
	#if DX_VERSION == 11
		// model data
		float4 model_pos_sample    :POSITION0;
		float4 model_uv_sample     :TEXCOORD0;
		float4 model_normal_sample :NORMAL0;		
	#elif defined(pc)
		// model data
		float4 model_pos_sample    :POSITION0;
		float4 model_uv_sample     :TEXCOORD0;
		float4 model_normal_sample :NORMAL0;

		// fake, just to be the same as s_particle_vertex
		float2 index               :TEXCOORD1;

		// instanced data
		float4 pos_sample    :POSITION1;
		float4 vel_sample    :POSITION2;
		float4 rot_sample    :TEXCOORD2;
		float4 time_sample   :TEXCOORD3;
		float4 anm_sample    :TEXCOORD4;
		float4 anm2_sample   :TEXCOORD5;
		float4 rnd_sample    :POSITION3;
		float4 rnd2_sample   :POSITION4;
		float4 axis_sample   :NORMAL1;
		float4 col_sample    :COLOR0;
		float4 col2_sample   :COLOR1;
	#else
		int index		:INDEX;
		// This is only present for the spawning particles
		float2 address	:TEXCOORD1;	// location within the particle storage buffer
	#endif
#else
	int index;
	float2 address;
#endif
	// The remaining fields are always accessed via explicit vfetches instead of implicitly
};

struct s_contrail_vertex
{
#ifndef PC_CPU
	#if DX_VERSION == 11
		int index;
	#elif defined(pc)
		float4 pos_sample                :POSITION;
		float4 vel_sample                :POSITION1;
		float4 rnd_sample                :POSITION2;

		float4 misc_sample_4x16f         :TEXCOORD0;
		float4 misc_sample_4x16un        :TEXCOORD2;    //:TEXCOORD2;
		float4 misc_sample_2x16f         :TEXCOORD3;    //:TEXCOORD3;
		float4 col_sample                :COLOR0;
		float4 col2_sample               :COLOR1;

		float2 index                     :TEXCOORD1;

		float4 next_pos_sample           :POSITION3;
		float4 next_vel_sample           :POSITION4;
		float4 next_rnd_sample           :POSITION5;

		float4 next_misc_sample_4x16f    :TEXCOORD4;
		float4 next_misc_sample_4x16un   :TEXCOORD5;
		float4 next_misc_sample_2x16f    :TEXCOORD6;
		float4 next_col_sample           :COLOR2;
		float4 next_col2_sample          :COLOR3;

		float4 next_next_pos_sample      :POSITION6;
   #else
		int index        :INDEX;
		// This is only present for the spawning profiles
		float2 address	:TEXCOORD1;	// location within the contrail storage buffer
   #endif

#else
   int index;
   float2 address;
#endif

	// The remaining fields are always accessed via explicit vfetches instead of implicitly
};

struct s_light_volume_vertex
{
#ifndef PC_CPU
	#if DX_VERSION == 11
		int index;
	#elif defined(pc)
		// vertex index [x, 0]
		float2 index					:TEXCOORD1;

		// instanced data
		float4 pos_sample				:POSITION0;
		float4 misc_sample_2x16f		:TEXCOORD0;
		float4 col_sample				:COLOR0;
	#else
		int index        :INDEX;
	#endif
#else
   int index;
#endif
};

struct s_beam_vertex
{
#ifndef PC_CPU
	#if DX_VERSION == 11
		int index;
	#elif defined(pc)
		// vertex index [x, 0]
		float2 index					:TEXCOORD1;

		// instanced data
		float4 pos_sample				:POSITION0;
		float4 misc_sample_4x16un		:TEXCOORD0;
		float4 misc_sample_4x16f		:TEXCOORD2;
		float4 col_sample				:COLOR0;

		float4 next_pos_sample			:POSITION1;
		float4 next_misc_sample_4x16un	:TEXCOORD3;
		float4 next_misc_sample_4x16f	:TEXCOORD4;
		float4 next_col_sample			:COLOR1;

   #else
	   int index        :INDEX;
	#endif
#else
   int index;
#endif
};

struct s_chud_vertex_simple
{
#ifndef PC_CPU
	float2 position		:POSITION;
	float2 texcoord		:TEXCOORD0;
#else
	float2 position;
	float2 texcoord;
#endif
};

struct s_chud_vertex_fancy
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float4 color		:COLOR0;
	float2 texcoord		:TEXCOORD0;
#else
	float3 position;
	float4 color;
	float2 texcoord;
#endif
};

struct s_implicit_vertex
{
#ifndef PC_CPU
	float3 position		:POSITION;
	float2 texcoord		:TEXCOORD0;
#else
	float3 position;
	float2 texcoord;
#endif
};

struct s_decorator_vertex
{
#ifndef PC_CPU
	// vertex data (stream 0)
	float3 position		:	POSITION0;
	float2 texcoord		:	TEXCOORD0;
	
	// instance data (stream 1)
	float4 instance_position	:	POSITION1;
	float4 instance_orientation	:	NORMAL1;
	float4 instance_color		:	COLOR1;
#else
	float3 position;
	float2 texcoord;
	float4 instance_position;
	float4 instance_orientation;
	float4 instance_color;
#endif

	// also stream 2 => vertex index (int)
};

//	has been ingored 
struct s_water_vertex
{
#ifndef PC_CPU
	float3 position		:	POSITION0;
	float2 texcoord		:	TEXCOORD0;
#else
	float3 position;
	float2 texcoord;
#endif
};

//	has been ingored 
struct s_ripple_particle_vertex
{
#ifndef PC_CPU
	float2 position		:	POSITION0;
#else
	float2 position;
#endif
};

struct s_tiny_position_vertex
{
#ifndef PC_CPU
	float3 position		:	POSITION0;
#else
	float3 position;
#endif
};

struct s_patchy_fog_vertex
{
#ifndef PC_CPU
	float4 position		:	POSITION0;
#else
	float3 position;
#endif

#ifdef pc
	float2 texcoord		:	TEXCOORD0;
#endif // pc
};

#endif
