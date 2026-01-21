/*
BEAM.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
11/14/2005 4:14:31 PM (davcook)
	
Shaders for beam renders
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
#include "blend.fx"

#ifdef VERTEX_SHADER
#include "beam_common.fx"
#include "atmosphere.fx"
#endif

#define BLEND_MODE_SELF_ILLUM (TEST_CATEGORY_OPTION(blend_mode, additive) || TEST_CATEGORY_OPTION(blend_mode, add_src_times_srcalpha))

//This comment causes the shader compiler to be invoked for certain types
//@generate s_beam_vertex

// The following defines the protocol for passing interpolated data between the vertex shader 
// and the pixel shader.  It pays to compress the data into as few interpolators as possible.
// The reads and writes should evaporate out of the compiled code into the register mapping.
struct s_beam_render_vertex
{
    float4 m_position;
    float2 m_texcoord;
    float m_black_point; // avoid using interpolator for constant-per-profile value?
    float m_palette;	// avoid using interpolator for constant-per-profile value?
    float4 m_color;		// COLOR semantic will not clamp to [0,1].
    float3 m_color_add;		// COLOR semantic will not clamp to [0,1].
};

struct s_beam_interpolators
{
	float4 m_position0	:SV_Position;
	float4 m_color0		:COLOR0;
	float4 m_color1		:COLOR1;
	float4 m_texcoord0	:TEXCOORD0;
};

s_beam_interpolators write_beam_interpolators(s_beam_render_vertex VERTEX)
{
	s_beam_interpolators INTERPOLATORS;
	
	INTERPOLATORS.m_position0= VERTEX.m_position;
	INTERPOLATORS.m_color0= VERTEX.m_color;
	INTERPOLATORS.m_color1= float4(VERTEX.m_color_add, VERTEX.m_black_point);
	INTERPOLATORS.m_texcoord0= float4(VERTEX.m_texcoord, VERTEX.m_palette, 0.0f);

	return INTERPOLATORS;
}

s_beam_render_vertex read_beam_interpolators(s_beam_interpolators INTERPOLATORS)
{
    s_beam_render_vertex VERTEX;

    VERTEX.m_position = INTERPOLATORS.m_position0;
    VERTEX.m_color = INTERPOLATORS.m_color0;
    VERTEX.m_color_add = INTERPOLATORS.m_color1;
    VERTEX.m_black_point = INTERPOLATORS.m_color1.w;
    VERTEX.m_texcoord = INTERPOLATORS.m_texcoord0.xy;
    VERTEX.m_palette = INTERPOLATORS.m_texcoord0.z;

    return VERTEX;
}

#ifdef VERTEX_SHADER

// Match with c_beam_definition::e_profile
#define _profile_ribbon		0 
#define _profile_cross		1
#define _profile_ngon		2
#define _profile_type_max	3

#if DX_VERSION == 9
// Take the index from the vertex input semantic and translate it into strip, index, and offset.
void calc_strip_profile_and_offset( in int index, out int strip_index, out int buffer_index, out int offset )
{
#ifdef pc
	strip_index  = floor(index / 2);
	offset 		 = index - strip_index * 2;
	buffer_index = 0;
#else
	float verts_per_strip= g_all_state.m_num_profiles * 2;
	strip_index= floor((index + 0.5f) / verts_per_strip);
	float index_within_strip= index - strip_index * verts_per_strip;
	buffer_index= floor((index_within_strip + 0.5f) / 2);
	offset= index_within_strip - buffer_index * 2;
#endif
}
#endif

float2 strip_and_offset_to_cross_sectional_offset( int strip_index, int offset )
{
	[branch] if (g_all_state.m_profile_type== _profile_ribbon || g_all_state.m_profile_type== _profile_cross)
	{
		static float2x2 shift[2]= {{{-0.5f, 0.0f}, {0.5f, 0.0f}, }, {{0.0f, -0.5f}, {0.0f, 0.5f}, }, };
		return shift[strip_index][offset];
	}
	else //if (g_all_state.m_profile_type== _profile_ngon)
	{
		float radians= _2pi * (strip_index + offset) / g_all_state.m_ngon_sides;
		return 0.5f * float2(cos(radians), -sin(radians));	// the '-' causes inward-facing sides to be backface-culled.
	}
}

float2 profile_offset_to_texcoord( int strip_index, int offset, float cumulative_length )
{
	float v_shift; // number from -0.5f to 0.5f ranging across/around the cross-section
	[branch] if (g_all_state.m_profile_type== _profile_ribbon || g_all_state.m_profile_type== _profile_cross)
	{
		v_shift= offset - 0.5f;
	}
	else //if (g_all_state.m_profile_type== _profile_ngon)
	{
		v_shift= (strip_index + offset) / g_all_state.m_ngon_sides - 0.5f;
	}
	return float2(cumulative_length, v_shift)*g_all_state.m_uv_tiling_rate
		+float2(0.0f, 0.5f)
		+g_all_state.m_game_time*g_all_state.m_uv_scroll_rate;
}

// Plane perpendicular to beam with basis[0] horizontal in world space.
float2x3 cross_section_world_basis (float3 direction)
{
	float2x3 basis;

	float3 product = cross(direction, float3(0.0f, 0.0f, 1.0f));
	if (all(product == float3(0, 0, 0)))
	{
		basis[0]= float3(0.0f, 1.0f, 0.0f);
		basis[1]= float3(1.0f, 0.0f, 0.0f);
	}
	else
	{
		basis[0]= normalize(product);
		basis[1]= normalize(cross(basis[0], direction));
	}
	
	return basis;
}

// Plane perpendicular to beam with basis[0] parallel to screen.
float2x3 cross_section_billboard_basis (float3 position, float3 direction)
{
	float2x3 basis;

	basis[0]= normalize(cross(position - Camera_Position, direction));
	basis[1]= normalize(cross(basis[0], direction));
	
	return basis;
}

// Actual input vertex format is hard-coded in vfetches as s_profile_state
s_beam_interpolators default_vs( 
#if DX_VERSION == 11
	in uint instance_id : SV_InstanceID,
	in uint vertex_id : SV_VertexID
#else
	vertex_type vIN 
#endif
)
{
	s_beam_render_vertex OUT;

	// This would be used for killing verts by setting oPts.z!=0 .
	//asm {
	//	config VsExportMode=kill
	//};

	// Break the input index into a strip index, a profile index and an {0,1}-offset.
	int strip_index, profile_index, offset;
#if (DX_VERSION == 9) && defined(pc)
	calc_strip_profile_and_offset(vIN.index.y, strip_index, profile_index, offset);
	s_profile_state STATE= read_profile_state_from_input(vIN);
#elif DX_VERSION == 11
	strip_index = instance_id;
	profile_index = vertex_id / 2;
	offset = vertex_id & 1;
	s_profile_state STATE= read_profile_state(profile_index_to_buffer_index(profile_index));
#else
	calc_strip_profile_and_offset(vIN.index, strip_index, profile_index, offset);
	s_profile_state STATE= read_profile_state(profile_index_to_buffer_index(profile_index));
#endif

	// Compute the vertex position within the cross-sectional plane of the profile
   float2 cross_section_pos = strip_and_offset_to_cross_sectional_offset(strip_index, offset) * STATE.m_thickness;

	// Transform from cross-section plane to world space.
	float2x3 world_basis= cross_section_world_basis(g_all_state.m_direction);
	float2x3 billboard_basis= (g_all_state.m_profile_type== _profile_ribbon) ? cross_section_billboard_basis(STATE.m_position, g_all_state.m_direction) : world_basis;
	float rotation= STATE.m_rotation;
	float rotsin, rotcos;
	sincos(_2pi*rotation, rotsin, rotcos);
	float2x2 rotmat= {{rotcos, rotsin}, {-rotsin, rotcos}, };
	billboard_basis= mul(rotmat, billboard_basis);

	float3 world_pos= STATE.m_position + mul(cross_section_pos, billboard_basis) + mul(STATE.m_offset, world_basis);

	// Transform from world space to clip space. 
	OUT.m_position= mul(float4(world_pos, 1.0f), View_Projection);
	

	// Compute vertex texcoord
	OUT.m_texcoord= profile_offset_to_texcoord(strip_index, offset, length(STATE.m_percentile * g_all_state.m_capped_length));

	// Compute profile color
	OUT.m_color= STATE.m_color * STATE.m_intensity;
	IF_CATEGORY_OPTION(blend_mode, multiply)
	{
	}
	else if (BLEND_MODE_SELF_ILLUM)
	{
		OUT.m_color.xyz*= V_ILLUM_EXPOSURE;
	}
	else
	{
		OUT.m_color.xyz*= v_exposure.x;
	}
	IF_CATEGORY_OPTION(fog, on)	// fog
	{
		float3 extinction, inscatter;
		compute_scattering(Camera_Position, world_pos.xyz, extinction, inscatter);
		OUT.m_color.xyz*= extinction;
		OUT.m_color_add.xyz= inscatter * v_exposure.x;
	}
	else
	{
		OUT.m_color_add= float3(0.0f, 0.0f, 0.0f);
	}
	if (TEST_BIT(g_all_state.m_appearance_flags,_beam_origin_faded_bit))
	{
		float distance_from_origin= length(world_pos - g_all_state.m_origin);
		OUT.m_color.w*= saturate(g_all_state.m_origin_range * 
			(distance_from_origin - g_all_state.m_origin_cutoff));
	}
	if (TEST_BIT(g_all_state.m_appearance_flags,_beam_edge_faded_bit))
	{
		// Fade to transparent when profile plane is facing us ... but independent of camera orientation
		float3 profile_normal= normalize(cross(billboard_basis[0], billboard_basis[1]));
		float3 camera_to_vertex= normalize(world_pos-Camera_Position);
		float profile_angle= acos(abs(dot(camera_to_vertex, profile_normal)));
		OUT.m_color.w*= saturate(g_all_state.m_edge_range * (profile_angle - g_all_state.m_edge_cutoff));
	}

	// Compute profile black point
	OUT.m_black_point= STATE.m_black_point;
	OUT.m_palette= STATE.m_palette;

    return write_beam_interpolators(OUT);
}
#endif	//#ifdef VERTEX_SHADER

#ifdef PIXEL_SHADER
// Specialized routine for smoothly fading out profiles.  Maps
//		[0, black_point] to 0
//		[black_point, mid_point] to [0, mid_point] linearly
//		[mid_point, 1] to [mid_point, 1] by identity
// where mid_point is halfway between black_point and 1
//
//		|                   **
//		|                 **
//		|               **
//		|             **
//		|            *
//		|           *
//		|          *
//		|         *
//		|        *
//		|       *
//		|*******_____________
//      0      bp    mp      1
float remap_alpha(float black_point, float alpha)
{
	float mid_point= (black_point+1.0f)/2.0f;
	return mid_point*saturate((alpha-black_point)/(mid_point-black_point)) 
		+ saturate(alpha-mid_point);	// faster than a branch
}

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
#include "texture_xform.fx"

PARAM_SAMPLER_2D(base_map);
PARAM(float4, base_map_xform);

PARAM_SAMPLER_2D(base_map2);
PARAM(float4, base_map2_xform);

PARAM_SAMPLER_2D(palette);
PARAM_SAMPLER_2D(alpha_map);

PARAM(float, modulation_factor);
PARAM(float, alpha_modulation_factor);
PARAM(float, palette_shift_amount);
PARAM(float, depth_fade_range);

float4 sample_diffuse(float2 texcoord, float palette_v, float depth_alpha)
{
	float particle_alpha= 1.0f;

	IF_CATEGORY_OPTION(albedo, diffuse_only)
	{
		return sample2D(base_map, texcoord);
	}
	
	// Dependent texture fetch.  The palette can be any size.  In order to avoid filtering artifacts,
	// the palette should be smoothly varying, or else filtering should be turned off.
	IF_CATEGORY_OPTION(albedo, palettized)
	{
		float index= sample2D(base_map, texcoord).x;
		return sample2D(palette, float2(index, palette_v));
	}
	
	// Same as above except the alpha comes from the original texture, not the palette.
	IF_CATEGORY_OPTION(albedo, palettized_plus_alpha)
	{
		float index= sample2D(base_map, texcoord).x;
		float alpha= sample2D(alpha_map, texcoord).w;
		return float4(sample2D(palette, float2(index, palette_v)).xyz, alpha);
	}

	IF_CATEGORY_OPTION(albedo, palettized_plasma)
	{
		float noise_a=	sample2D(base_map,	transform_texcoord(texcoord, base_map_xform)).r;
		float noise_b=	sample2D(base_map2,	transform_texcoord(texcoord, base_map2_xform)).r;
		float index=	abs(noise_a - noise_b);

		float alpha=	sample2D(alpha_map, texcoord).a;

		index=	saturate(index + (1-alpha*particle_alpha*depth_alpha) * alpha_modulation_factor);

		float4 palette_value=	sample2D(palette, float2(index, palette_v));

		return float4(palette_value.rgb, alpha);
	}

	IF_CATEGORY_OPTION(albedo, palettized_2d_plasma)
	{
		float noise_a=	sample2D(base_map,	transform_texcoord(texcoord, base_map_xform)).r;
		float noise_b=	sample2D(base_map2,	transform_texcoord(texcoord, base_map2_xform)).r;
		float index=	abs(noise_a - noise_b);

		float alpha=	sample2D(alpha_map, texcoord).a;

//		IF_CATEGORY_OPTION(depth_fade, palette_shift)
//		{
//			index=	saturate(index + (1-alpha*particle_alpha) * palette_shift_amount);
//		}

		float4 palette_value=	sample2D(palette, float2(index, depth_alpha));
//		float4 palette_value=	pow(1-abs(index - (1-depth_alpha)), 20);

		return float4(palette_value.rgb, alpha);
	}
}

//float compute_depth_fade(float2 screen_coords, float depth, float range)
//{
//#if (DX_VERSION == 9)
//	if ((TEST_CATEGORY_OPTION(depth_fade, on) || TEST_CATEGORY_OPTION(depth_fade, palette_shift)) && !TEST_CATEGORY_OPTION(blend_mode, opaque))
//	{
//		float2 screen_texcoord= (screen_coords.xy + float2(0.5f, 0.5f)) / texture_size.xy;
//		float scene_depth= sample2D(depth_buffer, screen_texcoord).x;
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

typedef accum_pixel s_beam_render_pixel_out;
s_beam_render_pixel_out default_ps(s_beam_interpolators INTERPOLATORS)
{
	s_beam_render_vertex IN= read_beam_interpolators(INTERPOLATORS);

	//float depth_fade=	compute_depth_fade(screen_coords, IN.m_depth, depth_fade_range);
	float depth_fade = 1.0f;

	float4 blended= sample_diffuse(IN.m_texcoord, IN.m_palette, depth_fade);
	
	//blended.w *= depth_fade;

	IF_CATEGORY_OPTION(black_point, on)
	{
		blended.w= remap_alpha(IN.m_black_point, blended.w);
	}
	
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

	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(blended, false, false, 0.0f);
}
#endif	//#ifdef PIXEL_SHADER
