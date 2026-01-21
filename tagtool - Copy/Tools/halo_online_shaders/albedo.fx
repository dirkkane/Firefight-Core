
#include "entry.fx"

#define DETAIL_MULTIPLIER 4.59479f
// 4.59479f == 2 ^ 2.2  (sRGB gamma)

#define ALBEDO_DEFINED 1
#define ALBEDO_TYPE(albedo_option) ALBEDO_TYPE_##albedo_option

#define ALBEDO_TYPE_calc_albedo_default_ps										101
#define ALBEDO_TYPE_calc_albedo_detail_blend_ps									102
#define ALBEDO_TYPE_calc_albedo_constant_color_ps								103
#define ALBEDO_TYPE_calc_albedo_two_change_color_ps								104
#define ALBEDO_TYPE_calc_albedo_four_change_color_ps							105
#define ALBEDO_TYPE_calc_albedo_three_detail_blend_ps							106
#define ALBEDO_TYPE_calc_albedo_two_detail_overlay_ps							107
#define ALBEDO_TYPE_calc_albedo_two_detail_ps									108
#define ALBEDO_TYPE_calc_albedo_color_mask_ps									109
#define ALBEDO_TYPE_calc_albedo_two_detail_black_point_ps						110
#define ALBEDO_TYPE_calc_albedo_two_change_color_anim_ps						111
#define ALBEDO_TYPE_calc_albedo_chameleon_ps									112
#define ALBEDO_TYPE_calc_albedo_two_change_color_chameleon_ps					113
#define ALBEDO_TYPE_calc_albedo_chameleon_masked_ps								114
#define ALBEDO_TYPE_calc_albedo_color_mask_hard_light_ps						115
#define ALBEDO_TYPE_calc_albedo_four_change_color_applying_to_specular_ps		116
#define ALBEDO_TYPE_calc_albedo_simple_ps										117
#define ALBEDO_TYPE_calc_albedo_two_change_color_tex_overlay_ps					118
#define ALBEDO_TYPE_calc_albedo_chameleon_albedo_masked_ps						119
#define ALBEDO_TYPE_calc_albedo_custom_cube_ps									120
#define ALBEDO_TYPE_calc_albedo_two_color_ps									121
#define ALBEDO_TYPE_calc_albedo_emblem_ps										122

PARAM(float, blend_alpha);
PARAM(float4, albedo_color);
PARAM(float4, albedo_color2);		// used for color-mask
PARAM(float4, albedo_color3);

PARAM_SAMPLER_2D(base_map);
PARAM(float4, base_map_xform);
PARAM_SAMPLER_2D(detail_map);
PARAM(float4, detail_map_xform);

#ifdef pc
PARAM(float4, debug_tint);
#endif // pc

float3 calc_pc_albedo_lighting(
	in float3 albedo,
	in float3 normal)
{
	float3 light_direction1= float3(0.68f, 0.48f, -0.6f);
	float3 light_direction2= float3(-0.3f, -0.7f, -0.6f);
	
	float3 light_color1= float3(1.2f, 1.2f, 1.2f);
	float3 light_color2= float3(0.5f, 0.5f, 0.5f);
	float3 light_color3= float3(0.7f, 0.7f, 0.7f);
	float3 light_color4= float3(0.4f, 0.4f, 0.4f);
	
	float3 n_dot_l;
	
	n_dot_l= saturate(dot(normal, light_direction1))*light_color1;
	n_dot_l+= saturate(dot(normal, -light_direction1))*light_color2;
	n_dot_l+= saturate(dot(normal, light_direction2))*light_color3;
	n_dot_l+= saturate(dot(normal, -light_direction2))*light_color4;

	return(n_dot_l*albedo);
}

float3 srgb_de_gamma (float3 Csrgb)
{
   return (Csrgb<=0.04045f) ? (Csrgb/12.92f) : pow((Csrgb + 0.055f)/1.055f, 2.4f);
}
float3 srgb_gamma  (float3 Clinear)
{
   return (Clinear<=.0031308f) ? (12.92f * Clinear) : (1.055f * pow(Clinear,1.f/2.4f)) - 0.055f;
}


