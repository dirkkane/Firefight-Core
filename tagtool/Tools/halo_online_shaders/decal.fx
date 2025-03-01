/*
DECAL.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
04/12/2006 13:36 davcook	
*/

#include "global.fx"
#include "decal_registers.fx"

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
#ifndef category_albedo
CATEGORY_PARAM(category_albedo);
#endif
#ifndef category_blend_mode
CATEGORY_PARAM(category_blend_mode);
#endif
#ifndef category_render_pass
CATEGORY_PARAM(category_render_pass);
#endif
#ifndef category_specular
CATEGORY_PARAM(category_specular);
#endif
#ifndef category_bump_mapping
CATEGORY_PARAM(category_bump_mapping);
#endif
#ifndef category_tinting
CATEGORY_PARAM(category_tinting);
#endif

// We set the sampler address mode to black border in the render_method_option.  That guarantees no effect
// for most blend modes, but not all.  For the other modes, we do a pixel kill.
#define BLACK_BORDER_INSUFFICIENT (TEST_CATEGORY_OPTION(blend_mode, opaque) \
|| TEST_CATEGORY_OPTION(blend_mode, multiply)								\
|| TEST_CATEGORY_OPTION(blend_mode, double_multiply)						\
|| TEST_CATEGORY_OPTION(blend_mode, inv_alpha_blend))						\

// Even with this turned on, we get z-fighting, because the decal is not guaranteed to list the
// verts in the same order as the underlying mesh
#undef REPRODUCIBLE_Z

#include "hlsl_vertex_types.fx"
#include "hlsl_constant_persist.fx"
#include "hlsl_constant_oneshot.fx"
#include "deform.fx"
#include "blend.fx"
#include "player_emblem.fx"
//#include "clip_plane.fx"

#ifdef VERTEX_SHADER
#define IS_FLAT_VERTEX (IS_VERTEX_TYPE(s_flat_world_vertex) || IS_VERTEX_TYPE(s_flat_rigid_vertex) || IS_VERTEX_TYPE(s_flat_skinned_vertex))
#else
#define IS_FLAT_VERTEX TEST_CATEGORY_OPTION(bump_mapping, leave)
#endif

#define BLEND_MODE_SELF_ILLUM (TEST_CATEGORY_OPTION(blend_mode, additive) || TEST_CATEGORY_OPTION(blend_mode, add_src_times_srcalpha))

PARAM(float, u_tiles);
PARAM(float, v_tiles);

struct s_decal_interpolators
{
	float4 m_position	:SV_Position;
#if DX_VERSION == 11
	float m_clip_distance : SV_ClipDistance;
#endif
	float4 m_texcoord	:TEXCOORD0;
	float  m_pos_w :TEXCOORD1;
#if !IS_FLAT_VERTEX
	float3 m_tangent	:TEXCOORD2;	
	float3 m_binormal	:TEXCOORD3;	
	float3 m_normal		:TEXCOORD4;
#endif
};

s_decal_interpolators default_vs( vertex_type IN )
{
	s_decal_interpolators OUT;

	float4 local_to_world_transform[3];
	always_local_to_view(IN, local_to_world_transform, OUT.m_position);

	// Record both the normalized and sprite texcoord, for use in pixel kill and tfetch
	if (pixel_kill_enabled)
	{
		OUT.m_texcoord= float4(IN.texcoord, IN.texcoord * sprite.zw + sprite.xy);
	}
	else
	{
		OUT.m_texcoord= float4(0.5f, 0.5f, IN.texcoord * sprite.zw + sprite.xy);
	}
	
	OUT.m_texcoord.zw*= float2(u_tiles, v_tiles);
	OUT.m_pos_w = OUT.m_position.w;
	
#if !IS_FLAT_VERTEX
	OUT.m_normal= IN.normal;	// currently, decals are always in world space
	OUT.m_tangent= IN.tangent;
	OUT.m_binormal= IN.binormal;
#endif

#if DX_VERSION == 11
	OUT.m_clip_distance = dot(OUT.m_position, v_clip_plane);
#endif
	
	return OUT;
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

PARAM_SAMPLER_2D(base_map);
PARAM_SAMPLER_2D(alpha_map);
PARAM_SAMPLER_2D(palette);

// Don't apply gamma twice!  This should really be taken care of in render_target.fx . 
#if TEST_CATEGORY_OPTION(blend_mode, multiply) || TEST_CATEGORY_OPTION(blend_mode, double_multiply)
#define LDR_gamma2 false
#define HDR_gamma2 false
#endif

#define BLEND_MODE_USES_SRC_ALPHA (!(						\
	TEST_CATEGORY_OPTION(blend_mode, opaque) ||				\
	TEST_CATEGORY_OPTION(blend_mode, additive) ||			\
	TEST_CATEGORY_OPTION(blend_mode, multiply) ||			\
	TEST_CATEGORY_OPTION(blend_mode, double_multiply) ||	\
	TEST_CATEGORY_OPTION(blend_mode, maximum) ||			\
	TEST_CATEGORY_OPTION(blend_mode, multiply_add)			\
))

