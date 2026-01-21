// .shader_fur

#include "global.fx"

#include "hlsl_constant_persist.fx"

#define NO_WETNESS_EFFECT

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "blend.fx"
#include "utilities.fx"

#define DETAIL_MULTIPLIER 4.59479f

#include "deform.fx"
#include "texture_xform.fx"

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"

#include "parallax.fx"
#include "warp.fx"

#include "spherical_harmonics.fx"
#include "analytical_mask.fx"
#include "simple_lights.fx"
#include "overlays.fx"
#include "albedo_pass.fx"

#define FUR_SHADOW_APPLY
#define NO_SHADOW_GENERATE_PASS
#include "shadow_generate.fx"
#include "shadow_mask.fx"

#define shadow_intenstiy_preserve_for_vmf 1.2f
#define shadow_intenstiy_preserve_for_ambient 1.0f

#include "velocity.fx"

//#include "clip_plane.fx"
#include "dynamic_light_clip.fx"

#if ENTRY_POINT(entry_point) == ENTRY_POINT_imposter_static_sh
	#define static_sh_vs imposter_static_sh_vs
	#define static_sh_ps imposter_static_sh_ps
	#define SHADER_FOR_IMPOSTER
#elif ENTRY_POINT(entry_point) == ENTRY_POINT_imposter_static_prt_ambient
	#define static_prt_ambient_vs imposter_static_prt_ambient_vs
	#define static_prt_ps imposter_static_prt_ps
	#define SHADER_FOR_IMPOSTER
#endif


PARAM(float, approximate_specular_type);
PARAM_SAMPLER_2D(dynamic_light_gel_texture);


PARAM_SAMPLER_2D(fur_hairs_map);
PARAM(float4, fur_hairs_map_xform);

PARAM(float4, fur_deep_color);
PARAM_SAMPLER_2D(fur_tint_map);
PARAM(float4, fur_tint_map_xform);
PARAM(float4, fur_tint_color);

PARAM(float, layer_depth);
PARAM(float, texcoord_aspect_ratio);			// how stretched your texcoords are
PARAM(float, depth_darken);
PARAM(int, layers_of_4);						// integer please
PARAM(float, fur_intensity);
PARAM(float, fur_alpha_scale);
PARAM(float, fur_shear_x);						// read from warp map
PARAM(float, fur_shear_y);						// read from warp map
PARAM(float, fur_fix);

PARAM(bool, no_dynamic_lights);

float4 calc_albedo_multilayer_ps(
	in float2	texcoord,
	in float3	view_dir,														// in_tangent_space
	in float3	fragment_to_camera_world,
	in float	view_dot_normal)
{
	float3	fur_color=		sample2D(fur_tint_map,	transform_texcoord(texcoord, fur_tint_map_xform));

	texcoord= transform_texcoord(texcoord, fur_hairs_map_xform);						// transform texcoord first

	float layer_count=	layers_of_4 * 4;

	// comb the fur
	view_dir.xy -=	float2(fur_shear_x, fur_shear_y) * view_dir.z;
	view_dir=		normalize(view_dir);

	// calculate shift offset
	float2 offset=	view_dir.xy * fur_hairs_map_xform.xy * float2(texcoord_aspect_ratio, 1.0f) * layer_depth / layer_count;

	// offset start point so that the fixed point is the base of the fur layer, not the top
	texcoord	+=	fur_fix * offset * layer_count;

	float4 accum= float4(0.0f, 0.0f, 0.0f, 0.0f);
#ifdef pc
//	[unroll]
	[loop]
#endif
	float depth_intensity= 1.0f;
	for (int x= 0; x < layers_of_4; x++)
	{
		accum +=			depth_intensity * sample2D(fur_hairs_map,	texcoord);
		texcoord -=			offset;
		depth_intensity *=	depth_darken;

		accum +=			depth_intensity * sample2D(fur_hairs_map,	texcoord);
		texcoord -=			offset;
		depth_intensity *=	depth_darken;

		accum +=			depth_intensity * sample2D(fur_hairs_map,	texcoord);
		texcoord -=			offset;
		depth_intensity *=	depth_darken;

		accum +=			depth_intensity * sample2D(fur_hairs_map,	texcoord);
		texcoord -=			offset;
		depth_intensity *=	depth_darken;
	}

	accum.rgba /= layer_count;


	float4 result;
//	result.rgb=		pow(accum.rgb, layer_contrast) * fur_color * fur_intensity;

	result.rgb=		(fur_deep_color.rgb + accum.rgb * fur_tint_color.rgb) * fur_color * fur_intensity;
	result.a=		saturate(accum.a * fur_alpha_scale);

	return result;
}