void apply_pc_albedo_modifier(
	inout float4 albedo,
	in float3 normal)
{
#ifdef pc
	albedo.rgb= lerp(albedo.rgb, debug_tint.rgb, debug_tint.a);
	
	//if (p_shader_pc_albedo_lighting!=0.f)
	//{
	//	albedo.xyz= calc_pc_albedo_lighting(albedo.xyz, normal);
	//}
	// apply gamma correction by hand on PC to color target only
//	albedo.rgb= srgb_gamma(albedo.rgb);
#endif // pc
}

void calc_albedo_constant_color_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	albedo= albedo_color;
	
	apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_simple_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
    float4 base= sample2D(base_map, transform_texcoord(texcoord, base_map_xform));
    albedo.rgba= base.rgba*albedo_color.rgba;

    apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_default_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base=	sample2D(base_map,   transform_texcoord(texcoord, base_map_xform));
	float4	detail=	sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));

	albedo.rgb= base.rgb * (detail.rgb * DETAIL_MULTIPLIER) * albedo_color.rgb;
	albedo.w= base.w*detail.w*albedo_color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(detail_map2);
PARAM(float4, detail_map2_xform);

void calc_albedo_detail_blend_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base=	sample2D(base_map,		transform_texcoord(texcoord, base_map_xform));
	#ifdef APPLY_FIXES
	base.w= saturate(base.w*blend_alpha);
	#endif
	
	float4	detail=	sample2D(detail_map,	transform_texcoord(texcoord, detail_map_xform));	
	float4	detail2= sample2D(detail_map2,	transform_texcoord(texcoord, detail_map2_xform));

	albedo.xyz= (1.0f-base.w)*detail.xyz + base.w*detail2.xyz;
	albedo.xyz= DETAIL_MULTIPLIER * base.xyz*albedo.xyz;
	albedo.w= (1.0f-base.w)*detail.w + base.w*detail2.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(detail_map3);
PARAM(float4, detail_map3_xform);

void calc_albedo_three_detail_blend_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base=	sample2D(base_map,		transform_texcoord(texcoord, base_map_xform));
	#ifdef APPLY_FIXES
	base.w= saturate(base.w*blend_alpha);
	#endif
	
	float4 detail1= sample2D(detail_map,	transform_texcoord(texcoord, detail_map_xform));
	float4 detail2= sample2D(detail_map2,	transform_texcoord(texcoord, detail_map2_xform));
	float4 detail3= sample2D(detail_map3,	transform_texcoord(texcoord, detail_map3_xform));

	float blend1= saturate(2.0f*base.w);
	float blend2= saturate(2.0f*base.w - 1.0f);

	float4 first_blend=  (1.0f-blend1)*detail1		+ blend1*detail2;
	float4 second_blend= (1.0f-blend2)*first_blend	+ blend2*detail3;

	albedo.rgb= DETAIL_MULTIPLIER * base.rgb * second_blend.rgb;
	albedo.a= second_blend.a;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(change_color_map);
PARAM(float4, change_color_map_xform);
PARAM(float3, primary_change_color);
PARAM(float3, secondary_change_color);
PARAM(float3, tertiary_change_color);
PARAM(float3, quaternary_change_color);

uniform float4 primary_change_color_old : register(c190);
uniform float4 secondary_change_color_old : register(c191);

void calc_albedo_two_change_color_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{	
	float4 base=			sample2D(base_map,			transform_texcoord(texcoord, base_map_xform));
	float4 detail=			sample2D(detail_map,		transform_texcoord(texcoord, detail_map_xform));
	float4 change_color=	sample2D(change_color_map, 	transform_texcoord(texcoord, change_color_map_xform));
	
#if ENTRY_POINT(entry_point) == ENTRY_POINT_albedo || ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_vertex_color
    float old_scalar = saturate((vPos.y * secondary_change_color_old.w - primary_change_color_old.w) * 15.0 + 0.5);
#else
    float old_scalar = saturate(primary_change_color_old.w * -15.0 + 0.5);
#endif
	
    float3 primary_change = lerp(primary_change_color.rgb, primary_change_color_old.rgb, old_scalar);
    float3 secondary_change = lerp(secondary_change_color.rgb, secondary_change_color_old.rgb, old_scalar);

	change_color.xyz=	((1.0f-change_color.x) + change_color.x*primary_change.xyz)*
						((1.0f-change_color.y) + change_color.y*secondary_change.xyz);

	albedo.xyz= DETAIL_MULTIPLIER * base.xyz*detail.xyz*change_color.xyz;
	albedo.w= base.w*detail.w;
	
	apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_four_change_color_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base=			sample2D(base_map,			transform_texcoord(texcoord, base_map_xform));
	float4 detail=			sample2D(detail_map,		transform_texcoord(texcoord, detail_map_xform));
	float4 change_color=	sample2D(change_color_map,	transform_texcoord(texcoord, change_color_map_xform));

	change_color.xyz=	((1.0f-change_color.x) + change_color.x*primary_change_color.xyz)	*
						((1.0f-change_color.y) + change_color.y*secondary_change_color.xyz)	*
						((1.0f-change_color.z) + change_color.z*tertiary_change_color.xyz)	*
						((1.0f-change_color.w) + change_color.w*quaternary_change_color.xyz);

	albedo.xyz= DETAIL_MULTIPLIER * base.xyz*detail.xyz*change_color.xyz;
	albedo.w= base.w*detail.w;
	
	apply_pc_albedo_modifier(albedo, normal);
}