#include "albedo_pass.fx"
#include "render_target.fx"
#include "bump_mapping.fx"

#define RENDER_TARGET_ALBEDO_ONLY			0
#define RENDER_TARGET_ALBEDO_AND_NORMAL		1
#define RENDER_TARGET_LIGHTING				2

#if TEST_CATEGORY_OPTION(render_pass, post_lighting)
#define RENDER_TARGET_TYPE RENDER_TARGET_LIGHTING
#elif !TEST_CATEGORY_OPTION(bump_mapping, leave)
#define RENDER_TARGET_TYPE RENDER_TARGET_ALBEDO_AND_NORMAL
#else
#define RENDER_TARGET_TYPE RENDER_TARGET_ALBEDO_ONLY
#endif

PARAM_SAMPLER_2D(vector_map);
PARAM(float, antialias_tweak);
PARAM(float, vector_sharpness);
PARAM_SAMPLER_2D(shadow_vector_map);
PARAM(float4, shadow_vector_map_xform);
PARAM(float, shadow_offset_u);
PARAM(float, shadow_offset_v);
PARAM(float, shadow_darkness);
PARAM(float, shadow_sharpness);
PARAM(float4, base_map_xform);

PARAM_SAMPLER_2D(change_color_map);
PARAM(float3, primary_change_color);
PARAM(float3, secondary_change_color);
PARAM(float3, tertiary_change_color);
	
float4 get_gradients_pc(in float2 value)
{
    float2 x_gradient = ddx(value);
    float2 y_gradient = ddy(value);
    return float4(x_gradient.x, y_gradient.x, x_gradient.y, y_gradient.y);
}

