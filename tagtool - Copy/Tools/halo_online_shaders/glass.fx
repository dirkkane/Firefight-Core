
#define blend_type alpha_blend
#ifdef material_type
#undef material_type
#define material_type two_lobe_phong
#endif
#define calc_specular_mask_ps calc_specular_mask_no_specular_mask_ps
#define calc_self_illumination_ps calc_self_illumination_none_ps

//#define DX_VERSION 9

#include "global.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "blend.fx"
#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"

#include "atmosphere.fx"

#include "albedo.fx"
#include "bump_mapping.fx"
#include "extended_bump_mapping.fx"
#include "environment_mapping.fx"

#include "render_target.fx"
#include "spherical_harmonics.fx"
#include "lightmap_sampling.fx"
#include "simple_lights.fx"

PARAM(float, analytical_specular_contribution);
PARAM(float, diffuse_coefficient);
PARAM(float, environment_map_specular_contribution);
PARAM_SAMPLER_2D(material_texture);
PARAM(float4, material_texture_xform);						//texture matrix
PARAM(float, material_texture_black_roughness);
PARAM(float, material_texture_black_specular_multiplier);

PARAM(float, analytical_roughness);
PARAM(bool, order3_area_specular);
PARAM(bool, no_dynamic_lights);

#define area_specular_contribution 0

#define use_material_texture false
#define specular_coefficient 1
#include "two_lobe_phong_reach.fx"

// alias
#define normal_specular		specular_tint
#define glancing_specular	fresnel_color

#define calc_output_color_with_explicit_light_quadratic calc_output_color_with_explicit_light_linear_with_dominant_light
										
float3 get_constant_analytical_light_dir_vs()
{
 	return -normalize(v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz);		// ###ctchou $PERF : pass this in as a constant
}				

void get_albedo_and_normal(out float3 bump_normal, out float4 albedo, in float2 texcoord, in float3x3 tangent_frame, in float3 fragment_to_camera_world, in float2 fragment_position)
{
	calc_bumpmap_ps(texcoord, fragment_to_camera_world, tangent_frame, bump_normal);
	calc_albedo_ps(texcoord, albedo, bump_normal, float4(0,0,0,0), float3(0,0,0), fragment_position);
}

void calc_material_glass_ps(
    in float3 view_dir,
    in float3 fragment_to_camera_world,
    in float3 surface_normal,
    in float3 view_reflect_dir_world,
    float4 sh_lighting_coefficients[10],
    in float3 analytical_light_dir,
    in float3 analytical_light_intensity,
    in float3 diffuse_reflectance,
    in float3 specular_mask,
    in float2 texcoord,
    in float4 prt_ravi_diff,
    in float3x3 tangent_frame,          // = {tangent, binormal, normal};
    out float3 envmap_area_specular_only,
    out float4 specular_radiance,
    inout float3 diffuse_radiance)
{
	float3 specular_analytical= 0;
	float3 simple_light_diffuse_light= 0.0f;
	float3 simple_light_specular_light= 0.0f;
	float4 misc = 0.0f;

	float4 spatially_varying_material_parameters;
	float3 normal_specular_blend_albedo_color;
	float3 additional_diffuse_radiance;

	float4 final_specular_tint_color= calc_material_analytic_specular_two_lobe_phong_ps(
		view_dir,
		surface_normal,
		view_reflect_dir_world,
		analytical_light_dir,
		analytical_light_intensity,
		0,
		texcoord,
		prt_ravi_diff.w,
		tangent_frame,
		misc,
		spatially_varying_material_parameters,
		normal_specular_blend_albedo_color,
		specular_analytical,
		additional_diffuse_radiance);

	[branch]
	if (!no_dynamic_lights)
	{
		float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
		calc_simple_lights_analytical(
			fragment_position_world,
			surface_normal,
			view_reflect_dir_world,                             // view direction = fragment to camera,   reflected around fragment normal
			normal_specular_power,
			simple_light_diffuse_light,
			simple_light_specular_light);
		simple_light_specular_light*=final_specular_tint_color.rgb;
	}

	//scaling and masking
	specular_radiance.xyz= specular_mask * (simple_light_specular_light + specular_analytical) * analytical_specular_contribution ;

	//envmap_area_specular_only.xyz= envmap_area_specular_only*final_specular_tint_color + 0.25*(lighting_coefficients[1].rgb+lighting_coefficients[3].rgb);
    envmap_area_specular_only = sh_lighting_coefficients[0].xyz * final_specular_tint_color.rgb;
	
	specular_radiance.w= 0.0f;

	diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_coefficient;
}