PARAM_SAMPLER_2D(detail_map_overlay);
PARAM(float4, detail_map_overlay_xform);

void calc_albedo_two_detail_overlay_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base=				sample2D(base_map,				transform_texcoord(texcoord, base_map_xform));
	float4	detail=				sample2D(detail_map,			transform_texcoord(texcoord, detail_map_xform));	
	float4	detail2=			sample2D(detail_map2,			transform_texcoord(texcoord, detail_map2_xform));
	float4	detail_overlay=		sample2D(detail_map_overlay,	transform_texcoord(texcoord, detail_map_overlay_xform));

	float4 detail_blend= (1.0f-base.w)*detail + base.w*detail2;
	
	albedo.xyz= base.xyz * (DETAIL_MULTIPLIER * DETAIL_MULTIPLIER) * detail_blend.xyz * detail_overlay.xyz;
	albedo.w= detail_blend.w * detail_overlay.w;

	apply_pc_albedo_modifier(albedo, normal);
}


void calc_albedo_two_detail_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base=				sample2D(base_map,				transform_texcoord(texcoord, base_map_xform));
	float4	detail=				sample2D(detail_map,			transform_texcoord(texcoord, detail_map_xform));	
	float4	detail2=			sample2D(detail_map2,			transform_texcoord(texcoord, detail_map2_xform));
	
	albedo.xyz= base.xyz * (DETAIL_MULTIPLIER * DETAIL_MULTIPLIER) * detail.xyz * detail2.xyz;
	albedo.w= base.w * detail.w * detail2.w;

	apply_pc_albedo_modifier(albedo, normal);
}


PARAM_SAMPLER_2D(color_mask_map);
PARAM(float4, color_mask_map_xform);
PARAM(float4, neutral_gray);

void calc_albedo_color_mask_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base=	sample2D(base_map,   transform_texcoord(texcoord, base_map_xform));
	float4	detail=	sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
	float4  color_mask=	sample2D(color_mask_map,	transform_texcoord(texcoord, color_mask_map_xform));

	float4 tint_color=	((1.0f-color_mask.x) + color_mask.x * albedo_color.xyzw / float4(neutral_gray.xyz, 1.0f))		*		// ###ctchou $PERF do this divide in the pre-process
						((1.0f-color_mask.y) + color_mask.y * albedo_color2.xyzw / float4(neutral_gray.xyz, 1.0f))		*
						((1.0f-color_mask.z) + color_mask.z * albedo_color3.xyzw / float4(neutral_gray.xyz, 1.0f));

	albedo.rgb= base.rgb * (detail.rgb * DETAIL_MULTIPLIER) * tint_color.rgb;
	albedo.w= base.w * detail.w * tint_color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_two_detail_black_point_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base=				sample2D(base_map,				transform_texcoord(texcoord, base_map_xform));
	float4	detail=				sample2D(detail_map,			transform_texcoord(texcoord, detail_map_xform));	
	float4	detail2=			sample2D(detail_map2,			transform_texcoord(texcoord, detail_map2_xform));
	
	albedo.xyz= base.xyz * (DETAIL_MULTIPLIER * DETAIL_MULTIPLIER) * detail.xyz * detail2.xyz;
	albedo.w= apply_black_point(base.w, detail.w * detail2.w);

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_CUBE(custom_cube);