float4 sample_diffuse(float2 texcoord_tile, float2 texcoord, float palette_v)
{
	IF_CATEGORY_OPTION(albedo, diffuse_only)
	{
		return sample2D(base_map, texcoord);
	}
	
	// Same as above except the alpha comes from a separate texture.
	IF_CATEGORY_OPTION(albedo, diffuse_plus_alpha)
	{
		return float4(sample2D(base_map, texcoord).xyz, sample2D(alpha_map, texcoord).w);
	}
	
	// Same as above except the alpha is always a single tile even if the decal is a sprite, or tiled.
	IF_CATEGORY_OPTION(albedo, diffuse_plus_alpha_mask)
	{
		return float4(sample2D(base_map, texcoord).xyz, sample2D(alpha_map, texcoord_tile).w);
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
	
	// Same as above except the alpha is always a single tile even if the decal is a sprite, or tiled.
	IF_CATEGORY_OPTION(albedo, palettized_plus_alpha_mask)
	{
		float index= sample2D(base_map, texcoord).x;
		float alpha= sample2D(alpha_map, texcoord_tile).w;
		return float4(sample2D(palette, float2(index, palette_v)).xyz, alpha);
	}
	
	IF_CATEGORY_OPTION(albedo, emblem_change_color)
	{
		//return generate_emblem_pixel(texcoord);
        return sample2D(tex0_sampler, texcoord);
	}

	IF_CATEGORY_OPTION(albedo, change_color)
	{
		float4 change_color= sample2D(change_color_map, texcoord);

		change_color.xyz=	((1.0f-change_color.x) + change_color.x*primary_change_color.xyz)	*
							((1.0f-change_color.y) + change_color.y*secondary_change_color.xyz)	*
							((1.0f-change_color.z) + change_color.z*tertiary_change_color.xyz);

		return change_color;
	}

#ifdef category_albedo_option_vector_alpha
	IF_CATEGORY_OPTION(albedo, vector_alpha)
	{
		float3 color=				sample2D(base_map, transform_texcoord(texcoord, base_map_xform)).rgb;
		float  vector_distance=		sample2D(vector_map, texcoord).g;
		
		float scale= antialias_tweak;
#ifdef pc
		#ifndef APPLY_FIXES
		scale /= 0.001f;
		#else
		float4 gradients = get_gradients_pc(texcoord.xy);
		scale /= sqrt(dot(gradients.xyzw, gradients.xyzw));
		#endif
#else // !pc
		float4 gradients;
		asm {
			getGradients gradients, texcoord, vector_map
		};
		scale /= sqrt(dot(gradients.xyzw, gradients.xyzw));
#endif // !pc
		scale= max(scale, 1.0f);		// scales smaller than 1.0 result in '100% transparent' areas appearing as semi-opaque

		float vector_alpha= saturate((vector_distance - 0.5f) * min(scale, vector_sharpness) + 0.5f);

		return float4(color * vector_alpha, vector_alpha);
	}	
#endif

#ifdef category_albedo_option_vector_alpha_drop_shadow
	IF_CATEGORY_OPTION(albedo, vector_alpha_drop_shadow)
	{
		float vector_distance=		sample2D(vector_map, texcoord).g;
		float shadow_distance=		sample2D(shadow_vector_map, transform_texcoord(texcoord, shadow_vector_map_xform)).g;
		
		float scale= antialias_tweak;
#ifdef pc
		#ifndef APPLY_FIXES
		scale /= 0.001f;
		#else
		float4 gradients = get_gradients_pc(texcoord.xy);
		scale /= sqrt(dot(gradients.xyzw, gradients.xyzw));
		#endif
#else // !pc
		float4 gradients;
		asm {
			getGradients gradients, texcoord, vector_map
		};
		scale /= sqrt(dot(gradients.xyzw, gradients.xyzw));
#endif // !pc
		scale= max(scale, 1.0f);		// scales smaller than 1.0 result in '100% transparent' areas appearing as semi-opaque

		float shadow_alpha= saturate((shadow_distance - 0.5f) * min(scale, shadow_sharpness) + 0.5f) * shadow_darkness;
		float vector_alpha= saturate((vector_distance - 0.5f) * min(scale, vector_sharpness) + 0.5f);

		{
#ifndef pc
			[isolate]
#endif // !pc
			float3 color=				sample2D(base_map,	  transform_texcoord(texcoord, base_map_xform)).rgb;
			return float4(color * vector_alpha, vector_alpha + shadow_alpha);
		}
	}	
#endif

}

float3x3 tangent_frame(s_decal_interpolators IN)
{
#if IS_FLAT_VERTEX
	return 0.0f;
#else
	return float3x3(IN.m_tangent, IN.m_binormal, IN.m_normal);
#endif
}

float3 sample_bump(float2 texcoord_tile, float2 texcoord, float3x3 tangent_frame)
{
	float3 bump_normal;
	float3 unused= {0.0f, 0.0f, 0.0f};
	
	IF_CATEGORY_OPTION(bump_mapping, leave)
	{
		calc_bumpmap_off_ps(texcoord, unused, tangent_frame, bump_normal);
	}
	
	IF_CATEGORY_OPTION(bump_mapping, standard)
	{
		calc_bumpmap_default_ps(texcoord, unused, tangent_frame, bump_normal);
	}
	
	IF_CATEGORY_OPTION(bump_mapping, standard_mask)
	{
		calc_bumpmap_default_ps(texcoord_tile, unused, tangent_frame, bump_normal);
	}
	
	return bump_normal;
}

PARAM(float4, tint_color);
PARAM(float, intensity);
PARAM(float, modulation_factor);

void tint_and_modulate(inout float4 diffuse)
{
	float4 tint_color_internal= 1.0f;
	float intensity_internal= 1.0f;
	float modulation_factor_internal= 0.0f;

	IF_CATEGORY_OPTION(tinting, none)
	{
	}
	else 
	{
		tint_color_internal= tint_color;
		intensity_internal= intensity;
		IF_CATEGORY_OPTION(tinting, unmodulated)
		{
		}
		else IF_CATEGORY_OPTION(tinting, fully_modulated)
		{
			modulation_factor_internal= 1.0f;
		}
		else IF_CATEGORY_OPTION(tinting, partially_modulated)
		{
			modulation_factor_internal= modulation_factor;
		}
	}
	
	const static float recip_sqrt_3= 1.0f / 1.7320508f;
	float Y= recip_sqrt_3 * length(diffuse.xyz);
	diffuse.xyz*= lerp(tint_color_internal.xyz, 1.0f, modulation_factor_internal * Y) * intensity_internal;
	
	IF_CATEGORY_OPTION(render_pass, post_lighting)
	{
		IF_CATEGORY_OPTION(blend_mode, multiply)
		{
		}
		else IF_CATEGORY_OPTION(blend_mode, double_multiply)
		{
		}
		else if (BLEND_MODE_SELF_ILLUM)
		{
			diffuse.xyz*= ILLUM_EXPOSURE;
		}
		else
		{
			diffuse.xyz*= g_exposure.x;
		}		
	}
}

// fade out ... cover a few of the common blend modes
void fade_out(inout float4 color)
{
	IF_CATEGORY_OPTION(blend_mode, additive)
	{
		color.xyz*= fade;
	}
	else IF_CATEGORY_OPTION(blend_mode, multiply)
	{
		color.xyz= lerp(1.0f, color.xyz, fade.x);
	}
	else IF_CATEGORY_OPTION(blend_mode, double_multiply)
	{
		color.xyz= lerp(0.5f, color.xyz, fade.x);
	}
	
	// bump and specular needs an alpha even if diffuse doesn't
	if (!IS_FLAT_VERTEX || !TEST_CATEGORY_OPTION(specular, leave) || BLEND_MODE_USES_SRC_ALPHA)
	{
		color.w *= fade.x;
	}
	
	IF_CATEGORY_OPTION(blend_mode, pre_multiplied_alpha)
	{
#if defined(category_albedo_option_vector_alpha_drop_shadow) || defined (category_albedo_option_vector_alpha)
		IF_CATEGORY_OPTION(albedo, vector_alpha_drop_shadow)
		{
		}
		else IF_CATEGORY_OPTION(albedo, vector_alpha)
		{
		}
		else
#endif
		{
			color.xyz *= color.w;
		}
		color.xyz *= fade.x;
	}
}

#if (RENDER_TARGET_TYPE== RENDER_TARGET_LIGHTING)
typedef accum_pixel s_decal_render_pixel_out;
#elif (RENDER_TARGET_TYPE== RENDER_TARGET_ALBEDO_AND_NORMAL)
typedef albedo_pixel s_decal_render_pixel_out;
#else	//if (RENDER_TARGET_TYPE RENDER_TARGET_ALBEDO_ONLY)
struct s_decal_render_pixel_out
{
	float4 m_color0:	SV_Target0;
};
#endif

s_decal_render_pixel_out convert_to_decal_target(float4 color, float3 normal, float pos_w, float3 geo_normal)
{
	s_decal_render_pixel_out OUT;
	
#if (RENDER_TARGET_TYPE== RENDER_TARGET_LIGHTING)
	OUT= CONVERT_TO_RENDER_TARGET_FOR_BLEND(color, false, false, 0.0f);
#elif (RENDER_TARGET_TYPE== RENDER_TARGET_ALBEDO_AND_NORMAL)
	OUT= convert_to_albedo_target_no_srgb(color, normal, pos_w, geo_normal);
#else	//if (RENDER_TARGET_TYPE RENDER_TARGET_ALBEDO_ONLY)
	OUT.m_color0= color;
#endif
	
	return OUT;
}

#ifndef pc
// This removes the tangent space interpolators if we're not bump mapping.
// It gives us 63 ALU threads instead of 48 for the simplest decals.
// It will cause vertex shader patching, but I think it's worth it.
// No longer needed now that we split into flat and regular vertex types.
//[removeUnusedInputs]
// This keeps the GPR count down to the max number of interpolators, because 
// we want more ALU threads.  Hasn't helped in tests.
//[reduceTempRegUsage(5)]	
#endif
s_decal_render_pixel_out default_ps(s_decal_interpolators IN)
{
	if (true /*pixel_kill_enabled*/)	// debug render has a performace impact, so moving this to vertex shader
	{
		// This block translates to 2 ALU instructions with no branches.
		// In some cases we can use the built in border address mode instead (see BLACK_BORDER_INSUFFICIENT)
		clip(float4(IN.m_texcoord.xy, 1.0f-IN.m_texcoord.xy));
	}

	float4 diffuse= sample_diffuse(IN.m_texcoord.xy, IN.m_texcoord.zw, 0.0f);
	tint_and_modulate(diffuse);
	fade_out(diffuse);

	float3x3 tangent_framev = tangent_frame(IN);
	float3 bump= sample_bump(IN.m_texcoord.xy, IN.m_texcoord.zw, tangent_framev);
	
	return convert_to_decal_target(diffuse, bump, IN.m_pos_w, tangent_framev[2]);
}