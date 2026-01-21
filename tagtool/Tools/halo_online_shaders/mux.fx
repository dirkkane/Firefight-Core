//#line 1 "source\rasterizer\hlsl\mux.fx"

#define calc_alpha_test_ps calc_alpha_test_off_ps
#define calc_specular_mask_ps calc_specular_mask_from_diffuse_ps
#define calc_self_illumination_ps calc_self_illumination_none_ps
#define blend_type opaque
#define bitmap_rotation 0

#define distort_proc_ps distort_off_ps

#include "global.fx"
#include "hlsl_constant_persist.fx"

#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"

PARAM_SAMPLER_2D(material_map);
PARAM(float4, material_map_xform);
PARAM(float, blend_material_scale);
PARAM(float, blend_material_offset);

#if defined(pc) && (DX_VERSION == 9)
	static float	mux_index= 0.0;
	static float	mux_blend= 0.0;
	static float4	mux_transform=	0.0;
	float pc_atlas_scale_x;
	float pc_atlas_scale_y;
	float pc_atlas_transform_x;
	float pc_atlas_transform_y;
	float blend_material_count;
#else
	PARAM(float, mux_index);
#endif //pc


void mux_pre_shader(in float2 texcoord)
{
#if defined(pc) && (DX_VERSION == 9)
	mux_index=			(sample2D(material_map, transform_texcoord(texcoord, material_map_xform)).r * blend_material_scale + blend_material_offset) * blend_material_count;

	float2	mux_int_index= 0.0;

	mux_int_index.x=	floor(mux_index);
	mux_blend=			mux_index - mux_int_index.x;

	mux_int_index=		floor(frac((mux_int_index.xx + float2(0.5f, 1.5f)) / blend_material_count) * blend_material_count);

	mux_transform=		mux_int_index.xxyy * float4(pc_atlas_transform_x, pc_atlas_transform_y, pc_atlas_transform_x, pc_atlas_transform_y);

#else
	mux_index= sample2D(material_map, transform_texcoord(texcoord, material_map_xform)).a * blend_material_scale + blend_material_offset;
#endif //pc
}
#define PRE_SHADER(texcoord) mux_pre_shader(texcoord)


void mux_pre_material_shader(in float2 texcoord);
#define PRE_MATERIAL_SHADER(texcoord) mux_pre_material_shader(texcoord)


float4 sample_array_texture(in texture_sampler_2d_array array_texture, in float2 texcoord)
{
#if defined(pc) && (DX_VERSION == 9)
	// tile to [0, 1], and scale and offset by mux transform
	float2 tilecoord=	texcoord.xy - floor(texcoord.xy);
	tilecoord=			tilecoord * float2(pc_atlas_scale_x, pc_atlas_scale_y);

	float4 lower=	sample2Dlod(array_texture, float4(tilecoord + mux_transform.xy, 0.0f, 0.0f), 0.0f);
	float4 higher=	sample2Dlod(array_texture, float4(tilecoord + mux_transform.zw, 0.0f, 0.0f), 0.0f);
	return lerp(lower, higher, mux_blend);
#else
	float4 result;
	float3 new_texcoord= float3(texcoord, mux_index);
#ifdef xenon
	asm {
		tfetch3D result, new_texcoord, array_texture, OffsetZ=+0.5
	};
#elif DX_VERSION == 11
	result= array_texture.t.Sample(array_texture.s, convert_3d_texture_coord_to_array_texture(array_texture, new_texcoord));
#endif
	return result;
#endif
}

float3 sample_array_bumpmap(in texture_sampler_2d_array bump_map, in float2 texcoord)
{
#if defined(pc) && (DX_VERSION == 9)
	//float3 bump= tex2D(bump_map, texcoord);
	float3 bump= 1;
#else					// xenon compressed bump textures don't calculate z automatically
	float4 bump;
	float3 new_texcoord= float3(texcoord, mux_index);
#ifdef xenon
	asm {
		tfetch3D bump, new_texcoord, bump_map, FetchValidOnly= false, OffsetZ=+0.5
	};
#elif DX_VERSION == 11
	bump= bump_map.t.Sample(bump_map.s,  convert_3d_texture_coord_to_array_texture(bump_map, new_texcoord));
#endif
	bump.z= saturate(dot(bump.xy, bump.xy));
	bump.z= sqrt(1 - bump.z);
#endif
	bump.xyz= normalize(bump.xyz);		// ###ctchou $PERF do we need to normalize?  why?

	return bump.xyz;
}

#define ALBEDO_TEXTURE_ARRAY
#define BUMP_TEXTURE_ARRAY
#define PARALLAX_TEXTURE_ARRAY
#define SAMPLE_ALBEDO_TEXTURE sample_array_texture
#define SAMPLE_BUMP_TEXTURE sample_array_bumpmap
#define SAMPLE_PARALLAX_TEXTURE sample_array_texture

#include "albedo.fx"
#include "parallax.fx"
#include "bump_mapping.fx"

#include "self_illumination.fx"
#include "specular_mask.fx"
#include "material_models.fx"
#include "environment_mapping.fx"
//#include "wetness.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"
#include "distortion.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"
#include "albedo_pass.fx"
#include "blend.fx"
#define	BLEND_MODE_OFF		// no blend for mux

#include "shadow_generate.fx"
#include "shadow_mask.fx"

#include "active_camo.fx"
#include "velocity.fx"

#include "debug_modes.fx"

#include "entry_points.fx"

#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_single_lobe_phong
PARAM_SAMPLER_2D(material_property0_map);
PARAM_SAMPLER_2D(material_property1_map);
void mux_pre_material_shader(in float2 texcoord)
{
#if !defined(pc) || (DX_VERSION == 11)
[isolate]
	float4 property0= sample2D(material_property0_map, float2(mux_index, 0.5f));
	float4 property1= sample2D(material_property1_map, float2(mux_index, 0.5f));

	specular_tint= property0.rgb;
	diffuse_coefficient= property0.a;
	specular_coefficient= 1.0f;
	area_specular_contribution= property1.r;
	analytical_specular_contribution= property1.g;
	environment_map_specular_contribution= property1.b;
	roughness= property1.a;
#else // pc
#endif // pc
}
#endif // #if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_single_lobe_phong
