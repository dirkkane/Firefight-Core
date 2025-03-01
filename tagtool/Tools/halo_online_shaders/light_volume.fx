/*
LIGHT_VOLUME.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/14/2005 4:14:31 PM (davcook)
	
Shaders for light_volume renders
*/

#include "global.fx"

#undef MEMEXPORT_ENABLED

// The strings in this test should be external preprocessor defines
#define TEST_CATEGORY_OPTION(cat, opt) (category_##cat== category_##cat##_option_##opt)
#define IF_CATEGORY_OPTION(cat, opt) if (TEST_CATEGORY_OPTION(cat, opt))
#define IF_NOT_CATEGORY_OPTION(cat, opt) if (!TEST_CATEGORY_OPTION(cat, opt))

#if DX_VERSION == 9
#define CATEGORY_PARAM(_name) PARAM(int, _name)
#elif DX_VERSION == 11
#define CATEGORY_PARAM(_name) PARAM(float, _name)
#endif

// If the categories are not defined by the preprocessor, treat them as shader constants set by the game.
// We could automatically prepend this to the shader file when doing generate-templates, hmmm...
#ifndef category_blend_mode
CATEGORY_PARAM(category_blend_mode);
#endif
#ifndef category_fog
CATEGORY_PARAM(category_fog);
#endif

#include "hlsl_vertex_types.fx"
#include "hlsl_constant_persist.fx"
#include "light_volume_registers.fx"
#include "blend.fx"

#ifdef VERTEX_SHADER
#include "light_volume_common.fx"
#include "atmosphere.fx"
#endif

//This comment causes the shader compiler to be invoked for certain types
//@generate s_light_volume_vertex

// The following defines the protocol for passing interpolated data between the vertex shader 
// and the pixel shader.  It pays to compress the data into as few interpolators as possible.
// The reads and writes should evaporate out of the compiled code into the register mapping.
struct s_light_volume_render_vertex
{
    float4 m_position;
    float2 m_texcoord;
    float4 m_color;		// COLOR semantic will not clamp to [0,1].
    float3 m_color_add;		// COLOR semantic will not clamp to [0,1].
};

struct s_light_volume_interpolators
{
	float4 m_position0	:SV_Position;
	float4 m_color0		:COLOR0;
	float4 m_color1		:COLOR1;
	float4 m_texcoord0	:TEXCOORD0;
};

s_light_volume_interpolators write_light_volume_interpolators(s_light_volume_render_vertex VERTEX)
{
	s_light_volume_interpolators INTERPOLATORS;
	
	INTERPOLATORS.m_position0= VERTEX.m_position;
	INTERPOLATORS.m_color0= VERTEX.m_color;
	INTERPOLATORS.m_color1= float4(VERTEX.m_color_add, 0.0f);
	INTERPOLATORS.m_texcoord0= float4(VERTEX.m_texcoord, 0.0f, 0.0f);

	return INTERPOLATORS;
}

s_light_volume_render_vertex read_light_volume_interpolators(s_light_volume_interpolators INTERPOLATORS)
{
	s_light_volume_render_vertex VERTEX;
	
	VERTEX.m_position= INTERPOLATORS.m_position0;
	VERTEX.m_color= INTERPOLATORS.m_color0;
	VERTEX.m_color_add= INTERPOLATORS.m_color1;
	VERTEX.m_texcoord= INTERPOLATORS.m_texcoord0.xy;

	return VERTEX;
}

#ifdef VERTEX_SHADER
	
