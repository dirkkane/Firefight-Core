/*
WATER.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
04/12/2006 13:36 davcook	
*/

#include "global.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_water_vertex



// The strings in this test should be external preprocessor defines
#define TEST_CATEGORY_OPTION(cat, opt) (category_##cat== category_##cat##_option_##opt)
#define IF_CATEGORY_OPTION(cat, opt) if (TEST_CATEGORY_OPTION(cat, opt))
#define IF_NOT_CATEGORY_OPTION(cat, opt) if (!TEST_CATEGORY_OPTION(cat, opt))

// If the categories are not defined by the preprocessor, treat them as shader constants set by the game.
// We could automatically prepend this to the shader file when doing generate-templates, hmmm...

#include "hlsl_vertex_types.fx"
#include "hlsl_constant_persist.fx"


// Attempt to auto-synchronize constant and sampler registers between hlsl and cpp code.
#include "water_registers.fx"


// define before render_target.fx
#ifndef LDR_ALPHA_ADJUST
#define LDR_ALPHA_ADJUST g_exposure.w
#endif
#ifndef HDR_ALPHA_ADJUST
#define HDR_ALPHA_ADJUST g_exposure.b
#endif
#ifndef DARK_COLOR_MULTIPLIER
#define DARK_COLOR_MULTIPLIER g_exposure.g
#endif
#include "render_target.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_water_vertex

// The strings in this test should be external preprocessor defines
#define TEST_CATEGORY_OPTION(cat, opt) (category_##cat== category_##cat##_option_##opt)
#define IF_CATEGORY_OPTION(cat, opt) if (TEST_CATEGORY_OPTION(cat, opt))
#define IF_NOT_CATEGORY_OPTION(cat, opt) if (!TEST_CATEGORY_OPTION(cat, opt))


// rename entry point of water passes 
#define water_shading_tessellation_vs		static_per_pixel_vs
#define water_shading_tessellation_ps		static_per_pixel_ps
#define water_shading_non_tessellation_vs	static_per_vertex_vs
#define water_shading_non_tessellation_ps	static_per_vertex_ps
#define water_depth_only_vs				shadow_generate_vs
#define water_depth_only_ps				shadow_generate_ps

// #ifdef pc
// 	
// // The following defines the protocol for passing interpolated data between the vertex shader 
// // and the pixel shader.  
// struct s_water_interpolators
// {
// 	float4 position	:POSITION0;
// };
// 
// #ifdef VERTEX_SHADER
// s_water_interpolators water_tessellation_vs()
// {
// 	s_water_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// s_water_interpolators water_shading_tessellation_vs()
// {
// 	s_water_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// 
// s_water_interpolators water_shading_non_tessellation_vs()
// {
// 	s_water_interpolators OUT;
// 	OUT.position= 0.0f;
// 	return OUT;
// }
// 
// #endif //VERTEX_SHADER
// 
// 
// #ifdef PIXEL_SHADER
// float4 water_tessellation_ps(s_water_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// float4 water_shading_tessellation_ps(s_water_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// float4 water_shading_non_tessellation_ps(s_water_interpolators INTERPOLATORS) :COLOR0
// {
// 	return float4(0,1,2,3);
// }
// 
// #endif //PIXEL_SHADER
// 
// #else //xenon

/* Water profile contants and textures from tag*/
PARAM_SAMPLER_2D_ARRAY(wave_displacement_array);
PARAM(float4, wave_displacement_array_xform);
PARAM(float, time_warp);
PARAM(float, wave_height);

PARAM_SAMPLER_2D_ARRAY(wave_slope_array);
PARAM(float4, wave_slope_array_xform);
PARAM(float, time_warp_aux);
PARAM(float, wave_height_aux);

PARAM_SAMPLER_2D(watercolor_texture);
PARAM_SAMPLER_2D(global_shape_texture);
PARAM_SAMPLER_CUBE(environment_map);

// foam texture
PARAM_SAMPLER_2D(foam_texture);
PARAM(float4, foam_texture_xform);
PARAM_SAMPLER_2D(foam_texture_detail);
PARAM(float4, foam_texture_detail_xform);
PARAM(float, foam_height);
PARAM(float, foam_pow);

// wave shape
PARAM(float, displacement_range_x);
PARAM(float, displacement_range_y);
PARAM(float, displacement_range_z);
PARAM(float, slope_range_x);
PARAM(float, slope_range_y);

PARAM(float, choppiness_forward);
PARAM(float, choppiness_backward);
PARAM(float, choppiness_side);
PARAM(float, wave_visual_damping_distance);

PARAM(float, detail_slope_scale_x);
PARAM(float, detail_slope_scale_y);
PARAM(float, detail_slope_scale_z);
PARAM(float, detail_slope_steepness);

