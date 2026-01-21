#ifdef disable_register_reorder
// magic pragma given to us by the DX10 team
// to disable the register reordering pass that was
// causing a lot of pain on the PC side of the compiler
// with this pragma we get a massive speedup on compile times
// on the PC side
#pragma ruledisable 0x0a0c0101
#endif // #ifdef disable_register_reorder

#define LDR_ONLY
#define LDR_ALPHA_ADJUST	(1.0f / 32.0f)
#define LDR_gamma2			false

#include "bump_mapping_util.fx"
#include "global.fx"
#include "texture_xform.fx"
#include "hlsl_vertex_types.fx"
#include "render_target.fx"
#include "blend.fx"

#ifdef VERTEX_SHADER
	#define VERTEX_CONSTANT(type, name, register_index)   type name : register(register_index)
	#define PIXEL_CONSTANT(type, name, register_index)   type name
#else
	#define VERTEX_CONSTANT(type, name, register_index)   type name
	#define PIXEL_CONSTANT(type, name, register_index)   type name : register(register_index)
#endif

VERTEX_CONSTANT(float4, pixelspace_xform,			c250);
VERTEX_CONSTANT(float4, screenspace_sampler_xform,	c251);
PIXEL_CONSTANT(float4,  screenspace_xform,			c200);

#undef LDR_gamma2
#include "hlsl_constant_mapping.fx"


void default_vs(
	in vertex_type vertex,
	out float4 position : POSITION,
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

#define CALC_WARP(type) calc_warp_##type

sampler2D	warp_map;
float4		warp_map_xform;
float		warp_amount;

float4 calc_warp_none(in float4 original_texcoord)
{
	return original_texcoord;
}

float4 calc_warp_pixel_space(in float4 original_texcoord)
{
	#ifdef APPLY_FIXES
	float2 warp=	BUMP_CONVERT(tex2D(warp_map,	transform_texcoord(original_texcoord.zw, warp_map_xform)).xy);
	#else
	float2 warp=	tex2D(warp_map,	transform_texcoord(original_texcoord.zw, warp_map_xform)).xy;
	#endif
	original_texcoord.zw += warp * warp_amount;
	return original_texcoord;
}

float4 calc_warp_screen_space(in float4 original_texcoord)
{
	#ifdef APPLY_FIXES
	float2 warp=	BUMP_CONVERT(tex2D(warp_map,	transform_texcoord(original_texcoord.xy, warp_map_xform)).xy);
	#else
	float2 warp=	tex2D(warp_map,	transform_texcoord(original_texcoord.xy, warp_map_xform)).xy;
	#endif
	warp = warp.xy * warp_amount;
	original_texcoord.xy += warp;
	
	warp /= screenspace_xform.xy; 
	original_texcoord.zw += warp;

	return original_texcoord;
}

#define CALC_BASE(type) calc_base_##type

sampler2D	base_map;
float4		base_map_xform;
sampler2D	detail_map;
float4		detail_map_xform;

float4 calc_base_single_screen_space(in float4 texcoord)
{
	float4	base=	tex2D(base_map, transform_texcoord(texcoord.xy, base_map_xform));
	return	base;
}

float4 calc_base_single_pixel_space(in float4 texcoord)
{
	float4	base=	tex2D(base_map,   transform_texcoord(texcoord.zw, base_map_xform));
	return	base;
}



#define CALC_OVERLAY(type, stage) calc_overlay_##type(color, texcoord, detail_map_##stage, detail_map_##stage##_xform, detail_mask_##stage, detail_mask_##stage##_xform, detail_fade_##stage, detail_multiplier_##stage)

float4		tint_color;
float4		add_color;
sampler2D	detail_map_a;
float4		detail_map_a_xform;
sampler2D	detail_mask_a;
float4		detail_mask_a_xform;
float		detail_fade_a;
float		detail_multiplier_a;
sampler2D	detail_map_b;
float4		detail_map_b_xform;
sampler2D	detail_mask_b;
float4		detail_mask_b_xform;
float		detail_fade_b;
float		detail_multiplier_b;

float4 calc_overlay_none(in float4 color, in float4 texcoord, sampler2D detail_map, in float4 detail_map_xform, sampler2D detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	return color;
}

float4 calc_overlay_tint_add_color(in float4 color, in float4 texcoord, sampler2D detail_map, in float4 detail_map_xform, sampler2D detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	return color * tint_color + add_color;
}

float4 calc_overlay_detail_screen_space(in float4 color, in float4 texcoord, sampler2D detail_map, in float4 detail_map_xform, sampler2D detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	// We need to sample this with the 0..1 coordinates so always use zw components (these untransformed & warped)
	float4 detail=	tex2D(detail_map, transform_texcoord(texcoord.xy, detail_map_xform));
	detail.rgb *= detail_multiplier;
	detail=	lerp(1.0f, detail, detail_fade);
	return color * detail;
}

float4 calc_overlay_detail_pixel_space(in float4 color, in float4 texcoord, sampler2D detail_map, in float4 detail_map_xform, sampler2D detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	float4 result=	color * tex2D(detail_map, transform_texcoord(texcoord.zw, detail_map_xform));
	result.rgb *= detail_multiplier;
	return result;

}

float4 calc_overlay_detail_masked_screen_space(in float4 color, in float4 texcoord, sampler2D detail_map, in float4 detail_map_xform, sampler2D detail_mask_map, in float4 detail_mask_map_xform, in float detail_fade, in float detail_multiplier)
{
	float4 detail=			tex2D(detail_map, transform_texcoord(texcoord.xy, detail_map_xform));
	detail.rgb *= detail_multiplier;
	float4 detail_mask=		tex2D(detail_mask_map, transform_texcoord(texcoord.xy, detail_mask_map_xform));
	detail=	lerp(1.0f, detail, saturate(detail_fade*detail_mask.a));
	return color * detail;

}


float fade;

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


accum_pixel default_ps(
	in float4 original_texcoord : TEXCOORD0)
{
	float4 texcoord= CALC_WARP(warp_type)(original_texcoord);
	
	float4 color =   CALC_BASE(base_type)(texcoord);
	color=			 CALC_OVERLAY(overlay_a_type, a);
	color=			 CALC_OVERLAY(overlay_b_type, b);
	
	color=			 calc_fade_out(color);
	
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(color, false, false);
}