void calc_albedo_custom_cube_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map,   transform_texcoord(texcoord, base_map_xform));
	float4 custom_color = sampleCUBE(custom_cube, normal);

	albedo.rgb= base.rgb * custom_color.xyz;
	albedo.w= base.w * albedo_color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_CUBE(blend_map);
PARAM(float4, albedo_second_color);

void calc_albedo_two_color_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));

	float4 blend_factor = sampleCUBE(blend_map, normal);

	float4 color = blend_factor.y * albedo_color * 2 + blend_factor.z * albedo_second_color * 2;

	albedo.rgb= base.rgb * color.xyz;
	albedo.w= base.w * color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM(float3, chameleon_color0);
PARAM(float3, chameleon_color1);
PARAM(float3, chameleon_color2);
PARAM(float3, chameleon_color3);
PARAM(float, chameleon_color_offset1);
PARAM(float, chameleon_color_offset2);
PARAM(float, chameleon_fresnel_power);

float3 calc_chameleon(in float3 normal, in float3 view_dir)
{
	float dp = pow(max(dot(normal, view_dir), 0.0f), chameleon_fresnel_power);

	float3 col0 = chameleon_color0;
	float3 col1 = chameleon_color1;
	float lrp = dp * (1.0f / chameleon_color_offset1);

	if (dp > chameleon_color_offset1) {
		col0 = chameleon_color1;
		col1 = chameleon_color2;
		lrp = (dp - chameleon_color_offset1) * (1.0f / (chameleon_color_offset2 - chameleon_color_offset1));
	}
	if (dp > chameleon_color_offset2) {
		col0 = chameleon_color2;
		col1 = chameleon_color3;
		lrp = (dp - chameleon_color_offset2) * (1.0f / (1.0f - chameleon_color_offset2));
	}

	return lerp(col0, col1, lrp);
}

void calc_albedo_chameleon_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4	base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));
	float4	detail = sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
	
	float3 color = calc_chameleon(normal, view_dir);
	albedo.rgb = base.rgb * (detail.rgb * DETAIL_MULTIPLIER) * color.rgb;
	albedo.w = base.w*detail.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(chameleon_mask_map);
PARAM(float4, chameleon_mask_map_xform);

void calc_albedo_chameleon_masked_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));
    float4 detail = sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
    float mask = sample2D(chameleon_mask_map, transform_texcoord(texcoord, chameleon_mask_map_xform)).r;
	
	float3 color = lerp(1.0f, calc_chameleon(normal, view_dir), mask);
	albedo.rgb = base.rgb * (detail.rgb * DETAIL_MULTIPLIER) * color.rgb;
	albedo.w = base.w*detail.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(base_masked_map);
PARAM(float4, base_masked_map_xform);
PARAM(float4, albedo_masked_color);

void calc_albedo_chameleon_albedo_masked_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform)) * albedo_color;
	float4 base_masked = sample2D(base_masked_map, transform_texcoord(texcoord, base_masked_map_xform)) * albedo_masked_color;
	float  mask = sample2D(chameleon_mask_map, transform_texcoord(texcoord, chameleon_mask_map_xform)).r;

	base_masked.rgb *= calc_chameleon(normal, view_dir);

	albedo = lerp(base, base_masked, mask);

	apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_two_change_color_chameleon_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));
	float4 detail = sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
	float4 change_color = sample2D(change_color_map, transform_texcoord(texcoord, change_color_map_xform));

	float3 cur_primary_change_color = primary_change_color.rgb;
	float3 cur_secondary_change_color = secondary_change_color.rgb;

	// chameleon
	float3 color = calc_chameleon(normal, view_dir);

	albedo.rgb = base.rgb * (detail.rgb * DETAIL_MULTIPLIER) * color.rgb;

	float3 cc = cur_primary_change_color.xyz*change_color.x + cur_secondary_change_color.xyz*change_color.y;
	cc = lerp(0.5f, min(cc, 1.0f), min(change_color.x + change_color.y, 1.0f));

	albedo.xyz = albedo.xyz < 0.5f ? (2.0f * albedo.xyz * cc)
		: 1.0f - (2.0f * (1.0f - albedo.xyz) * (1.0f - cc));

	albedo.w = base.w*detail.w;

	apply_pc_albedo_modifier(albedo, normal);
}