struct static_per_pixel_vsout
{
	float4 position						: VS_POS_OUTPUT;
	float4 texcoord_and_vertexNdotL		: TEXCOORD0;
	float3 normal						: TEXCOORD3;
	float3 binormal						: TEXCOORD4;
	float3 tangent						: TEXCOORD5;
    float3 fragment_to_camera_world		: TEXCOORD6;
	float3 extinction					: COLOR0;
	float3 inscatter					: COLOR1;
};
										
static_per_pixel_vsout static_sh_vs(in vertex_type vertex)
{
    static_per_pixel_vsout vsout;
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
    always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal= vertex.normal;
	vsout.texcoord_and_vertexNdotL.xy= vertex.texcoord;
    vsout.texcoord_and_vertexNdotL.w= vsout.position.w;
	vsout.tangent= vertex.tangent;
    vsout.binormal = vertex.binormal;
	
    vsout.texcoord_and_vertexNdotL.z = dot(vsout.normal, get_constant_analytical_light_dir_vs());
		
	// world space direction to eye/camera
    vsout.fragment_to_camera_world.rgb = Camera_Position - vertex.position;
											
    compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);
	
    return vsout;
} 

float4 get_albedo(
	in float2 fragment_position)
{
    float2 screen_texcoord = (fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy;
    float4 albedo = tex2D(albedo_texture, screen_texcoord);
	
	return albedo;
}

float4 calc_output_color_with_explicit_light_linear_with_dominant_light(
	float2 fragment_position,
	float3x3 tangent_frame,				// = {tangent, binormal, normal};
	float4 sh_lighting_coefficients[10],
	float3 fragment_to_camera_world,	// direction to eye/camera, in world space
	float2 original_texcoord,
	float4 prt_ravi_diff,
	float3 light_direction,
	float3 light_intensity,
	float3 extinction,
	float3 inscatter,
	out float4 ssr_color)
{
	float4 out_color;
	
	float3 view_dir= normalize(fragment_to_camera_world);	

    float3 bump_normal;
    float4 albedo;    
    get_albedo_and_normal(bump_normal, albedo, original_texcoord, tangent_frame, fragment_to_camera_world, float2(0,0));
    
	float3 view_reflect_dir= -normalize(reflect(view_dir, bump_normal));
	
	//float analytical_light_dot_product_result=saturate(dot(light_direction,bump_normal));
    //float raised_analytical_light_equation_a= (raised_analytical_light_maximum-raised_analytical_light_minimum)/2;
    //float raised_analytical_light_equation_b= (raised_analytical_light_maximum+raised_analytical_light_minimum)/2;
    //float raised_analytical_dot_product= saturate(dot(light_direction, bump_normal)*raised_analytical_light_equation_a+raised_analytical_light_equation_b);
	//float3 diffuse_radiance= analytical_light_dot_product_result*
	//		light_intensity/
	//		pi*
	//		vmf_lighting_coefficients[0].w;
    //
	//float3 analytical_mask= get_analytical_mask(Camera_Position_PS - fragment_to_camera_world,vmf_lighting_coefficients);
	//
    //float3 envmap_area_specular_only= raised_analytical_dot_product * light_intensity * analytical_mask * 0.25f * vmf_lighting_coefficients[2].w;
    
    float3 diffuse_radiance = ravi_order_3(bump_normal, sh_lighting_coefficients);
	
    float3 envmap_area_specular_only;
    const float specular_mask= 1.0;
    
    float4 envmap_specular_reflectance_and_roughness= float4(environment_map_specular_contribution,
			environment_map_specular_contribution,
			environment_map_specular_contribution,
			analytical_roughness);
    
    float4 specular_radiance= 0;

    calc_material_glass_ps(
       view_dir,                 // normalized
       fragment_to_camera_world,       // actual vector, not normalized
       bump_normal,              // normalized
       view_reflect_dir,          // normalized
       
       sh_lighting_coefficients,
       light_direction,          // normalized
       light_intensity/**analytical_mask*/,
       
       albedo.xyz,              // diffuse_reflectance
       specular_mask,
       original_texcoord,
       prt_ravi_diff,

       tangent_frame,

       envmap_area_specular_only,
       specular_radiance,
       diffuse_radiance);
       	
    float3 envmap_radiance = CALC_ENVMAP(envmap_type)(view_dir, bump_normal, view_reflect_dir, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, ssr_color);
		
	// apply opacity fresnel effect	
	{
		float final_opacity, specular_scalar;
		calc_alpha_blend_opacity(albedo.w, tangent_frame[2], view_dir, original_texcoord, final_opacity, specular_scalar);

		envmap_radiance*= specular_scalar;
		specular_radiance*= specular_scalar;
		albedo.w= final_opacity;
	}
		
	out_color.xyz= diffuse_radiance * albedo.xyz + specular_radiance.rgb + envmap_radiance;
	
	out_color.w= saturate(albedo.w);

	out_color.rgb= out_color.rgb * g_exposure.rrr;
	
	return out_color;
}

accum_pixel static_sh_ps(in static_per_pixel_vsout vsout)
{	
	// setup tangent frame
    float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal.xyz };
	
	// build sh_lighting_coefficients
	float4 sh_lighting_coefficients[10]=
		{
			p_lighting_constant_0, 
			p_lighting_constant_1, 
			p_lighting_constant_2, 
			p_lighting_constant_3, 
			p_lighting_constant_4, 
			p_lighting_constant_5, 
			p_lighting_constant_6, 
			p_lighting_constant_7, 
			p_lighting_constant_8, 
			p_lighting_constant_9 
		}; 	
	
	float4 prt_ravi_diff= float4(1.0f, 0.0f, 1.0f, dot(tangent_frame[2], k_ps_dominant_light_direction.xyz));
	
    float4 ssr_color;
	float4 out_color= calc_output_color_with_explicit_light_quadratic(
		vsout.position.xy,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord_and_vertexNdotL.xy,
		prt_ravi_diff,
		k_ps_dominant_light_direction.xyz,
		k_ps_dominant_light_intensity.xyz,
		vsout.extinction,
		vsout.inscatter.rgb,
		ssr_color);


    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false, ssr_color);
}

