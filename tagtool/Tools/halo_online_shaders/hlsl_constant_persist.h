#ifndef _HLSL_CONSTANT_PERSIST_H_
#define _HLSL_CONSTANT_PERSIST_H_

//NOTE: if you modify any of this, than you need to modify hlsl_constant_persist.fx 

//////////////////////////////////////////////////////////////////////////
//!!NOTE: if you modify any of this and add persist/oneshot PS & VS constants, you need to
// add corresponding code to c_command_buffer_cache::initialize_persist_constant_usage_mask (command_buffers.cpp)

struct s_view_constants
{
	real_vector4d view_proj_xform_x;
	real_vector4d view_proj_xform_y;
	real_vector4d view_proj_xform_z;
	real_vector4d view_proj_xform_w;
	real_vector4d view_xform_x;
	real_vector4d view_xform_y;
	real_vector4d view_xform_z;
	real_vector4d view_xform_position;
	real_vector4d screen_xform_x;
	real_vector4d screen_xform_y;
	real_vector4d viewport_scale;
	real_vector4d viewport_offset;
};

#if DX_VERSION == 9

//vertex shader registers
enum 
{
	k_first_view_constant= 0,
	k_viewproj_xform_x= k_first_view_constant,
	k_viewproj_xform_y,
	k_viewproj_xform_z,
	k_viewproj_xform_w,
	k_camera_forward,
	k_camera_left,
	k_camera_up,
	k_camera_position,
	k_screen_xform_x,
	k_screen_xform_y,
	k_viewport_scale,
	k_viewport_offset,
	k_last_view_constant,

	k_vs_atmosphere_constant_extra=	15,
	k_vs_exposure= 232,
	k_vs_alt_exposure= 239,

	k_vs_atmosphere_constant_0=	233,
	k_vs_atmosphere_constant_1=	234,
	k_vs_atmosphere_constant_2= 235,
	k_vs_atmosphere_constant_3= 236,
	k_vs_atmosphere_constant_4= 237,
	k_vs_atmosphere_constant_5= 238,

	k_vs_lighting_constant_0=	240,
	k_vs_lighting_constant_1=	241,
	k_vs_lighting_constant_2=	242,
	k_vs_lighting_constant_3=	243,
	k_vs_lighting_constant_4=	244,
	k_vs_lighting_constant_5=	245,
	k_vs_lighting_constant_6=	246,
	k_vs_lighting_constant_7=	247,
	k_vs_lighting_constant_8=	248,
	k_vs_lighting_constant_9=	249,

	k_vs_shadow_projection= k_vs_lighting_constant_0,

	k_material_cook_torrance= 247,
	k_vs_squish_params= 250,

	k_number_of_view_constants= k_last_view_constant-k_first_view_constant,

	k_bool_compressed_lightmaps= 0,
	k_number_of_bool_constants,
};

//pixel shader registers
enum 
{
	k_ps_exposure= 0,

	k_ps_lighting_constant_0=		1,
	k_ps_lighting_constant_1=		2,
	k_ps_lighting_constant_2=		3,
	k_ps_lighting_constant_3=		4,
	k_ps_lighting_constant_4=		5,
	k_ps_lighting_constant_5=		6,
	k_ps_lighting_constant_6=		7,
	k_ps_lighting_constant_7=		8,
	k_ps_lighting_constant_8=		9,
	k_ps_lighting_constant_9=		10,

	k_ps_alt_exposure=				12,		// 

	k_ps_texture_size=				14,
	k_ps_dynamic_environment_blend= 15,

	k_register_camera_position_ps=	16,
	k_register_simple_light_count=	17,
	k_register_simple_light_start=	18,


	//	constants for light map dxt5 compression, 
	k_ps_lightmap_compress_constant_using_dxt= 10,		// boolean 

	k_ps_lightmap_compress_constant_0=		210,
	k_ps_lightmap_compress_constant_1=		211,
	k_ps_lightmap_compress_constant_2=		212,

#ifdef XENON
	k_tiling_vpos_offset=			108,
	k_tiling_resolvetexture_xform=	109,
	k_tiling_reserved2=				110,
	k_tiling_reserved3=				111,
#endif

	k_ps_render_debug_mode= 94,

#ifdef PC
	k_shader_pc_specular_enabled=	95,
	k_shader_pc_albedo_lighting=	96,
#endif // pc
};

// pixel shader actual constants
enum
{
#ifdef PC
	k_maximum_simple_light_count=	8,
#else
	k_maximum_simple_light_count=	16,
#endif
};

//samplers accessed by vertex shader
enum
{
	k_vs_sampler_atmosphere_neta_table= 0,
	k_vs_sampler_weather_occlusion,	// can go in oneshot if necessary
	k_number_of_vs_sampler,
};

//pixel shader common samplers --- do not allow any collisions by explicitly declaring samplers greater than 10 elsewhere!!!
enum
{
	//STATIC LIGHTING
#if DX_VERSION == 11
	k_sampler_lightprobe_texture_array= 13,
	k_sampler_dominant_light_intensity_map= 14,
	
	k_sampler_scene_ldr_texture= 15,
	
	k_sampler_albedo_texture= 16, 
	k_sampler_normal_texture= 17, 
	
	k_sampler_depth_buffer = 18,
#else	
	k_sampler_albedo_texture= 10, 
	k_sampler_normal_texture= 11, 

	//#ifndef PC
	k_sampler_lightprobe_texture_array= 12, 
	k_sampler_dominant_light_intensity_map= 13, 
//#endif

	//WATER, ACTIVE CAMO
	k_sampler_scene_ldr_texture= 10, 	
	k_sampler_scene_hdr_texture= 11,	// don't use unless you resolve the conflict with k_sampler_depth_buffer!!!

	//WATER, PARTICLES 
	k_sampler_depth_buffer= 11, 
#endif
};

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\hlsl_constant_persist.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif //_HLSL_CONSTANT_PERSIST_H_