uniform float4 primary_change_color_anim;
uniform float4 secondary_change_color_anim;

#define k_shaderstage_albedo 1

void calc_albedo_two_change_color_anim_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{	
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));
	float4 detail = sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
	float4 change_color = sample2D(change_color_map, transform_texcoord(texcoord, change_color_map_xform));
	
#if ENTRY_POINT(entry_point) == ENTRY_POINT_albedo || ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_vertex_color
    float anim_scalar = saturate((vPos.y * secondary_change_color_anim.w - primary_change_color_anim.w) * 15.0 + 0.5);
#else
    float anim_scalar = saturate(primary_change_color_anim.w * -15.0 + 0.5);
#endif
	
    float3 cur_primary_change_color = lerp(primary_change_color.rgb, primary_change_color_anim.rgb, anim_scalar);
    float3 cur_secondary_change_color = lerp(secondary_change_color.rgb, secondary_change_color_anim.rgb, anim_scalar);

	albedo.xyz = DETAIL_MULTIPLIER * base.xyz * detail.xyz;

	cur_primary_change_color *= albedo.xyz;
	cur_secondary_change_color *= albedo.xyz;

	albedo.xyz = lerp(albedo.xyz, cur_primary_change_color, change_color.x);
	albedo.xyz = lerp(albedo.xyz, cur_secondary_change_color, change_color.y);
	albedo.w = base.w*detail.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_CUBE(color_blend_mask_cubemap);
void calc_albedo_scrolling_cube_mask_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));

	float4 blend_factor = sampleCUBE(color_blend_mask_cubemap, misc.xyz);

	float4 color = blend_factor.y * albedo_color * 2 + blend_factor.z * albedo_second_color * 2;

	albedo.rgb = base.rgb * color.xyz;
	albedo.w = base.w * color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_CUBE(color_cubemap);
void calc_albedo_scrolling_cube_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));

	float4 color = sampleCUBE(color_cubemap, misc.xyz);

	albedo.rgb = base.rgb * color.xyz;
	albedo.w = base.w * color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(color_texture);
PARAM(float, u_speed);
PARAM(float, v_speed);
void calc_albedo_scrolling_texture_uv_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float2 transformed_texcoord = transform_texcoord(texcoord, base_map_xform);
	float4 base = sample2D(base_map, transformed_texcoord);
	
	static float2 scrolling_speed = float2(u_speed, v_speed);
	float4 color = sample2D(color_texture, transformed_texcoord + ps_total_time * scrolling_speed);

	albedo.rgb = base.rgb * color.xyz;
	albedo.w = base.w * color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_texture_from_misc_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float2 transformed_texcoord = transform_texcoord(texcoord, base_map_xform);
	float4 base = sample2D(base_map, transformed_texcoord);
	
	float4 color = sample2D(color_texture, misc.xy);

	albedo.rgb = base.rgb * color.xyz;
	albedo.w = base.w * color.w;

	apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_color_mask_hard_light_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
    float color_mask = sample2D(color_mask_map, transform_texcoord(texcoord, color_mask_map_xform)).r;
    float4 base = sample2D(base_map, transform_texcoord(texcoord, base_map_xform));
    float4 detail = sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
	
    float3 masked_color = ((color_mask * 2.0f - 1.0f) * albedo_color.rgb);
    float3 masked_color_unorm = masked_color * 0.5f + 0.5f;
	
    float3 inverse = base.rgb * (1.0f - masked_color_unorm);
	
    float3 hardlight = masked_color_unorm > 0.5f ? masked_color + 2.0f * inverse : masked_color_unorm * 2.0f * base.rgb;
	
    albedo.rgb = hardlight * detail.rgb * DETAIL_MULTIPLIER;
	albedo.a= base.a * detail.a * albedo_color.a;

    apply_pc_albedo_modifier(albedo, normal);
}

PARAM_SAMPLER_2D(emblem_map);

void calc_albedo_emblem_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	// decal border clip
    clip(float4(texcoord.xy, 1.0f-texcoord.xy));
	
    albedo= sample2D(emblem_map, texcoord);

    apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_four_change_color_applying_to_specular_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
    calc_albedo_four_change_color_ps(texcoord,
		albedo,
		normal,
		misc,
		view_dir,
		vPos);
}