// single pass lighting

struct static_per_vertex_vsout
{
	float4 position					: VS_POS_OUTPUT;
	float4 texcoord					: TEXCOORD0; // zw contains inscatter.xy
	float3 fragment_to_camera_world	: TEXCOORD1;
	float3 tangent					: TEXCOORD2;
	float4 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float4 probe0_3_r				: TEXCOORD5;
	float4 probe0_3_g				: TEXCOORD6;
	float4 probe0_3_b				: TEXCOORD7;
	float3 dominant_light_intensity	: TEXCOORD8;
	float4 extinction				: COLOR0;
};

static_per_vertex_vsout static_per_vertex_vs(
	in vertex_type vertex,
	in float4 light_intensity : TEXCOORD3,
	in float4 c0_3_rgbe : TEXCOORD4,
	in float4 c1_1_rgbe : TEXCOORD5,
	in float4 c1_2_rgbe : TEXCOORD6,
	in float4 c1_3_rgbe : TEXCOORD7)
{
	static_per_vertex_vsout vsout;
	
   // on PC vertex lightnap is stored in unsigned format
   // convert to signed
   light_intensity = 2 * light_intensity - 1;
	c0_3_rgbe = 2 * c0_3_rgbe - 1;
	c1_1_rgbe = 2 * c1_1_rgbe - 1;
	c1_2_rgbe = 2 * c1_2_rgbe - 1;
	c1_3_rgbe = 2 * c1_3_rgbe - 1;

	// output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);

    vsout.normal.xyz = vertex.normal;
	vsout.normal.w = vsout.position.w;
	vsout.texcoord.xy = vertex.texcoord;
	vsout.binormal = vertex.binormal;
	vsout.tangent = vertex.tangent;
	
	float scale= exp2(light_intensity.a * 31.75f);
	light_intensity.rgb*= scale;
	
	scale= exp2(c0_3_rgbe.a * 31.75f);
	c0_3_rgbe.rgb*= scale;
	
	scale= exp2(c1_1_rgbe.a * 31.75f);
	c1_1_rgbe.rgb*= scale;

	scale= exp2(c1_2_rgbe.a * 31.75f);
	c1_2_rgbe.rgb*= scale;
	
	scale= exp2(c1_3_rgbe.a * 31.75f);
	c1_3_rgbe.rgb*= scale;
		
	vsout.probe0_3_r = float4(c0_3_rgbe.r, c1_1_rgbe.r, c1_2_rgbe.r, c1_3_rgbe.r);
	vsout.probe0_3_g = float4(c0_3_rgbe.g, c1_1_rgbe.g, c1_2_rgbe.g, c1_3_rgbe.g);
	vsout.probe0_3_b = float4(c0_3_rgbe.b, c1_1_rgbe.b, c1_2_rgbe.b, c1_3_rgbe.b);

	vsout.dominant_light_intensity = light_intensity.xyz;

	vsout.fragment_to_camera_world = Camera_Position - vertex.position;
	
	float3 inscatter;
	compute_scattering(Camera_Position, vertex.position, vsout.extinction.xyz, inscatter);
	vsout.texcoord.zw = inscatter.xy;
	vsout.extinction.w = inscatter.z;

	return vsout;
}