void albedo_vs(							// albedo pass
	in vertex_type vertex,
	out float4 position						: SV_Position,
	//CLIP_OUTPUT
	out float2 texcoord						: TEXCOORD0,
	out float3 normal						: TEXCOORD1,
	out float3 binormal						: TEXCOORD2,
	out float3 tangent						: TEXCOORD3,
	out float3 fragment_to_camera_world		: TEXCOORD4)
{
	float4 local_to_world_transform[3];
	always_local_to_view(vertex, local_to_world_transform, position, binormal);

	texcoord=						vertex.texcoord;
	normal=							vertex.normal;
	tangent=						vertex.tangent;
	//binormal=						vertex.binormal;
	fragment_to_camera_world=		Camera_Position - vertex.position;

	//CALC_CLIP(position);
}

void static_sh_vs(
	in vertex_type vertex,
	out float4 position						: SV_Position,
	//CLIP_OUTPUT
//	out float2 texcoord						: TEXCOORD0,
//	out float3 binormal						: TEXCOORD2,
//	out float3 tangent						: TEXCOORD3,
	out float3 normal						: TEXCOORD0,
	out float3 fragment_to_camera_world		: TEXCOORD1)
{
	float4 local_to_world_transform[3];
	float3 binormal;
	always_local_to_view(vertex, local_to_world_transform, position, binormal);

//	texcoord=						vertex.texcoord;
	normal=							vertex.normal;
//	tangent=						vertex.tangent;
//	binormal=						vertex.binormal;
	fragment_to_camera_world=		Camera_Position - vertex.position;

	//CALC_CLIP(position);
}

void static_prt_ambient_vs(
	in vertex_type vertex,
	out float4 position						: SV_Position,
	//CLIP_OUTPUT
//	out float2 texcoord						: TEXCOORD0,
//	out float3 binormal						: TEXCOORD2,
//	out float3 tangent						: TEXCOORD3,
	out float3 normal						: TEXCOORD0,
	out float3 fragment_to_camera_world		: TEXCOORD1)
{
	static_sh_vs(vertex, position, /*CLIP_OUTPUT_PARAM*/ normal, fragment_to_camera_world);

	//CALC_CLIP(position);
}

void default_dynamic_light_vs(
	in vertex_type vertex,
	out float4 position						: SV_Position,
	//DYNAMIC_LIGHT_CLIP_OUTPUT
//	out float2 texcoord						: TEXCOORD0,
//	out float3 binormal						: TEXCOORD2,
//	out float3 tangent						: TEXCOORD3,
	out float3 normal						: TEXCOORD0,
	out float3 fragment_to_camera_world		: TEXCOORD1,
	out float4 fragment_position_shadow		: TEXCOORD2)		// homogenous coordinates of the fragment position in projective shadow space
{
	//CLIP_OUTPUT_DUMMY
	static_sh_vs(vertex, position, /*CLIP_OUTPUT_PARAM*/ normal, fragment_to_camera_world);
	fragment_position_shadow= mul(float4(vertex.position.xyz, 1.0f), Shadow_Projection);

	//CALC_DYNAMIC_LIGHT_CLIP(position);
}