// refraction settings
PARAM(float, refraction_texcoord_shift);
PARAM(float, refraction_extinct_distance);
PARAM(float, minimal_wave_disturbance);
PARAM(float, refraction_depth_dominant_ratio);

// water appearance
PARAM(float, reflection_coefficient);
PARAM(float, sunspot_cut);
PARAM(float, shadow_intensity_mark);

PARAM(float, fresnel_coefficient);
PARAM(float3, water_color_pure);
PARAM(float, watercolor_coefficient);
PARAM(float3, water_diffuse);
PARAM(float, water_murkiness);
PARAM(bool, no_dynamic_lights);

// bank alpha
PARAM(float, bankalpha_infuence_depth);

// global shape
PARAM(float, globalshape_infuence_depth);

// additions from reach
PARAM(float4, global_shape_texture_xform);
PARAM(float4, watercolor_texture_xform);
float slope_scaler;
float normal_variation_tweak;
float fresnel_dark_spot;
float foam_coefficient;
float foam_cut;
samplerCUBE dynamic_environment_map_0;

//	ignore the vertex_type, input vertex type defined locally
struct s_vertex_type_water_tessellation
{
	uint index		:	SV_VertexID;
};

#ifdef pc

#define PC_WATER_TESSELLATION

struct s_vertex_type_water_shading
{
#ifdef PC_WATER_TESSELLATION
	float4	pos1xyz_tc1x		: POSITION0;
	float4	tc1y_tan1xyz		: POSITION1;
	float4	bin1xyz_lm1x		: POSITION2;
	float4	lm1y_pos2xyz		: POSITION3;
	float4	tc2xy_tan2xy		: POSITION4;
   float4	tan2z_bin2xyz		: POSITION5;
   float4	lm2xy_pos3xy		: POSITION6;
   float4	pos3z_tc3xy_tan3x	: POSITION7;
   float4	tan3yz_bin3xy		: TEXCOORD0;
   float3	bin3z_lm3xy			: TEXCOORD1;

	float4	li1xyz_bt1x			: NORMAL0;
   float4	bt1yz_li2xy			: NORMAL1;
   float4	li2z_bt2xyz			: NORMAL2;
   float4	li3xyz_bt3x			: NORMAL3;
   float2	bt3yz				   : NORMAL4;

   float3	bc					   : TEXCOORD2;
#else
	float3   position		      : POSITION0;
	float2   texcoord		      : TEXCOORD0;
	float3   normal            : NORMAL;
	float3   tangent           : TANGENT;
	float3   binormal          : BINORMAL;

	float2   lm_tex            : TEXCOORD1;

	float3   local_info        : POSITION1;
	float3   base_texcoord     : POSITION3;
#endif
};
#else
struct s_vertex_type_water_shading
{
	int index		:	SV_VertexID;

	// tessellation parameter
	float3 uvw		:	BARYCENTRIC;
	int quad_id		:	QUADID;	
};
#endif // pc


struct s_water_render_vertex
{
	float4 position;
	float4 texcoord;
	float4 normal;
	float4 tangent;
	float4 binormal;	
	float4 local_info;
	float4 base_tex;
	float4 lm_tex;	
};

// The following defines the protocol for passing interpolated data between the vertex shader 
// and the pixel shader.  
struct s_water_interpolators
{
	float4 position		:SV_Position;
	float4 texcoord		:TEXCOORD0;
#ifndef pc // todo: not enough output registers on PC [01/28/2013 paul.smirnov]
	float4 normal		:TEXCOORD1;
#endif // pc
	float4 tangent		:TEXCOORD2;		// w = misc_info.x = height_scale
	float4 binormal		:TEXCOORD3;		// w = misc_info.y = height_scale_aux
	float4 position_ss	:TEXCOORD4;		//	position in screen space
	float4 incident_ws	:TEXCOORD5;		//	view incident direction in world space, incident_ws.w store the distannce between eye and current vertex
	float4 position_ws  :TEXCOORD6;		// w = misc_info.w = water_depth
#ifndef pc // todo: not enough output registers on PC [01/28/2013 paul.smirnov]
	float4 misc_info	:TEXCOORD7;	
#endif // pc
	float4 base_tex		:TEXCOORD8;	
	float4 lm_tex		:TEXCOORD9;	
	float4 fog_extinction	:TEXCOORD10;
	float4 fog_inscatter	:TEXCOORD11; 
};

//	structure definition for underwater
struct s_underwater_vertex_input
{
	int index		:	SV_VertexID;
};

/* implementation */
#include "water_tessellation.fx"
#include "water_shading.fx"

//#endif //pc

#undef water_shading_tessellation_vs	
#undef water_shading_tessellation_ps
#undef water_shading_non_tessellation_vs
#undef water_shading_non_tessellation_ps