accum_pixel static_per_vertex_ps(in static_per_vertex_vsout vsout)
{
	// setup tangent frame
    float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal.xyz };
	
	// build sh_lighting_coefficients
	float4 L0_3[3] = { vsout.probe0_3_r, vsout.probe0_3_g, vsout.probe0_3_b };
	
	//compute dominant light dir
	float3 dominant_light_direction = vsout.probe0_3_r.wyz * 0.212656f + vsout.probe0_3_g.wyz * 0.715158f + vsout.probe0_3_b.wyz * 0.0721856f;
	dominant_light_direction= dominant_light_direction * float3(-1.0f, -1.0f, 1.0f);
	dominant_light_direction= normalize(dominant_light_direction);
	
	float4 lighting_constants[4];
	pack_constants_linear(L0_3, lighting_constants);
	
	float4 sh_lighting_coefficients[10]=
		{
			lighting_constants[0], 
			lighting_constants[1], 
			lighting_constants[2], 
			lighting_constants[3],
			float4(0,0,0,0), 
			float4(0,0,0,0), 
			float4(0,0,0,0), 
			float4(0,0,0,0), 
			float4(0,0,0,0), 
			float4(0,0,0,0) 
		}; 	

	float4 prt_ravi_diff= float4(1.0f, 1.0f, 1.0f, dot(tangent_frame[2], dominant_light_direction));
	
    float4 ssr_color;
	float4 out_color= calc_output_color_with_explicit_light_linear_with_dominant_light(
		vsout.position.xy,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord.xy,
		prt_ravi_diff,
		dominant_light_direction,
		vsout.dominant_light_intensity,
		vsout.extinction.rgb,
		float3(vsout.texcoord.z, vsout.texcoord.w, vsout.extinction.w),
		ssr_color);

    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false, ssr_color);
}