void dynamic_light_vs(
	in vertex_type vertex,
	out float4 position						: SV_Position,
	//DYNAMIC_LIGHT_CLIP_OUTPUT
//	out float2 texcoord						: TEXCOORD0,
//	out float3 binormal						: TEXCOORD2,
//	out float3 tangent						: TEXCOORD3,
	out float3 normal						: TEXCOORD0,
	out float3 fragment_to_camera_world		: TEXCOORD1,
	out float4 fragment_position_shadow		: TEXCOORD2)		// homogenous coordinates of the fragment position in projective shadow space
{
    default_dynamic_light_vs(
        vertex,
        position,
        normal,
        fragment_to_camera_world,
        fragment_position_shadow);
}













albedo_pixel albedo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	//CLIP_INPUT
	in float2 original_texcoord				: TEXCOORD0,
	in float3 normal						: TEXCOORD1,
	in float3 binormal						: TEXCOORD2,
	in float3 tangent						: TEXCOORD3,
	in float3 fragment_to_camera_world		: TEXCOORD4)
{
	// normalize interpolated values
	normal=		normalize(normal);
#ifndef ALPHA_OPTIMIZATION
	binormal=	normalize(binormal);
	tangent=	normalize(tangent);
#endif

	// setup tangent frame
	float3x3 tangent_frame=				{ tangent, binormal, normal };

	float3 bump_normal=					normal;
	float3 view_dir=					normalize(fragment_to_camera_world);
	float3 view_dir_in_tangent_space=	mul(tangent_frame, view_dir);					// ###ctchou $PERF $TODO can we pass this as an interpolated value, and skip all the rest?
	float  view_dot_normal=				dot(view_dir, bump_normal);
	float3 view_reflect_dir=			-normalize(reflect(view_dir, bump_normal));

	// compute parallax
	float2 texcoord;
	calc_parallax_ps(original_texcoord, view_dir_in_tangent_space, texcoord);

	float4 albedo=						calc_albedo_ps(texcoord, view_dir_in_tangent_space, fragment_to_camera_world, view_dot_normal);

	// TODO: Map to Halo 3's input structs
	return convert_to_albedo_target(albedo, bump_normal, 0.0f, tangent_frame[2], approximate_specular_type);
}