// Actual input vertex format is hard-coded in vfetches as s_profile_state
s_light_volume_interpolators default_vs(
#if DX_VERSION == 11
	in uint instance_id : SV_instanceID,
	in uint vertex_id : SV_VertexID
#else
	vertex_type vIN
#endif
)
{
	s_light_volume_render_vertex OUT;
// #ifndef pc
	// This would be used for killing verts by setting oPts.z!=0 .
	//asm {
	//	config VsExportMode=kill
	//};

	// Break the input index into a prim index and a vert index within the primitive.
#if (DX_VERSION == 9) && defined(pc)
	int2 index_and_offset= int2(0, vIN.index.x);
    s_profile_state STATE= read_profile_state_from_input(vIN);
#elif DX_VERSION == 11
	uint quad_index = (vertex_id ^ ((vertex_id & 2) >> 1));
	int2 index_and_offset = int2(instance_id, quad_index);
	index_and_offset.x= profile_index_to_buffer_index(index_and_offset.x);
	s_profile_state STATE= read_profile_state(index_and_offset.x);
#else
	int2 index_and_offset= int2(round(vIN.index / 4), round(vIN.index % 4));
	index_and_offset.x= profile_index_to_buffer_index(index_and_offset.x);
	s_profile_state STATE= read_profile_state(index_and_offset.x);
#endif
	
	// Compute some useful quantities
	float3 camera_to_profile= normalize(STATE.m_position - Camera_Position);
	float sin_view_angle= length(cross(g_all_state.m_direction, normalize(camera_to_profile)));
	
	// Profiles have aspect ratio 1 from head-on, but not from the side
	float profile_length= lerp(STATE.m_thickness, g_all_state.m_profile_length, sin_view_angle);
	
	// Compute the vertex position within the plane of the sprite
	float4x2 shift = {{0.0f, 0.0f}, {1.0f, 0.0f}, {1.0f, 1.0f}, {0.0f, 1.0f}, };
	float2 billboard_pos= (shift[index_and_offset.y] * 1.0f - 0.5f) * float2(profile_length, STATE.m_thickness);
	
	// Transform from profile space to world space. 
	// Basis is facing camera, but rotated based on light volume direction
	float2x3 billboard_basis;
	billboard_basis[1]= normalize(cross(camera_to_profile, g_all_state.m_direction));
	billboard_basis[0]= cross(camera_to_profile, billboard_basis[1]);
	float3 world_pos= STATE.m_position + mul(billboard_pos, billboard_basis);
	
	// Transform from world space to clip space. 
	OUT.m_position= mul(float4(world_pos, 1.0f), View_Projection);
	
	// Compute vertex texcoord
	OUT.m_texcoord= shift[index_and_offset.y];

	// Compute profile color
	OUT.m_color= STATE.m_color * STATE.m_intensity;
	IF_NOT_CATEGORY_OPTION(blend_mode, multiply)
	{
		OUT.m_color.xyz*= V_ILLUM_EXPOSURE;
	}
	IF_CATEGORY_OPTION(fog, on)	// fog
	{
		float3 extinction, inscatter;
		compute_scattering(Camera_Position, STATE.m_position, extinction, inscatter);
		OUT.m_color.xyz*= extinction;
		OUT.m_color_add.xyz= inscatter * v_exposure.x;
	}
	else
	{
		OUT.m_color_add= float3(0.0f, 0.0f, 0.0f);
	}
	
	// Total intensity at a pixel should be approximately the same from all angles and any profile density.
	// Reduce alpha by the expected overdraw factor.
	float spacing= g_all_state.m_profile_distance * sin_view_angle;
	float overdraw= min(g_all_state.m_num_profiles, profile_length / spacing);
	OUT.m_color.w*= lerp(g_all_state.m_brightness_ratio, 1.0f, sin_view_angle) / overdraw;
// #else	//#ifndef pc
// 	OUT.m_position= float4(0.0f, 0.0f, 0.0f, 0.0f);	// Doesn't work on PC!!!  (This just makes it compile.)
// 	OUT.m_color= float4(0.0f, 0.0f, 0.0f, 0.0f);	// Doesn't work on PC!!!  (This just makes it compile.)
// 	OUT.m_color_add= float3(0.0f, 0.0f, 0.0f);
// 	OUT.m_texcoord = float2(0.0f, 0.0f);
// #endif	//#ifndef pc

    return write_light_volume_interpolators(OUT);
}
#endif	//#ifdef VERTEX_SHADER

#ifdef PIXEL_SHADER

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

#include "utilities.fx"
#include "render_target.fx"

PARAM_SAMPLER_2D(base_map);
//PARAM(float, depth_fade_range);

PARAM(float, center_offset);
PARAM(float, falloff);

float4 sample_diffuse(float2 texcoord)
{
	IF_CATEGORY_OPTION(albedo, diffuse_only)
	{
		return sample2D(base_map, texcoord);
	}
	IF_CATEGORY_OPTION(albedo, circular)
	{
		float2	delta=		2 * texcoord - 1;
		float	radius=		saturate(center_offset - center_offset * dot(delta.xy, delta.xy));
//		float	alpha=		radius * radius * sqrt(radius);
		float	alpha=		pow(radius, falloff);
		return	float4(alpha, alpha, alpha, 1.0f);
	}
}

//float compute_depth_fade(float2 screen_coords, float depth, float range)
//{
//#if (DX_VERSION == 9)
//	if (!TEST_CATEGORY_OPTION(depth_fade, off) && !TEST_CATEGORY_OPTION(blend_mode, opaque))
//	{
//		float2 screen_texcoord= (screen_coords.xy + float2(0.5f, 0.5f)) / texture_size.xy;
//		float4 depth_value= sample2D(depth_buffer, screen_texcoord);
//		float particle_depth= depth;
//		float delta_depth= scene_depth - particle_depth;
//		return saturate(delta_depth / range);
//	}
//	else
//#endif // !pc
//	{
//		return 1.0f;
//	}
//}

typedef accum_pixel s_light_volume_render_pixel_out;
s_light_volume_render_pixel_out default_ps(s_light_volume_interpolators INTERPOLATORS)
{
// #ifndef pc
	s_light_volume_render_vertex IN= read_light_volume_interpolators(INTERPOLATORS);

	// need glvs compile for this :/
	//float depth_fade=	compute_depth_fade(IN.m_screencoord, IN.m_depth, depth_fade_range);

	float4 blended= sample_diffuse(IN.m_texcoord);

	//blended.w *=		depth_fade;
	
	blended*= IN.m_color;
	
	// Non-linear blend modes don't work under the normal framework...
	IF_CATEGORY_OPTION(blend_mode, multiply)
	{
		blended.xyz= lerp(float3(1.0f, 1.0f, 1.0f), blended.xyz, blended.w);
	}
	else
	{
		blended.xyz+= IN.m_color_add;
	}
// #else
// 	float4 blended= float4(0.0f, 0.0f, 0.0f, 0.0f);
// #endif
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(blended, false, false, 0.0f);
}
#endif	//#ifdef PIXEL_SHADER