struct static_prt_vsout
{
	float4 position					: VS_POS_OUTPUT;
	float3 texcoord					: TEXCOORD0;
	float3 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 tangent					: TEXCOORD5;
	float3 fragment_to_camera_world	: TEXCOORD6;
	float4 prt_ravi_diff			: TEXCOORD7;
	float3 extinction				: COLOR0;
	float3 inscatter				: COLOR1;
};

accum_pixel static_prt_ps(in static_prt_vsout vsout)
{	
	// setup tangent frame
    float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal };
	
	//float4 prt_ravi_diff= float4(1,1,1,1);
	
	// build sh_lighting_coefficients
	float4 sh_lighting_coefficients[10]=
		{
			p_lighting_constant_0, 
			p_lighting_constant_1, 
			p_lighting_constant_2, 
			p_lighting_constant_3, 
			p_lighting_constant_4, 
			p_lighting_constant_5, 
			p_lighting_constant_6, 
			p_lighting_constant_7, 
			p_lighting_constant_8, 
			p_lighting_constant_9 
		};
	
    float4 ssr_color;
	float4 out_color= calc_output_color_with_explicit_light_quadratic(
		vsout.position.xy,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord.xy,
		vsout.prt_ravi_diff,
		k_ps_dominant_light_direction.xyz,
		k_ps_dominant_light_intensity.xyz,
		vsout.extinction.rgb,
		vsout.inscatter.rgb,
		ssr_color);
				
    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false, ssr_color);
}

static_prt_vsout static_prt_ambient_vs(in vertex_type vertex, in float prt_c0_c3 : BLENDWEIGHT1)
{
    static_prt_vsout vsout;
	
	float prt_c0= prt_c0_c3;

	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal= vertex.normal;
    vsout.texcoord= float3(vertex.texcoord, vsout.position.w);
	vsout.tangent= vertex.tangent;
	vsout.binormal= vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world= Camera_Position-vertex.position;
	
	float ambient_occlusion= prt_c0;
	float lighting_c0= 	dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));			// ###ctchou $PERF convert to monochrome before passing in!
	float ravi_mono= (0.886227f * lighting_c0)/3.1415926535f;
	float prt_mono= ambient_occlusion * lighting_c0;
		
	prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
	ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
	float prt_ravi_ratio= prt_mono /ravi_mono;
	vsout.prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
	vsout.prt_ravi_diff.y= prt_mono;														// unused
	vsout.prt_ravi_diff.z= (ambient_occlusion * 3.1415926535f)/0.886227f;					// specular occlusion % (ambient occlusion)
	vsout.prt_ravi_diff.w= min(dot(vsout.normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction.xyz, vsout.inscatter.xyz);

	return vsout;
} // static_prt_ambient_vs