float4 get_albedo(in float2 fragment_position)
{
	float4 albedo;

#if DX_VERSION == 11
	albedo= albedo_texture.Load(int3(fragment_position.xy, 0));
#elif defined(pc)
	float2 screen_texcoord=		(fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy;
	albedo=						sample2D(albedo_texture, screen_texcoord);
#else // xenon
	float2 screen_texcoord= fragment_position.xy;
	asm
	{
		tfetch2D albedo, screen_texcoord, albedo_texture, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true
	};
#endif // xenon

	return albedo;
}

accum_pixel static_sh_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//CLIP_INPUT
//	in float2 texcoord						: TEXCOORD0,
//	in float3 binormal						: TEXCOORD2,
//	in float3 tangent						: TEXCOORD3,
	in float3 normal						: TEXCOORD0,			// ###ctchou $TODO $PERF optimize by removing unused interpolators
	in float3 fragment_to_camera_world		: TEXCOORD1)
{
	// normalize interpolated values
	normal=		normalize(normal);
#ifndef ALPHA_OPTIMIZATION
//	binormal=	normalize(binormal);
//	tangent=	normalize(tangent);
#endif

//	// setup tangent frame
//	float3x3 tangent_frame=		{ tangent, binormal, normal };

	// build lighting_coefficients
	float4 vmf_lighting_coefficients[4]=
	{
		p_lighting_constant_0,
		p_lighting_constant_1,
		p_lighting_constant_2,
		p_lighting_constant_3,
	};

	float4 shadow_mask;
	get_shadow_mask(shadow_mask, fragment_position);
	apply_shadow_mask_to_vmf_lighting_coefficients_direct_only(shadow_mask, vmf_lighting_coefficients);

	float3 bump_normal=		normal;

	float3 fragment_position_world=		Camera_Position_PS - fragment_to_camera_world;
	float3 view_dir=					normalize(fragment_to_camera_world);
//	float3 view_dir_in_tangent_space=	mul(tangent_frame, view_dir);
	float  view_dot_normal=				dot(view_dir, bump_normal);
	float3 view_reflect_dir=			-normalize(reflect(view_dir, bump_normal));

	// get diffuse albedo, specular mask and bump normal
	float4 albedo=	get_albedo(fragment_position);

	float3 diffuse_radiance=	dual_vmf_diffuse(bump_normal,		vmf_lighting_coefficients);

	float3 analytical_mask=		get_analytical_mask(fragment_position_world,	vmf_lighting_coefficients);

	// analytical diffuse response
	float cosine=				saturate(dot(k_ps_dominant_light_direction.xyz, bump_normal) * 0.5f + 0.5f);
	cosine *= cosine;
	float analytical_light_dot_product_result=		cosine*cosine;
	diffuse_radiance +=			analytical_mask * analytical_light_dot_product_result * k_ps_dominant_light_intensity.xyz * vmf_lighting_coefficients[0].w / pi;


	// bounce light
//	diffuse_radiance +=			saturate(dot(k_ps_bounce_light_direction, bump_normal))*k_ps_bounce_light_intensity/pi;


	// simple lights
	if (!no_dynamic_lights)
	{
		float3 simple_light_diffuse_light;
		float3 simple_light_specular_light;

		calc_simple_lights_analytical(
			fragment_position_world,
			bump_normal,
			view_reflect_dir,
			1.0f,
			simple_light_diffuse_light,
			simple_light_specular_light);

		diffuse_radiance += simple_light_diffuse_light;
	}

	float4 out_color;

	out_color.rgb=				diffuse_radiance * albedo.rgb;

	APPLY_OVERLAYS(out_color.rgb, float2(0.0f, 0.0f), view_dot_normal)

	// compute velocity
	float output_alpha;
	{
		output_alpha= compute_antialias_blur_scalar(fragment_to_camera_world);
	}

	out_color.rgb *=			g_exposure.rrr;
	out_color.w=				output_alpha;

	return convert_to_render_target(out_color, false, false);
}

accum_pixel static_prt_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//CLIP_INPUT
//	in float2 texcoord						: TEXCOORD0,
//	in float3 binormal						: TEXCOORD2,
//	in float3 tangent						: TEXCOORD3,
	in float3 normal						: TEXCOORD0,
	in float3 fragment_to_camera_world		: TEXCOORD1)
{
	return static_sh_ps(fragment_position, /*CLIP_INPUT_PARAM*/ normal, fragment_to_camera_world);
}

