#ifdef disable_register_reorder
// magic pragma given to us by the DX10 team
// to disable the register reordering pass that was
// causing a lot of pain on the PC side of the compiler
// with this pragma we get a massive speedup on compile times
// on the PC side
#pragma ruledisable 0x0a0c0101
#endif // #ifdef disable_register_reorder

#define LDR_ONLY
#ifdef xenon
#define LDR_ALPHA_ADJUST	(1.0f / 32.0f)
#else
#define LDR_ALPHA_ADJUST	1.0f
#endif
#define LDR_gamma2			false

#include "global.fx"
#include "texture_xform.fx"
#include "hlsl_vertex_types.fx"
#include "render_target.fx"
#include "blend.fx"

#include "screen_registers.fx"

#undef LDR_gamma2
#include "hlsl_constant_mapping.fx"


void default_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	out float4 texcoord : TEXCOORD0)
{
	position.xy= vertex.position;
	position.zw= 1.0f;
	texcoord.xy= transform_texcoord(vertex.texcoord, screenspace_sampler_xform); 
	
	// Disable pixel space for now as it isn't workinging transform_texcoord(texcoord.xy, pixelspace_xform). Note that I didn't remove
	// pixel space at this point in time in order to minimize changes (this one would affect actuall render method definitions and tags). 
	// Ideally render method definition needs to be modified to remove pixel space transforms all together. For now, just hijacking it. 
	texcoord.zw= vertex.texcoord; 
}

void albedo_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	out float4 texcoord : TEXCOORD0)
{
	default_vs(vertex, position, texcoord);
}

#define CALC_WARP(type) calc_warp_##type

PARAM_SAMPLER_2D(warp_map);
PARAM(float4, warp_map_xform);
PARAM(float, warp_amount);

float4 calc_warp_none(in float4 original_texcoord)
{
	return original_texcoord;
}

float4 calc_warp_pixel_space(in float4 original_texcoord)
{
	float2 warp=	sample2D(warp_map,	transform_texcoord(original_texcoord.zw, warp_map_xform)).xy;
	original_texcoord.zw += warp * warp_amount;
	return original_texcoord;
}

float4 calc_warp_screen_space(in float4 original_texcoord)
{
	float2 warp=	sample2D(warp_map,	transform_texcoord(original_texcoord.xy, warp_map_xform)).xy;
	warp = warp.xy * warp_amount;
	original_texcoord.xy += warp;
	
	warp /= screenspace_xform.xy; 
	original_texcoord.zw += warp;

	return original_texcoord;
}

#define CALC_BASE(type) calc_base_##type

PARAM_SAMPLER_2D(base_map);
PARAM(float4, base_map_xform);
PARAM_SAMPLER_2D(detail_map);
PARAM(float4, detail_map_xform);

float2 inv_transform_texcoord(in float2 texcoord, in float4 xform)
{
	return (texcoord - xform.zw) / xform.xy;
}

float4 calc_base_single_screen_space(in float4 texcoord, in bool is_screenshot)
{
	float2 uv = transform_texcoord(texcoord.xy, base_map_xform);
	if (is_screenshot)
	{
		uv = inv_transform_texcoord(uv, screenspace_xform);
	}

	float4	base=	sample2D(base_map, uv);
	return	base;
}

float4 calc_base_single_pixel_space(in float4 texcoord, in bool is_screenshot)
{
	float4	base=	sample2D(base_map,   transform_texcoord(texcoord.zw, base_map_xform));
	return	base;
}



#define CALC_OVERLAY(type, stage) calc_overlay_##type(color, texcoord, detail_map_##stage, detail_map_##stage##_xform, detail_mask_##stage, detail_mask_##stage##_xform, detail_fade_##stage, detail_multiplier_##stage)

PARAM(float4, tint_color);
PARAM(float4, add_color);
PARAM_SAMPLER_2D(detail_map_a);
PARAM(float4, detail_map_a_xform);
PARAM_SAMPLER_2D(detail_mask_a);
PARAM(float4, detail_mask_a_xform);
PARAM(float, detail_fade_a);
PARAM(float, detail_multiplier_a);
PARAM_SAMPLER_2D(detail_map_b);
PARAM(float4, detail_map_b_xform);
PARAM_SAMPLER_2D(detail_mask_b);
PARAM(float4, detail_mask_b_xform);
PARAM(float, detail_fade_b);
PARAM(float, detail_multiplier_b);

float4 calc_overlay_none(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform, texture_sampler_2d detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	return color;
}

float4 calc_overlay_tint_add_color(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform, texture_sampler_2d detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	return color * tint_color + add_color;
}

float4 calc_overlay_detail_screen_space(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform, texture_sampler_2d detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	// We need to sample this with the 0..1 coordinates so always use zw components (these untransformed & warped)
	float4 detail=	sample2D(detail_map, transform_texcoord(texcoord.xy, detail_map_xform));
	detail.rgb *= detail_multiplier;
	detail=	lerp(1.0f, detail, detail_fade);
	return color * detail;
}

float4 calc_overlay_detail_pixel_space(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform, texture_sampler_2d detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	float4 result=	color * sample2D(detail_map, transform_texcoord(texcoord.zw, detail_map_xform));
	result.rgb *= detail_multiplier;
	return result;

}

float4 calc_overlay_detail_masked_screen_space(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform, texture_sampler_2d detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	float4 detail=			sample2D(detail_map, transform_texcoord(texcoord.xy, detail_map_xform));
	detail.rgb *= detail_multiplier;
	float4 detail_mask=		sample2D(detail_mask_map, transform_texcoord(texcoord.xy, detail_mask_map_xform));
	detail=	lerp(1.0f, detail, saturate(detail_fade*detail_mask.a));
	return color * detail;

}


PARAM(float, fade);

float4 calc_fade_out(in float4 color)
{
	float4 alpha_fade=	float4(fade, 1.0f - fade, 0.5f - 0.5f * fade, 0.0f);

#if BLEND_MODE(opaque)	
#elif BLEND_MODE(additive)
	color.rgba *=	alpha_fade.x;
#elif BLEND_MODE(multiply)
	color.rgba=		color.rgba * alpha_fade.x + alpha_fade.y;
#elif BLEND_MODE(alpha_blend)
	color.a *=		alpha_fade.x;
#elif BLEND_MODE(double_multiply)
	color.rgba=		color.rgba * alpha_fade.x + alpha_fade.z;
#elif BLEND_MODE(pre_multiplied_alpha)
	color.rgba	*=	alpha_fade.x;
	color.a		+=	alpha_fade.y;
#endif
	return color;
}

accum_pixel pixel_shader(
	SCREEN_POSITION_INPUT(screen_position),
	in float4 original_texcoord,
	in bool is_screenshot)
{
	float4 texcoord= CALC_WARP(warp_type)(original_texcoord);
	
	float4 color =   CALC_BASE(base_type)(texcoord, is_screenshot);
	color=			 CALC_OVERLAY(overlay_a_type, a);
	color=			 CALC_OVERLAY(overlay_b_type, b);
	
	color=			 calc_fade_out(color);
	
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(color, false, false);
}

accum_pixel default_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float4 original_texcoord : TEXCOORD0)
{
	return pixel_shader(screen_position, original_texcoord, false);
}

accum_pixel albedo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float4 original_texcoord : TEXCOORD0)
{
	return pixel_shader(screen_position, original_texcoord, true);
}