/*#ifndef __GLASS_FX_H__
#define __GLASS_FX_H__
#pragma once
/*
GLASS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
1/16/2007 1:08:55 PM (haochen)
	glass render method


#include "hlsl_constant_mapping.fx"
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"
#include "render_target.fx"
#include "blend.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"
#include "shadow_generate.fx"
//#include "clip_plane.fx"
#include "dynamic_light_clip.fx"

//tinting
float3 tint_color;
void calc_tinting_constant_color_ps(in float2 texcoord, out float4 tinting)
{
	tinting= float4(tint_color, 1.0f);
}

PARAM_SAMPLER_2D(tint_texture);
PARAM(float4, tint_texture_xform);
void calc_tinting_texture_ps(in float2 texcoord, out float4 tinting)
{
	tinting= sample2D(tint_texture,   transform_texcoord(texcoord, tint_texture_xform));
}

void calc_bump_mapping_default_ps()
{
}

PARAM_SAMPLER_2D(reflection_cubemap);
PARAM(float4, reflection_cubemap_xform);
float3 calc_reflection_static_cubemap_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir)
{
	reflect_dir.y= -reflect_dir.y;
	float3 reflection= texCUBE(reflection_cubemap, reflect_dir);
	return reflection;
}

float3 calc_reflection_dyanamic_cubemap_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir)
{
	return float3(1.0f, 1.0f, 1.0f);
}

float3 calc_reflection_realtime_reflection_ps(
	in float3 view_dir,
	in float3 normal,
	in float3 reflect_dir)
{
	return float3(1.0f, 1.0f, 1.0f);
}

void calc_refraction_static_texture_ps()
{
}

void calc_refraction_scene_ps()
{
}

void calc_weathering_rain_streak_ps()
{
}

void calc_weathering_snow_dust_ps()
{
}

void albedo_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0)
{
	float4 local_to_world_transform[3];
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	// normal, tangent and binormal are all in world space
	texcoord= vertex.texcoord;
	
	CALC_CLIP(position);
}

float4 albedo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	CLIP_INPUT
	in float2 original_texcoord : TEXCOORD0) : SV_Target0
{
	float4 tinting;
	calc_tinting_ps(original_texcoord, tinting);
	return tinting;
}

void static_per_pixel_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD3,
	out float3 binormal : TEXCOORD4,
	out float3 tangent : TEXCOORD5,
	out float2 lightmap_texcoord : TEXCOORD6,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	normal= vertex.normal;
	texcoord= vertex.texcoord;
	lightmap_texcoord= lightmap.texcoord;
	tangent= vertex.tangent;
	binormal= vertex.binormal;

	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	CALC_CLIP(position);
}

accum_pixel static_per_pixel_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD3,
	in float3 binormal : TEXCOORD4,
	in float3 tangent : TEXCOORD5,
	in float2 lightmap_texcoord : TEXCOORD6_centroid,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1
	) : SV_Target
{
	float4 out_color= float4(1.0f, 1.0f, 1.0f, 1.0f);		
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false);
}


void static_sh_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float2 lightmap_texcoord : TEXCOORD4,
	out float3 fragment_to_camera_world : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	normal= vertex.normal;
	texcoord= vertex.texcoord;
	lightmap_texcoord= lightmap.texcoord;
	tangent= vertex.tangent;
	binormal= vertex.binormal;

	fragment_to_camera_world= Camera_Position-vertex.position;

	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	CALC_CLIP(position);
}

accum_pixel static_sh_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float2 lightmap_texcoord : TEXCOORD4_centroid,
	in float3 fragment_to_camera_world : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1
	) : SV_Target
{
	
	//tint color
#if DX_VERSION == 11
	float4 tint = albedo_texture.Load(int3(fragment_position.xy, 0));
#else
	float4 tint= sample2D(albedo_texture, (fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy);
#endif
	
	//environment map
	float3 view_dir= normalize(fragment_to_camera_world);
	float3 nromal_dir= normal;
	float3 reflect_dir= normalize( (dot(view_dir, nromal_dir) * nromal_dir - view_dir) * 2 + view_dir );
	float3 reflection= calc_reflection_ps(view_dir, nromal_dir, reflect_dir);
	float4 out_color= float4(reflection, 0.0f);		
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false);
}

void dynamic_light_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
#if DX_VERSION == 11	
	out s_dynamic_light_clip_distance clip_distance,
#endif
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float4 fragment_position_shadow : TEXCOORD5)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	normal= vertex.normal;
	texcoord= vertex.texcoord;
	tangent= vertex.tangent;
	binormal= vertex.binormal;

	fragment_position_shadow= mul(float4(vertex.position, 1.0f), Shadow_Projection);
	
#if DX_VERSION == 11
	clip_distance = calc_dynamic_light_clip_distance(position);
#endif
}

accum_pixel dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
#if DX_VERSION == 11	
	in s_dynamic_light_clip_distance clip_distance,
#endif
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float4 fragment_position_shadow : TEXCOORD5)
{
	float4 out_color= float4(1.0f, 1.0f, 1.0f, 1.0f);		
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false);
}

#endif //__GLASS_FX_H__
*/