accum_pixel default_dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//DYNAMIC_LIGHT_CLIP_INPUT
//	in float2 texcoord : TEXCOORD0,
//	in float3 binormal : TEXCOORD2,
//	in float3 tangent : TEXCOORD3,
	in float3 normal : TEXCOORD0,
	in float3 fragment_to_camera_world : TEXCOORD1,
	in float4 fragment_position_shadow : TEXCOORD2,			// homogenous coordinates of the fragment position in projective shadow space
	bool high_res_shadows)
{
	// normalize interpolated values
	normal=		normalize(normal);
#ifndef ALPHA_OPTIMIZATION
//	binormal=	normalize(binormal);
//	tangent=	normalize(tangent);
#endif

	// setup tangent frame
//	float3x3 tangent_frame=		{ tangent, binormal, normal };



	float3 bump_normal=		normal;

	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
	float3 view_dir= normalize(fragment_to_camera_world);
//	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	float3 view_reflect_dir= -normalize(reflect(view_dir, bump_normal));


	float3 light_radiance;
	float3 fragment_to_light;
	float light_dist2;
	calculate_simple_light(
		0,
		fragment_position_world,
		light_radiance,
		fragment_to_light);			// return normalized direction to the light

	fragment_position_shadow.xyz /= fragment_position_shadow.w;							// projective transform on xy coordinates

	// apply light gel
	light_radiance *=  sample2D(dynamic_light_gel_texture, transform_texcoord(fragment_position_shadow.xy, p_dynamic_light_gel_xform));

	// get diffuse albedo, specular mask and bump normal
	float4 albedo=	get_albedo(fragment_position);

//	restore_specular_mask(albedo, analytical_specular_contribution);



	// calculate diffuse lobe
	float cosine=										saturate(dot(fragment_to_light, bump_normal) * 0.5f + 0.5f);
	cosine *= cosine;
	float	analytical_light_dot_product_result=		cosine*cosine;
	float3	radiance=									analytical_light_dot_product_result * light_radiance * albedo.rgb / pi;



	// calculate shadow
	float unshadowed_percentage= 1.0f;
	if (dynamic_light_shadowing)
	{
		if (dot(radiance, radiance) > 0.0f)									// ###ctchou $PERF unproven 'performance' hack
		{
			float cosine= dot(normal.xyz, p_lighting_constant_1.xyz);								// p_vmf_lighting_constant_1.xyz = normalized forward direction of light (along which depth values are measured)

			float slope= sqrt(1-cosine*cosine) / cosine;										// slope == tan(theta) == sin(theta)/cos(theta) == sqrt(1-cos^2(theta))/cos(theta)
																								// ###ctchou $REVIEW could make this (4.0) a shader parameter if you have trouble with the masterchief's helmet not shadowing properly

			float half_pixel_size= p_lighting_constant_1.w * fragment_position_shadow.w;		// the texture coordinate distance from the center of a pixel to the corner of the pixel - increases linearly with increasing depth
			float depth_bias= (slope + 0.2f) * half_pixel_size;

			depth_bias= 0.0f;

//			if (cinematic)
			if (false)
			{
				if (high_res_shadows)
				{
					unshadowed_percentage= sample_percentage_closer_PCF_9x9_block_predicated(fragment_position_shadow, depth_bias);
				} else
				{
					unshadowed_percentage= sample_percentage_closer_PCF_5x5_block_predicated(fragment_position_shadow, depth_bias);
				}
			}
			else
			{
				if (high_res_shadows)
				{
					unshadowed_percentage= sample_percentage_closer_PCF_5x5_block_predicated(fragment_position_shadow, depth_bias);
				} else
				{
					unshadowed_percentage= sample_percentage_closer_PCF_3x3_block(fragment_position_shadow, depth_bias);
				}
			}
		}
	}

	float4 out_color;

	// set color channels
	out_color.xyz= (radiance) * g_exposure.rrr * unshadowed_percentage;

	float output_alpha= 1.0f;

	// set alpha channel
	out_color.w= ALPHA_CHANNEL_OUTPUT;

	return convert_to_render_target(out_color, true, true);
}

accum_pixel dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//DYNAMIC_LIGHT_CLIP_INPUT
//	in float2 texcoord : TEXCOORD0,
//	in float3 binormal : TEXCOORD2,
//	in float3 tangent : TEXCOORD3,
	in float3 normal : TEXCOORD0,
	in float3 fragment_to_camera_world : TEXCOORD1,
	in float4 fragment_position_shadow : TEXCOORD2)			// homogenous coordinates of the fragment position in projective shadow space
{
	return default_dynamic_light_ps(
		fragment_position,
		//DYNAMIC_LIGHT_CLIP_INPUT_PARAM
		normal,
		fragment_to_camera_world,
		fragment_position_shadow,
		false);
}

accum_pixel dynamic_light_hq_shadows_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//DYNAMIC_LIGHT_CLIP_INPUT
//	in float2 texcoord : TEXCOORD0,
//	in float3 binormal : TEXCOORD2,
//	in float3 tangent : TEXCOORD3,
	in float3 normal : TEXCOORD0,
	in float3 fragment_to_camera_world : TEXCOORD1,
	in float4 fragment_position_shadow : TEXCOORD2)			// homogenous coordinates of the fragment position in projective shadow space
{
	return default_dynamic_light_ps(
		fragment_position,
		//DYNAMIC_LIGHT_CLIP_INPUT_PARAM
		normal,
		fragment_to_camera_world,
		fragment_position_shadow,
		false);
}

























