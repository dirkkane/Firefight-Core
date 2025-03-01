#include "hlsl_constant_mapping.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#define GAMMA2 true

#define NO_ALPHA_TO_COVERAGE

#include "bump_mapping_util.fx"

#include "utilities.fx"
#include "albedo_pass.fx"
#include "render_target.fx"
#include "deform.fx"
#include "texture_xform.fx"
#include "environment_mapping.fx"
#include "spherical_harmonics.fx"
#include "simple_lights.fx"
#include "debug_modes.fx"
#include "entry.fx"
#include "hlsl_constant_mapping.fx"

#include "lightmap_sampling.fx"
#include "dynamic_light_clip.fx"

#define DETAIL_MULTIPLIER 4.59479f

PARAM(float4, debug_tint);

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


void apply_pc_albedo_modifier(
	inout float4 albedo,
	in float3 normal)
{
	albedo.rgb= lerp(albedo.rgb, debug_tint.rgb, debug_tint.a);
	
	//if (p_shader_pc_albedo_lighting!=0.f)
	//{
	//	albedo.xyz= calc_pc_albedo_lighting(albedo, normal);
	//}
}


void calc_alpha_test_ps(in float2 texcoord, out float output_alpha)
{
	output_alpha = 1.0f;
}
#include "atmosphere.fx"
#include "shadow_generate.fx"

//=============================================================================
//categories
//	- blending
//	- environment_map
//	- material_0
//	- material_1
//	- material_2
//	- material_3
//=============================================================================


//================
// parameters
//================


PARAM_SAMPLER_2D(blend_map);
PARAM(float4, blend_map_xform);

PARAM(float, global_albedo_tint);

#define ACTIVE_MATERIAL(material_type) ACTIVE_##material_type
#define ACTIVE_diffuse_only 1
#define ACTIVE_diffuse_plus_specular 1
#define ACTIVE_diffuse_only_plus_self_illum 1
#define ACTIVE_diffuse_plus_specular_plus_self_illum 1
#define ACTIVE_off 0
#define ACTIVE_MATERIAL_COUNT (ACTIVE_MATERIAL(material_0_type) + ACTIVE_MATERIAL(material_1_type) + ACTIVE_MATERIAL(material_2_type) + ACTIVE_MATERIAL(material_3_type))

#define SPECULAR_MATERIAL(material_type) SPECULAR_##material_type
#define SPECULAR_diffuse_only 0
#define SPECULAR_diffuse_plus_specular 1
#define SPECULAR_diffuse_only_plus_self_illum 0
#define SPECULAR_diffuse_plus_specular_plus_self_illum 1
#define SPECULAR_off 0
#define SPECULAR_MATERIAL_COUNT (SPECULAR_MATERIAL(material_0_type) + SPECULAR_MATERIAL(material_1_type) + SPECULAR_MATERIAL(material_2_type) + SPECULAR_MATERIAL(material_3_type))

#define SELF_ILLUM_MATERIAL(material_type) SELF_ILLUM_##material_type
#define SELF_ILLUM_diffuse_only 0
#define SELF_ILLUM_diffuse_plus_specular 0
#define SELF_ILLUM_diffuse_only_plus_self_illum 1
#define SELF_ILLUM_diffuse_plus_specular_plus_self_illum 1
#define SELF_ILLUM_off 0
#if ENTRY_POINT(entry_point) == ENTRY_POINT_dynamic_light || ENTRY_POINT(entry_point) == ENTRY_POINT_dynamic_light_cinematic
   #define SELF_ILLUM_MATERIAL_COUNT 0
#else
   #define SELF_ILLUM_MATERIAL_COUNT (SELF_ILLUM_MATERIAL(material_0_type) + SELF_ILLUM_MATERIAL(material_1_type) + SELF_ILLUM_MATERIAL(material_2_type) + SELF_ILLUM_MATERIAL(material_3_type))
#endif

#define DETAIL_BUMP_ENABLED (ACTIVE_MATERIAL_COUNT < 4)

#define MORPH_DYNAMIC(blend_option) MORPH_##blend_option
#define MORPH_morph 0
#define MORPH_dynamic 1


#if MORPH_DYNAMIC(blend_type)
	PARAM(float4, dynamic_material);
	PARAM(float, transition_sharpness);
	PARAM(float, transition_threshold);
#endif // MORPH_DYNAMIC


#define DECLARE_MATERIAL(material_number)							\
PARAM_SAMPLER_2D(base_map_m_##material_number);						\
PARAM(float4, base_map_m_##material_number##_xform);				\
PARAM_SAMPLER_2D(detail_map_m_##material_number);					\
PARAM(float4, detail_map_m_##material_number##_xform);				\
PARAM_SAMPLER_2D(bump_map_m_##material_number);						\
PARAM(float4, bump_map_m_##material_number##_xform);				\
PARAM_SAMPLER_2D(detail_bump_m_##material_number);					\
PARAM(float4, detail_bump_m_##material_number##_xform);				\
PARAM(float, diffuse_coefficient_m_##material_number);				\
PARAM(float, specular_coefficient_m_##material_number);				\
PARAM(float, specular_power_m_##material_number);					\
PARAM(float3, specular_tint_m_##material_number);					\
PARAM(float, fresnel_curve_steepness_m_##material_number);			\
PARAM(float, area_specular_contribution_m_##material_number);		\
PARAM(float, analytical_specular_contribution_m_##material_number);	\
PARAM(float, environment_specular_contribution_m_##material_number);\
PARAM(float, albedo_specular_tint_blend_m_##material_number);		\
PARAM_SAMPLER_2D(self_illum_map_m_##material_number);				\
PARAM(float4, self_illum_map_m_##material_number##_xform);			\
PARAM_SAMPLER_2D(self_illum_detail_map_m_##material_number);		\
PARAM(float4, self_illum_detail_map_m_##material_number##_xform);	\
PARAM(float4, self_illum_color_m_##material_number);				\
PARAM(float, self_illum_intensity_m_##material_number);

DECLARE_MATERIAL(0);
DECLARE_MATERIAL(1);
DECLARE_MATERIAL(2);
DECLARE_MATERIAL(3);


float4 sample_blend_normalized(float2 texcoord)
{

	float4 blend= sample2D(blend_map, transform_texcoord(texcoord, blend_map_xform));
	//blend += 0.00000001f;			// this gets rid of pure black pixels in the blend map.  We've decided that this isn't worth the instruction - just change your blend map

	#if MORPH_DYNAMIC(blend_type)
		// alpha blend dynamic material
		float alpha= (blend.w - transition_threshold) * transition_sharpness;
		blend.w= 0.0f;
		blend= lerp(blend, dynamic_material, saturate(alpha));
	#endif // MORPH_DYNAMIC
	
	float blend_sum= 0.0f;
	#if ACTIVE_MATERIAL(material_0_type)
		blend_sum += blend.x;
	#endif
	#if ACTIVE_MATERIAL(material_1_type)
		blend_sum += blend.y;
	#endif
	#if ACTIVE_MATERIAL(material_2_type)
		blend_sum += blend.z;
	#endif
	#if ACTIVE_MATERIAL(material_3_type)
		blend_sum += blend.w;
	#endif
	
	blend.xyzw= (blend.xyzw) / blend_sum;		// normalize blend so that the sum of active channels is 1.0

	return blend;
}


float4 sample_blend_normalized_for_lighting(float2 texcoord)
{
#if SPECULAR_MATERIAL_COUNT > 0 || SELF_ILLUM_MATERIAL_COUNT > 0
	return sample_blend_normalized(texcoord);
#else
	return 1.0f / ACTIVE_MATERIAL_COUNT;
#endif
}


void calc_bumpmap(
	in bool bSelfIllum,
	in float2 texcoord,
	in texture_sampler_2d bump_map,
	in float4 bump_map_xform,
	in texture_sampler_2d detail_bump,
	in float4 detail_bump_xform,
	out float3 bump)
{
	bump= sample2D(bump_map, transform_texcoord(texcoord, bump_map_xform)).xyz;
#if DX_VERSION == 9																	
   bump.xy = BUMP_CONVERT(bump.xy);
#endif

#if DETAIL_BUMP_ENABLED
   if (!bSelfIllum) {
	float2 detail= sample2D(detail_bump, transform_texcoord(texcoord, detail_bump_xform)).xy;
	#if DX_VERSION == 9																	
		detail.xy = BUMP_CONVERT(detail.xy);
	#endif
	bump.xy += detail.xy;
   }
#endif

	bump.z= saturate(bump.x*bump.x + bump.y*bump.y);
	bump.z= sqrt(1 - bump.z);
}

float4 calc_detail(
	in bool bSelfIllum,
	in float2 texcoord,
	in texture_sampler_2d detail_map,
	in float4 detail_map_xform
)
{
   if (bSelfIllum) {
      return 1.0f / DETAIL_MULTIPLIER;
   } else {
      return sample2D(detail_map, transform_texcoord(texcoord, detail_map_xform));
   }
}

void calc_phong_outgoing_light(
	// geometric parameters in world space
	in float3	normal_dir,
	in float3	view_dir,
	in float3	reflection_dir,
	in float	n_dot_v,
	// phong lobe parameters
	in float	specular_power,
	// incident light parameters
	in float3	analytical_light_dir,
	in float3	analytical_light_color,
	// outgoing light (towards view)
	out float3	analytical_specular_light)
{
    // calculate analyical specular light
	float n_dot_l = dot(normal_dir, analytical_light_dir);
    float l_dot_r = max(dot(analytical_light_dir, reflection_dir), 0.0f);    
    if (n_dot_l > 0 && n_dot_v > 0 )
    {
		analytical_specular_light= analytical_light_color * (pow(l_dot_r, specular_power) * ((specular_power + 1.0f) / 6.2832));
	}
	else
	{
		analytical_specular_light= 0.0f;
	}
}

//=============================================================================
//entry points
//	- albedo
//	- static_per_pixel
//	- static_per_vertex
//	- static_sh
//	- shadow_apply
//	- dynamic_light
//=============================================================================


void default_vertex_transform_vs(
	inout vertex_type vertex,
	out float4 position,
	out float2 texcoord,
	out float4 normal,
	out float3 binormal,
	out float3 tangent,
	out float3 fragment_to_camera_world,
	out float4 local_to_world_transform[3])
{
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);

	texcoord= vertex.texcoord;
	normal.xyz= vertex.normal;
	normal.w= position.w;
	tangent= vertex.tangent;
	binormal= vertex.binormal;

	// world space vector from vertex to eye/camera
	fragment_to_camera_world= Camera_Position - vertex.position;
}


//================
// albedo
//================

void albedo_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float4 texcoord : TEXCOORD0,
	out float4 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3)
{
	float3 fragment_to_camera_world;
	float4 local_to_world_transform_UNUSED[3];
	default_vertex_transform_vs(vertex, position, texcoord.xy, normal, binormal, tangent, fragment_to_camera_world, local_to_world_transform_UNUSED);
	texcoord.zw= 1.0f;
	//clip_distance = dot(position, v_clip_plane);
}


#define COMPILER_IFANY
#define COMPILER_PREDBLOCK
#define COMPILER_PREDICATE
#define COMPILER_BRANCH

#define ACCUMULATE_MATERIAL_ALBEDO_AND_BUMP(material, blend_amount, albedo_accumulate, blendweight, bump)														\
COMPILER_IFANY																																					\
if (blend_amount > 0.0)																																			\
{																																								\
	float4 base=	sample2D(base_map_m_##material,	transform_texcoord(original_texcoord.xy, base_map_m_##material##_xform));									\
	float4 detail=	calc_detail(SELF_ILLUM_MATERIAL(material_##material##_type), original_texcoord, detail_map_m_##material, detail_map_m_##material##_xform);	\
	albedo_accumulate += base * detail * blendweight;																											\
	{																																							\
		float3 material_bump_normal;																															\
		calc_bumpmap(																																			\
			SELF_ILLUM_MATERIAL(material_##material##_type),																									\
			original_texcoord.xy,																																\
			bump_map_m_##material,																																\
			bump_map_m_##material##_xform,																														\
			detail_bump_m_##material,																															\
			detail_bump_m_##material##_xform,																													\
			material_bump_normal);																																\
			bump += material_bump_normal * blend_amount;																										\
	}																																							\
}

albedo_pixel albedo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	//in float clip_distance : SV_ClipDistance,
	in float4 original_texcoord : TEXCOORD0,
	in float4 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3)
{
	
	float4 blend;
	float4 blend2;

	blend= sample_blend_normalized(original_texcoord.xy);
	
	float4 albedo= 0.0f;
	float3 bump_normal= 0.0f;

	#if ACTIVE_MATERIAL(material_0_type)
		ACCUMULATE_MATERIAL_ALBEDO_AND_BUMP(0, blend.x, albedo, blend.xxxx, bump_normal);
	#endif
	
	#if ACTIVE_MATERIAL(material_1_type)	
		ACCUMULATE_MATERIAL_ALBEDO_AND_BUMP(1, blend.y, albedo, blend.yyyy, bump_normal);

	#endif

	#if ACTIVE_MATERIAL(material_2_type)
		ACCUMULATE_MATERIAL_ALBEDO_AND_BUMP(2, blend.z, albedo, blend.zzzz, bump_normal);
	#endif
	
	#if ACTIVE_MATERIAL(material_3_type)
		ACCUMULATE_MATERIAL_ALBEDO_AND_BUMP(3, blend.w, albedo, blend.wwww, bump_normal);
	#endif
	albedo.xyz *= global_albedo_tint * DETAIL_MULTIPLIER;
//	bump_normal.z= saturate(bump_normal.x*bump_normal.x + bump_normal.y*bump_normal.y);		// recalculating Z here saves a few GPRs and ALUs ...  but not as contrasty bump.  We're always texture bound anyways, so leave this out
//	bump_normal.z= sqrt(1 - bump_normal.z);
	bump_normal= normalize(bump_normal);

#ifndef ALPHA_OPTIMIZATION
	normal.xyz= normalize(normal.xyz);
	binormal= normalize(binormal);
	tangent= normalize(tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = {tangent, binormal, normal.xyz};

	// rotate bump normal into world space
	bump_normal= mul(bump_normal, tangent_frame);

	apply_pc_albedo_modifier(albedo, bump_normal);

	return convert_to_albedo_target(albedo, bump_normal, normal.w, tangent_frame[2]);
}

#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_pixel

struct entry_point_data
{
	float2 lightmap_texcoord;
};
#define BUILD_ENTRY_POINT_DATA(data)	{ data.lightmap_texcoord= lightmap_texcoord; }

void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[4],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{

	float3 sh_coefficients[4];
	
	sample_lightprobe_texture(
		data.lightmap_texcoord,
		sh_coefficients,
		dominant_light_direction,
		dominant_light_intensity);		

	pack_constants_texture_array_linear(sh_coefficients, sh_lighting_coefficients);	
}

void get_sh_coefficients_order3(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
}

#elif ((ENTRY_POINT(entry_point) == ENTRY_POINT_static_sh) || (ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_quadratic) || (ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_linear) || (ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_ambient))

struct entry_point_data
{
	float4 unused;
};
#define BUILD_ENTRY_POINT_DATA(data)	{ data.unused= 0.0f; }
void get_sh_coefficients_order3(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
	sh_lighting_coefficients[0]= p_lighting_constant_0;
	sh_lighting_coefficients[1]= p_lighting_constant_1; 
	sh_lighting_coefficients[2]= p_lighting_constant_2; 
	sh_lighting_coefficients[3]= p_lighting_constant_3; 
	sh_lighting_coefficients[4]= p_lighting_constant_4; 
	sh_lighting_coefficients[5]= p_lighting_constant_5; 
	sh_lighting_coefficients[6]= p_lighting_constant_6; 
	sh_lighting_coefficients[7]= p_lighting_constant_7; 
	sh_lighting_coefficients[8]= p_lighting_constant_8; 
	sh_lighting_coefficients[9]= p_lighting_constant_9;
	dominant_light_direction= k_ps_dominant_light_direction;
	dominant_light_intensity= k_ps_dominant_light_intensity;
}

void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[4],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
}

#elif ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_vertex

struct entry_point_data
{
	float4	p0_3_r;
	float4	p0_3_g;
	float4	p0_3_b;
	float3 dominant_light_intensity;
};

#define BUILD_ENTRY_POINT_DATA(data){ data.p0_3_r= p0_3_r;	data.p0_3_g= p0_3_g;	data.p0_3_b= p0_3_b; data.dominant_light_intensity= dominant_light_intensity;}
void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[4],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
	dominant_light_direction= data.p0_3_r.wyz * 0.212656f + data.p0_3_g.wyz * 0.715158f + data.p0_3_b.wyz * 0.0721856f;
	dominant_light_direction= dominant_light_direction * float3(-1.0f, -1.0f, 1.0f);
	dominant_light_direction= normalize(dominant_light_direction);
	float4 L0_3[3]= {data.p0_3_r, data.p0_3_g, data.p0_3_b};
	pack_constants_linear(L0_3, sh_lighting_coefficients);
	dominant_light_intensity= data.dominant_light_intensity;
}

void get_sh_coefficients_order3(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
}

#else

struct entry_point_data
{
};
#define BUILD_ENTRY_POINT_DATA(data)	ERROR_you_must_define_entry_point

void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[4],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
	sh_lighting_coefficients[0]= float4(1.0f, 0.0f, 1.0f, 0.0f);
	sh_lighting_coefficients[1]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[2]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[3]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	dominant_light_direction= 0.0f;
	dominant_light_intensity= 0.0f;
}

void get_sh_coefficients_order3(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{
}

#endif


float3 get_constant_analytical_light_dir_vs()
{
 	return -normalize(v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz);		// ###ctchou $PERF : pass this in as a constant
}



//===================
// static_per_pixel
//===================

void static_per_pixel_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float4 lightmap_texcoord : TEXCOORD4,
	out float3 fragment_to_camera_world : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform_UNUSED[3];
	float4 normal4 = float4(normal.xyz,1);
	default_vertex_transform_vs(vertex, position, texcoord, normal4, binormal, tangent, fragment_to_camera_world, local_to_world_transform_UNUSED);
	normal = normal4.xyz;
	lightmap_texcoord= float4(lightmap.texcoord, 0, 0);

	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	//clip_distance = dot(position, v_clip_plane);
}


struct specular_parameters
{
	float4 normal_albedo;			// specular albedo along normal (plus albedo blend in alpha)
	float power;					// specular power
	float analytical;				// analytical contribution	(* specular contribution)
	float area;						// area contribution		(* specular contribution)
	float envmap;					// envmap contribution		(* specular contribution)

	float fresnel_steepness;		// averaged across specular only
	float weight;
};

#define BLEND_SPECULAR(material_postfix, blend_amount, specular)						\
	blend_specular_parameters(															\
		blend_amount,																	\
		specular_tint_##material_postfix,												\
		albedo_specular_tint_blend_##material_postfix,									\
		specular_power_##material_postfix,												\
		specular_coefficient_##material_postfix,										\
		analytical_specular_contribution_##material_postfix,							\
		area_specular_contribution_##material_postfix,									\
		environment_specular_contribution_##material_postfix,							\
		fresnel_curve_steepness_##material_postfix,										\
		specular)


void blend_specular_parameters(
	in float blend_amount,
	in float3 specular_tint,
	in float albedo_specular_tint_blend,
	in float specular_power,
	in float specular_coefficient,
	in float analytical_specular_contribution,
	in float area_specular_contribution,
	in float environment_specular_contribution,
	in float fresnel_steepness,
	inout specular_parameters specular)
{
	specular.normal_albedo.rgb		+= blend_amount * specular_tint * (1.0 - albedo_specular_tint_blend);
	specular.normal_albedo.w		+= blend_amount * albedo_specular_tint_blend;
	
	specular.power					+= blend_amount * specular_power;
	specular.analytical				+= blend_amount * specular_coefficient * analytical_specular_contribution;			// ###ctchou $PERF can move specular_coefficient outside this blend
	specular.area					+= blend_amount * specular_coefficient * area_specular_contribution;
	specular.envmap					+= blend_amount * specular_coefficient * environment_specular_contribution;
		
	specular.fresnel_steepness		+= blend_amount * fresnel_steepness;
	specular.weight					+= blend_amount;
}

#define BLEND_SELF_ILLUM(material_number, texcoord)						\
	blend_self_illum(													\
		texcoord,														\
		self_illum_map_m_##material_number,								\
		self_illum_map_m_##material_number##_xform,						\
		self_illum_detail_map_m_##material_number,						\
		self_illum_detail_map_m_##material_number##_xform,				\
		self_illum_color_m_##material_number.rgb,						\
		self_illum_intensity_m_##material_number)


float3 blend_self_illum(
	in float2 texcoord,
	in texture_sampler_2d self_illum_map,
	in float4 self_illum_map_xform,
	in texture_sampler_2d self_illum_detail_map,
	in float4 self_illum_detail_map_xform,
	in float3 self_illum_color,
	in float self_illum_intensity)
{
	float3 self_illum = sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	float3 self_illum_detail = sample2D(self_illum_detail_map, transform_texcoord(texcoord, self_illum_detail_map_xform)).rgb;
	float3 result = self_illum * (self_illum_detail * DETAIL_MULTIPLIER) * self_illum_color;

	result.rgb *= self_illum_intensity;

	return result.rgb;
}



void blend_surface_parameters(
	in float2 texcoord,
	in float4 blend,
	out float diffuse_coefficient,
	out specular_parameters specular,
	out float3 self_illum)
{
	// calculate blended normal and diffuse coefficient
	diffuse_coefficient= 0.0f;

	{
		#if ACTIVE_MATERIAL(material_0_type)
//		if (blend.x)
		{
			#if SPECULAR_MATERIAL(material_0_type)
				diffuse_coefficient += diffuse_coefficient_m_0 * blend.x;
			#else
				diffuse_coefficient += blend.x;
			#endif
		}
		#endif

		#if ACTIVE_MATERIAL(material_1_type)
//		if (blend.y)
		{
			#if SPECULAR_MATERIAL(material_1_type)
				diffuse_coefficient += diffuse_coefficient_m_1 * blend.y;
			#else
				diffuse_coefficient += blend.y;
			#endif
		}
		#endif

		#if ACTIVE_MATERIAL(material_2_type)
//		if (blend.z)
		{
			#if SPECULAR_MATERIAL(material_2_type)
				diffuse_coefficient += diffuse_coefficient_m_2 * blend.z;
			#else
				diffuse_coefficient += blend.z;
			#endif
		}
		#endif

		#if ACTIVE_MATERIAL(material_3_type)
//		if (blend.w)
		{
			#if SPECULAR_MATERIAL(material_3_type)
				diffuse_coefficient += diffuse_coefficient_m_3 * blend.w;
			#else
				diffuse_coefficient += blend.w;
			#endif
		}
		#endif
	}

	// calculate specular parameters
	specular.normal_albedo= 0.0f;
	specular.power= 0.001f * 1.0f;				// default power is 1.0, default weight is 0.001
	specular.analytical= 0.0f;
	specular.area= 0.0f;
	specular.envmap= 0.0f;
	specular.fresnel_steepness= 0.001f * 5.0f;	// default steepness is 5.0
	specular.weight= 0.001f;					// add a teeny bit of initial weight, just to ensure no divide by zero in the final normalization

	#if SPECULAR_MATERIAL_COUNT > 0
	{	
		#if SPECULAR_MATERIAL(material_0_type)
			BLEND_SPECULAR(m_0, blend.x, specular);
		#endif
		
		#if SPECULAR_MATERIAL(material_1_type)
			BLEND_SPECULAR(m_1,	blend.y, specular);
		#endif
		
		#if SPECULAR_MATERIAL(material_2_type)
			BLEND_SPECULAR(m_2, blend.z, specular);
		#endif
		
		#if SPECULAR_MATERIAL(material_3_type)
			BLEND_SPECULAR(m_3, blend.w, specular);
		#endif
		
		// divide out specular weight for 'specular only weighted-blend'
		float scale= 1.0f / max(specular.weight, 0.001f);		// ###ctchou $PERF don't think we need the max()
		specular.fresnel_steepness *= scale;
		specular.power *= scale;
	}
	#endif

	// calculate self illum
	self_illum = 0.0f;
	#if SELF_ILLUM_MATERIAL_COUNT > 0
		#if SELF_ILLUM_MATERIAL(material_0_type)
			self_illum = BLEND_SELF_ILLUM(0, texcoord) * blend.x;
		#endif

		#if SELF_ILLUM_MATERIAL(material_1_type)
			self_illum += BLEND_SELF_ILLUM(1, texcoord) * blend.y;
		#endif

		#if SELF_ILLUM_MATERIAL(material_2_type)
			self_illum += BLEND_SELF_ILLUM(2, texcoord) * blend.z;
		#endif
	#endif
}

#ifdef PIXEL_SHADER
accum_pixel static_lighting_shared_ps_quadratic(
	in struct entry_point_data data,
	in float2 fragment_position,
	in float2 original_texcoord,
	in float3 normal,
	in float3 binormal,
	in float3 tangent,
	in float3 fragment_to_camera_world,
	in float3 extinction,
	in float3 inscatter)
{	
	float4 sh_lighting_coefficients[10];
	float3 dominant_light_direction;
	float3 dominant_light_intensity;
	
	get_sh_coefficients_order3(data, sh_lighting_coefficients, dominant_light_direction, dominant_light_intensity);

	// get blend values
	float4 blend= sample_blend_normalized_for_lighting(original_texcoord);
	
	// calculate blended surface parameters
	float diffuse_coefficient;
	specular_parameters specular;
	float3 self_illum;
	blend_surface_parameters(
		original_texcoord,
		blend,		
		diffuse_coefficient,
		specular,
		self_illum);

	// normalize interpolated values

#ifndef ALPHA_OPTIMIZATION
	normal= normalize(normal);
	binormal= normalize(binormal);
	tangent= normalize(tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = {tangent, binormal, normal};

	// rotate bump normal into world space
	
	#if DX_VERSION == 11
		float3 bump_normal = normal_texture.Load(int3(fragment_position.xy, 0)).xyz * 2.0f - 1.0f;
	#else
		float3 bump_normal= tex2D(normal_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy) * 2.0f - 1.0f;
	#endif

	float3 simple_light_diffuse_light;//= 0.0f;
	float3 simple_light_specular_light;//= 0.0f;
		float3 view_dir			= normalize(fragment_to_camera_world);
		
		///  DESC: 18 7 2007   13:49 BUNGIE\yaohhu :
		///    do not need normlize, but bump_normal is not normalized. It is possible incorrect before/after optimization.
		///float3 view_reflect_dir	= normalize( (dot(view_dir, bump_normal) * bump_normal - view_dir) * 2 + view_dir );
		float3 view_reflect_dir	= -normalize(reflect(view_dir, bump_normal));

		float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
		calc_simple_lights_analytical(
			fragment_position_world,
			bump_normal,
			view_reflect_dir,												// view direction = fragment to camera,   reflected around fragment normal
			specular.power,
			simple_light_diffuse_light,
			simple_light_specular_light);

	#if DX_VERSION == 11
		float4 albedo = albedo_texture.Load(int3(fragment_position.xy, 0));
	#else
		float4 albedo= tex2D(albedo_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy);
	#endif

	// if any material is active, evaluate the diffuse lobe
	
	float3 diffuse_light= 0.0f;
	diffuse_light= ravi_order_3(bump_normal, sh_lighting_coefficients);

	// if any material is specular, evaluate the combined specular lobe
	float3 analytical_specular_light= 0.0f;
	float3 area_specular_light= 0.0f;
	float3 specular_tint= 0.0f;
	float3 envmap_light= 0.0f;
	float4 ssr_color = 0.0f;
	#if SPECULAR_MATERIAL_COUNT > 0
	
		float n_dot_v			= dot( bump_normal, view_dir );

		calc_phong_outgoing_light(
			bump_normal,
			view_dir,
			view_reflect_dir,
			n_dot_v,
			specular.power,
			dominant_light_direction,
			dominant_light_intensity,
			analytical_specular_light);

		area_specular_light= ravi_order_3(view_reflect_dir, sh_lighting_coefficients);
		area_specular_light= max(0.0f, area_specular_light);

		// calculate full specular tint
	    float3 normal_tint= lerp(specular.normal_albedo.rgb, albedo.rgb, specular.normal_albedo.w);			// first blend in appropriate amounts of the diffuse albedo
		float fresnel_blend		= pow((1.0f - clamp(n_dot_v, 0.0f, 1.0f)), specular.fresnel_steepness);		// 
		specular_tint			= lerp(normal_tint, float3(1.0f, 1.0f, 1.0f), fresnel_blend);				// then blend that to white at glancing angles

		envmap_light= CALC_ENVMAP(envmap_type)(
			view_dir,
			bump_normal,
			view_reflect_dir,
			float4(1.0f, 1.0f, 1.0f, max(0.01f, 1.01 - specular.power / 200.0f)),		// convert specular power to roughness (cheap and bad approximation)
			area_specular_light,
			ssr_color);
	#endif

	// mix all light and albedo's together
	float4 out_color;
	out_color.a= 1.0f;

	// diffuse light	
	out_color.rgb= albedo.rgb * (diffuse_light + simple_light_diffuse_light) * diffuse_coefficient;

	// specular light
	#if SPECULAR_MATERIAL_COUNT > 0
		out_color.rgb += albedo.w * specular_tint * 
							(envmap_light * specular.envmap +
							area_specular_light * specular.area +
							(simple_light_specular_light + analytical_specular_light) * specular.analytical);
	#endif

	// self illum
	#if SELF_ILLUM_MATERIAL_COUNT > 0
		out_color.rgb += self_illum;
	#endif

	out_color.rgb= (out_color.rgb * extinction + inscatter) * g_exposure.rrr;
	return convert_to_render_target(out_color, true, false
#ifdef SSR_ENABLE
		, ssr_color
#endif
	);	
}

accum_pixel static_lighting_shared_ps_linear_with_dominant_light(
	in struct entry_point_data data,
	in float2 fragment_position,
	in float2 original_texcoord,
	in float3 normal,
	in float3 binormal,
	in float3 tangent,
	in float3 fragment_to_camera_world,
	in float3 extinction,
	in float3 inscatter)
{	
	float4 sh_lighting_coefficients[4];
	float3 dominant_light_direction;
	float3 dominant_light_intensity;
	
	get_sh_coefficients(data, sh_lighting_coefficients, dominant_light_direction, dominant_light_intensity);

	// get blend values
	float4 blend= sample_blend_normalized_for_lighting(original_texcoord);
	
	// calculate blended surface parameters
	float diffuse_coefficient;
	specular_parameters specular;
	float3 self_illum;
	blend_surface_parameters(
		original_texcoord,
		blend,		
		diffuse_coefficient,
		specular,
		self_illum);

	// normalize interpolated values

#ifndef ALPHA_OPTIMIZATION
	normal= normalize(normal);
	binormal= normalize(binormal);
	tangent= normalize(tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = {tangent, binormal, normal};

	#if DX_VERSION == 11
		float3 bump_normal = normal_texture.Load(int3(fragment_position.xy, 0)).xyz * 2.0f - 1.0f;
	#else
		float3 bump_normal= tex2D(normal_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy) * 2.0f - 1.0f;
	#endif

	float3 simple_light_diffuse_light;//= 0.0f;
	float3 simple_light_specular_light;//= 0.0f;
	float3 view_dir			= normalize(fragment_to_camera_world);
	///  DESC: 18 7 2007   13:49 BUNGIE\yaohhu :
	///    do not need normlize, but bump_normal is not normalized. It is possible incorrect before/after optimization.
	///float3 view_reflect_dir	= normalize( (dot(view_dir, bump_normal) * bump_normal - view_dir) * 2 + view_dir );
	float3 view_reflect_dir	= -normalize(reflect(view_dir, bump_normal));
	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
	calc_simple_lights_analytical(
		fragment_position_world,
		bump_normal,
		view_reflect_dir,												// view direction = fragment to camera,   reflected around fragment normal
		specular.power,
		simple_light_diffuse_light,
		simple_light_specular_light);

	#if DX_VERSION == 11
		float4 albedo = albedo_texture.Load(int3(fragment_position.xy, 0));
	#else
		float4 albedo= tex2D(albedo_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy);
	#endif

	// if any material is active, evaluate the diffuse lobe
	
	float3 diffuse_light= 0.0f;
	diffuse_light= ravi_order_2_with_dominant_light(bump_normal, sh_lighting_coefficients, dominant_light_direction, dominant_light_intensity);

	// if any material is specular, evaluate the combined specular lobe
	float3 analytical_specular_light= 0.0f;
	float3 area_specular_light= 0.0f;
	float3 specular_tint= 0.0f;
	float3 envmap_light= 0.0f;
	float4 ssr_color= 0.0f;
	#if SPECULAR_MATERIAL_COUNT > 0
	
		float n_dot_v			= dot( bump_normal, view_dir );

		calc_phong_outgoing_light(
			bump_normal,
			view_dir,
			view_reflect_dir,
			n_dot_v,
			specular.power,
			dominant_light_direction,
			dominant_light_intensity,
			analytical_specular_light);

		area_specular_light= ravi_order_2_new(view_reflect_dir, sh_lighting_coefficients);
		area_specular_light= max(0.0f, area_specular_light);

		// calculate full specular tint
	    float3 normal_tint= lerp(specular.normal_albedo.rgb, albedo.rgb, specular.normal_albedo.w);			// first blend in appropriate amounts of the diffuse albedo
		float fresnel_blend		= pow((1.0f - clamp(n_dot_v, 0.0f, 1.0f)), specular.fresnel_steepness);		// 
		specular_tint			= lerp(normal_tint, float3(1.0f, 1.0f, 1.0f), fresnel_blend);				// then blend that to white at glancing angles

		envmap_light= CALC_ENVMAP(envmap_type)(
			view_dir,
			bump_normal,
			view_reflect_dir,
			float4(1.0f, 1.0f, 1.0f, max(0.01f, 1.01 - specular.power / 200.0f)),		// convert specular power to roughness (cheap and bad approximation)
			area_specular_light,
			ssr_color);
	#endif

	// mix all light and albedo's together
	float4 out_color;
	out_color.a= 1.0f;

	// diffuse light	
	out_color.rgb= albedo.rgb * (diffuse_light + simple_light_diffuse_light) * diffuse_coefficient;

	// specular light
	#if SPECULAR_MATERIAL_COUNT > 0
		out_color.rgb += albedo.w * specular_tint * 
							(envmap_light * specular.envmap +
							area_specular_light * specular.area +
							(simple_light_specular_light + analytical_specular_light) * specular.analytical);
	#endif

	// self illum
	#if SELF_ILLUM_MATERIAL_COUNT > 0
		out_color.rgb += self_illum;
	#endif

	out_color.rgb= (out_color.rgb * extinction + inscatter) * g_exposure.rrr;
	return convert_to_render_target(out_color, true, false
#ifdef SSR_ENABLE
		, ssr_color
#endif
	);
}

#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_pixel
accum_pixel static_per_pixel_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in float clip_distance : SV_ClipDistance,
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float4 lightmap_texcoord : TEXCOORD4_centroid,
	in float3 fragment_to_camera_world : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)
{	
	entry_point_data data;
	BUILD_ENTRY_POINT_DATA(data);

	return static_lighting_shared_ps_linear_with_dominant_light(
		data,
		fragment_position,
		original_texcoord,
		normal,
		binormal,
		tangent,
		fragment_to_camera_world,
		extinction,
		inscatter);
		
}
#endif // ENTRY_POINT_static_per_pixel
#endif //PIXEL_SHADER

//===================
// static_per_vertex
//===================
#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_vertex
void static_per_vertex_vs(
	in vertex_type vertex,
	in float4 light_intensity : TEXCOORD3,
	in float4 c0_3_rgbe : TEXCOORD4,
	in float4 c1_1_rgbe : TEXCOORD5,
	in float4 c1_2_rgbe : TEXCOORD6,
	in float4 c1_3_rgbe : TEXCOORD7,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float4 texcoord : TEXCOORD0, // zw contains inscatter.xy
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 probe0_3_r : TEXCOORD5,
	out float4 probe0_3_g : TEXCOORD6,
	out float4 probe0_3_b : TEXCOORD7,
	out float3 dominant_light_intensity : TEXCOORD8,
	out float4 extinction : COLOR0) // w contains inscatter.z
//	out float3 inscatter : COLOR1)
{
   // on PC vertex lightnap is stored in unsigned format
   // convert to signed
   light_intensity = 2 * light_intensity - 1;
	c0_3_rgbe = 2 * c0_3_rgbe - 1;
	c1_1_rgbe = 2 * c1_1_rgbe - 1;
	c1_2_rgbe = 2 * c1_2_rgbe - 1;
	c1_3_rgbe = 2 * c1_3_rgbe - 1;

	float4 local_to_world_transform_UNUSED[3];
	float4 normal4 = float4(normal.xyz,1);
	default_vertex_transform_vs(vertex, position, texcoord.xy, normal4, binormal, tangent, fragment_to_camera_world, local_to_world_transform_UNUSED);	
	normal = normal4.xyz;
	//const real exponent_mult= 127.f/pow(2.f, fractional_exponent_bits); == 31.75f
	
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
		
	probe0_3_r= float4(c0_3_rgbe.r, c1_1_rgbe.r, c1_2_rgbe.r, c1_3_rgbe.r);
	probe0_3_g= float4(c0_3_rgbe.g, c1_1_rgbe.g, c1_2_rgbe.g, c1_3_rgbe.g);
	probe0_3_b= float4(c0_3_rgbe.b, c1_1_rgbe.b, c1_2_rgbe.b, c1_3_rgbe.b);
	
	dominant_light_intensity= light_intensity.xyz;
	
	float3 inscatter;
	compute_scattering(Camera_Position, vertex.position, extinction.xyz, inscatter);
	texcoord.zw  = inscatter.xy;
	extinction.w = inscatter.z;

	//clip_distance = dot(position, v_clip_plane);
}

#ifdef PIXEL_SHADER
accum_pixel static_per_vertex_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in float clip_distance : SV_ClipDistance,
	in float4 original_texcoord : TEXCOORD0, // zw contains inscatter.xy
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 p0_3_r : TEXCOORD5,
	in float4 p0_3_g : TEXCOORD6,
	in float4 p0_3_b : TEXCOORD7,
	in float3 dominant_light_intensity : TEXCOORD8,
	in float4 extinction : COLOR0) // w contains inscatter.z
//	in float3 inscatter : COLOR1)
{
	entry_point_data data;
	BUILD_ENTRY_POINT_DATA(data);

	return static_lighting_shared_ps_linear_with_dominant_light(
		data,
		fragment_position,
		original_texcoord.xy,
		normal,
		binormal,
		tangent,
		fragment_to_camera_world,
		extinction,
		float3(original_texcoord.z, original_texcoord.w, extinction.w));
}
#endif // PIXEL_SHADER
#endif // ENTRY_POINT_static_per_vertex


//================
// static_sh
//================

#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_sh
void static_sh_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform_UNUSED[3];
	float4 normal4 = float4(normal.xyz,1);
	default_vertex_transform_vs(vertex, position, texcoord, normal4, binormal, tangent, fragment_to_camera_world, local_to_world_transform_UNUSED);
	normal = normal4.xyz;
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	//clip_distance = dot(position, v_clip_plane);
}

#ifdef PIXEL_SHADER
accum_pixel static_sh_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in float clip_distance : SV_ClipDistance,
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)
{
	entry_point_data data;
	BUILD_ENTRY_POINT_DATA(data);
	return static_lighting_shared_ps_quadratic(
		data,
		fragment_position,
		original_texcoord,
		normal,
		binormal,
		tangent,
		fragment_to_camera_world,
		extinction,
		inscatter);
}
#endif  // PIXEL_SHADER
#endif	// ENTRY_POINT_static_sh


//================
// prt_quadratic
//================


void prt_quadratic(
	in float3 prt_c0_c2,
	in float3 prt_c3_c5,
	in float3 prt_c6_c8,	
	in float3 normal,
	float4 local_to_world_transform[3],
	out float4 prt_ravi_diff)
{
	// convert first 4 coefficients to monochrome
	float4 prt_c0_c3_monochrome= float4(prt_c0_c2.xyz, prt_c3_c5.x);			//(prt_c0_c3_r + prt_c0_c3_g + prt_c0_c3_b) / 3.0f;
	float4 SH_monochrome_3120;
	SH_monochrome_3120.xyz= (v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz) / 3.0f;			// ###ctchou $PERF convert to mono before passing in?
	SH_monochrome_3120.w= dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));
	
	// rotate the first 4 coefficients
	float4 SH_monochrome_local_0123;
	sh_inverse_rotate_0123_monochrome(
		local_to_world_transform,
		SH_monochrome_3120,
		SH_monochrome_local_0123);

	float prt_mono=		dot(SH_monochrome_local_0123, prt_c0_c3_monochrome);

	// convert last 5 coefficients to monochrome
	float4 prt_c4_c7_monochrome= float4(prt_c3_c5.yz, prt_c6_c8.xy);						//(prt_c4_c7_r + prt_c4_c7_g + prt_c4_c7_b) / 3.0f;
	float prt_c8_monochrome= prt_c6_c8.z;													//dot(prt_c8, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));
	float4 SH_monochrome_457= (v_lighting_constant_4 + v_lighting_constant_5 + v_lighting_constant_6) / 3.0f;
	float4 SH_monochrome_8866= (v_lighting_constant_7 + v_lighting_constant_8 + v_lighting_constant_9) / 3.0f;

	// rotate last 5 coefficients
	float4 SH_monochrome_local_4567;
	float SH_monochrome_local_8;
	sh_inverse_rotate_45678_monochrome(
		local_to_world_transform,
		SH_monochrome_457,
		SH_monochrome_8866,
		SH_monochrome_local_4567,
		SH_monochrome_local_8);

	prt_mono	+=	dot(SH_monochrome_local_4567, prt_c4_c7_monochrome);
	prt_mono	+=	SH_monochrome_local_8 * prt_c8_monochrome;

	float ravi_mono= ravi_order_3_monochromatic(normal, SH_monochrome_3120, SH_monochrome_457, SH_monochrome_8866);
	
	prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
	ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
	float prt_ravi_ratio= prt_mono / ravi_mono;
	prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
	prt_ravi_diff.y= prt_mono;														// unused
	prt_ravi_diff.z= (prt_c0_c3_monochrome.x * 3.1415926535f)/0.886227f;			// specular occlusion % (ambient occlusion)
	prt_ravi_diff.w= min(dot(normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
}


#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_quadratic
void static_prt_quadratic_vs(
	in vertex_type vertex,
	in float3 prt_c0_c2 : BLENDWEIGHT1,
	in float3 prt_c3_c5 : BLENDWEIGHT2,
	in float3 prt_c6_c8 : BLENDWEIGHT3,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 prt_ravi_diff : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];
	float4 normal4 = float4(normal.xyz,1);
	default_vertex_transform_vs(vertex, position, texcoord, normal4, binormal, tangent, fragment_to_camera_world, local_to_world_transform);
	normal = normal4.xyz;

	prt_quadratic(
		prt_c0_c2,
		prt_c3_c5,
		prt_c6_c8,
		normal,
		local_to_world_transform,
		prt_ravi_diff);
	
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	//clip_distance = dot(position, v_clip_plane);
}
#endif	// ENTRY_POINT_static_prt_quadratic


#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_linear
void static_prt_linear_vs(
	in vertex_type vertex,
	in float4 prt_c0_c3 : BLENDWEIGHT1,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 prt_ravi_diff : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];
	float4 normal4 = float4(normal.xyz,1);
	default_vertex_transform_vs(vertex, position, texcoord, normal4, binormal, tangent, fragment_to_camera_world, local_to_world_transform);
	normal = normal4.xyz;
   // on PC vertex linear PRT data is stored in unsigned format convert to signed
	prt_c0_c3 = 2 * prt_c0_c3 - 1;

	{	
		// new monochrome PRT/RAVI ratio calculation
		// convert to monochrome
		float4 prt_c0_c3_monochrome= prt_c0_c3;
		float4 SH_monochrome_3120;
		SH_monochrome_3120.xyz= (v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz) / 3.0f;		// ###ctchou $PERF convert to monochrome before setting the constants yo
		SH_monochrome_3120.w= dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));

		//rotate the first 4 coefficients	
		float4 SH_monochrome_local_0123;
		sh_inverse_rotate_0123_monochrome(
			local_to_world_transform,
			SH_monochrome_3120,
			SH_monochrome_local_0123);
			
		float prt_mono=		dot(SH_monochrome_local_0123, prt_c0_c3_monochrome);		
		float ravi_mono= ravi_order_2_monochromatic(normal, SH_monochrome_3120);
			
		prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
		ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
		float prt_ravi_ratio= prt_mono / ravi_mono;
		prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
		prt_ravi_diff.y= prt_mono;														// unused
		prt_ravi_diff.z= (prt_c0_c3_monochrome.x * 3.1415926535f)/0.886227f;			// specular occlusion % (ambient occlusion)
		prt_ravi_diff.w= min(dot(normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
	}	
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);

	//clip_distance = dot(position, v_clip_plane);
}
#endif	// ENTRY_POINT_static_prt_linear


#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_ambient
void static_prt_ambient_vs(
	in vertex_type vertex,
	in float prt_c0_c3 : BLENDWEIGHT1,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 prt_ravi_diff : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];
	float4 normal4 = float4(normal.xyz,1);
	default_vertex_transform_vs(vertex, position, texcoord, normal4, binormal, tangent, fragment_to_camera_world, local_to_world_transform);
	normal = normal4.xyz;

	float prt_c0= prt_c0_c3;
	{
		float ambient_occlusion= prt_c0;
		float lighting_c0= 	dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));			// ###ctchou $PERF convert to monochrome before passing in!
		float ravi_mono= (0.886227f * lighting_c0)/3.1415926535f;
		float prt_mono= ambient_occlusion * lighting_c0;
			
		prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
		ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
		float prt_ravi_ratio= prt_mono /ravi_mono;
		prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
		prt_ravi_diff.y= prt_mono;														// unused
		prt_ravi_diff.z= (ambient_occlusion * 3.1415926535f)/0.886227f;					// specular occlusion % (ambient occlusion)
		prt_ravi_diff.w= min(dot(normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
	}
		
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);

	//clip_distance = dot(position, v_clip_plane);
}
#endif	// ENTRY_POINT_static_prt_quadratic



#if ((ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_quadratic) || (ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_linear) || (ENTRY_POINT(entry_point) == ENTRY_POINT_static_prt_ambient))
#ifdef PIXEL_SHADER
accum_pixel static_prt_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in float clip_distance : SV_ClipDistance,
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 prt_ravi_diff : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)
{
	entry_point_data data;
	BUILD_ENTRY_POINT_DATA(data);
	return static_lighting_shared_ps_quadratic(
		data,
		fragment_position,
		original_texcoord,
		normal,
		binormal,
		tangent,
		fragment_to_camera_world,
		extinction,
		inscatter);
}
#endif  // PIXEL_SHADER
#endif  // quadratic / linear / ambient prt ps


PARAM_SAMPLER_2D(dynamic_light_gel_texture);

void default_dynamic_light_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	//out s_dynamic_light_clip_distance clip_distance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 fragment_position_shadow : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)				// homogenous coordinates of the fragment position in projective shadow space)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);

	texcoord= vertex.texcoord;
	normal= vertex.normal;
	tangent= vertex.tangent;
	binormal= vertex.binormal;
	// world space vector from vertex to eye/camera
	fragment_to_camera_world= Camera_Position - vertex.position;
		
	fragment_position_shadow= mul(float4(vertex.position, 1.0f), Shadow_Projection);		
	
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);		

	//clip_distance = calc_dynamic_light_clip_distance(position);
}

void dynamic_light_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	//out s_dynamic_light_clip_distance clip_distance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 fragment_position_shadow : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)		// homogenous coordinates of the fragment position in projective shadow space)
{
	default_dynamic_light_vs(
		vertex, 
		position, 
		//clip_distance,
		texcoord, 
		normal, 
		binormal, 
		tangent, 
		fragment_to_camera_world, 
		fragment_position_shadow, 
		extinction, 
		inscatter);
}

void dynamic_light_cine_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	//out s_dynamic_light_clip_distance clip_distance,
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 fragment_position_shadow : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)		// homogenous coordinates of the fragment position in projective shadow space)
{
	default_dynamic_light_vs(
		vertex, 
		position, 
		//clip_distance,
		texcoord, 
		normal, 
		binormal, 
		tangent, 
		fragment_to_camera_world, 
		fragment_position_shadow, 
		extinction, 
		inscatter);
}

#ifdef PIXEL_SHADER
accum_pixel default_dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in s_dynamic_light_clip_distance clip_distance,
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 fragment_position_shadow : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1,		// homogenous coordinates of the fragment position in projective shadow space
	bool cinematic)
{
	// get blend values
	float4 blend= sample_blend_normalized_for_lighting(texcoord);
	
	// calculate blended surface parameters
	float diffuse_coefficient;
	specular_parameters specular;
	float3 self_illum;
	blend_surface_parameters(
		texcoord,
		blend,		
		diffuse_coefficient,
		specular,
		self_illum);

	// normalize interpolated values
	normal= normalize(normal);
	binormal= normalize(binormal);
	tangent= normalize(tangent);

	// setup tangent frame
	float3x3 tangent_frame = {tangent, binormal, normal};

   	// rotate bump normal into world space

#if DX_VERSION == 11
	float3 bump_normal = normal_texture.Load(int3(fragment_position.xy, 0)).xyz * 2.0f - 1.0f;
#else
	float3 bump_normal= tex2D(normal_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy) * 2.0f - 1.0f;
#endif

	// convert view direction to tangent space
	float3 view_dir= normalize(fragment_to_camera_world);
	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	
	// calculate simple light falloff for expensive light
	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
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
	
	float4 out_color= 0.0f;	
	if (dot(light_radiance, light_radiance) > 0.0000001f)									// ###ctchou $PERF unproven 'performance' hack
	{
		float n_dot_v			= dot( bump_normal, view_dir );
		
		float3 analytic_diffuse_radiance= 0.0f;
		float3 analytic_specular_radiance= 0.0f;

		// get diffuse albedo and specular mask (specular mask _can_ be stored in the albedo alpha channel, or in a seperate texture)

		
		#if DX_VERSION == 11
			float4 diffuse_albedo = albedo_texture.Load(int3(fragment_position.xy, 0));
		#else
			float4 diffuse_albedo= tex2D(albedo_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy);
		#endif

		// calculate view reflection direction (in world space of course)
		float3 view_reflect_dir= normalize( (dot(view_dir, bump_normal) * bump_normal - view_dir) * 2 + view_dir );

		// calculate diffuse lobe
		analytic_diffuse_radiance= light_radiance * dot(fragment_to_light, bump_normal) * diffuse_albedo.rgb;
		
		#if SPECULAR_MATERIAL_COUNT > 0
			calc_phong_outgoing_light(
				bump_normal,
				view_dir,
				view_reflect_dir,
				n_dot_v,
				specular.power,
				fragment_to_light,
				light_radiance,
				analytic_specular_radiance);
		#endif
	
		// calculate shadow
		float unshadowed_percentage= 1.0f;

		float cosine= dot(normal.xyz, p_lighting_constant_1.xyz);								// p_lighting_constant_1.xyz = normalized forward direction of light (along which depth values are measured)

		float slope= sqrt(1-cosine*cosine) / cosine;										// slope == tan(theta) == sin(theta)/cos(theta) == sqrt(1-cos^2(theta))/cos(theta)
//		slope= min(slope, 4.0f) + 0.2f;														// don't let slope get too big (results in shadow errors - see master chief helmet), add a little bit of slope to account for curvature
																							// ###ctchou $REVIEW could make this (4.0) a shader parameter if you have trouble with the masterchief's helmet not shadowing properly	

//		slope= slope / dot(p_lighting_constant_1.xyz, fragment_to_light.xyz);				// adjust slope to be slope for z-depth
																		
		float half_pixel_size= p_lighting_constant_1.w * fragment_position_shadow.w;		// the texture coordinate distance from the center of a pixel to the corner of the pixel - increases linearly with increasing depth
		float depth_bias= (slope + 0.2f) * half_pixel_size;
	
		depth_bias= 0.0f;
	
		if (cinematic)
		{
			unshadowed_percentage= sample_percentage_closer_PCF_5x5_block_predicated(fragment_position_shadow, depth_bias);
		}
		else
		{
			unshadowed_percentage= sample_percentage_closer_PCF_3x3_block(fragment_position_shadow, depth_bias);
		}

		// diffuse light	
		out_color.rgb= analytic_diffuse_radiance * diffuse_coefficient;

	// specular light
	#if SPECULAR_MATERIAL_COUNT > 0
		// calculate full specular tint
	    float3 normal_tint		= lerp(specular.normal_albedo.rgb, diffuse_albedo.rgb, specular.normal_albedo.w);			// first blend in appropriate amounts of the diffuse albedo
		float fresnel_blend		= pow((1.0f - clamp(n_dot_v, 0.0f, 1.0f)), specular.fresnel_steepness);				// 
		float3 specular_tint	= lerp(normal_tint, float3(1.0f, 1.0f, 1.0f), fresnel_blend);						// then blend that to white at glancing angles
		
		out_color.rgb += diffuse_albedo.w * specular_tint * analytic_specular_radiance * specular.analytical;
	#endif
	
		out_color.rgb *= unshadowed_percentage;
	}
	
	// set color channels
	out_color.rgb= (out_color.rgb * extinction) * g_exposure.rrr;			// don't need inscatter because that has been added already in static lighting pass
	out_color.w= 1.0f;

	return convert_to_render_target(out_color, true, true
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}

accum_pixel dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in s_dynamic_light_clip_distance clip_distance,
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 fragment_position_shadow : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)		// homogenous coordinates of the fragment position in projective shadow space
{
	return default_dynamic_light_ps(
		fragment_position, 
		//clip_distance,
		texcoord, 
		normal, 
		binormal, 
		tangent, 
		fragment_to_camera_world, 
		fragment_position_shadow, 
		extinction, 
		inscatter, 
		false);
}

accum_pixel dynamic_light_cine_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	//in s_dynamic_light_clip_distance clip_distance,
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 fragment_position_shadow : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)		// homogenous coordinates of the fragment position in projective shadow space
{
	return default_dynamic_light_ps(
		fragment_position, 
		//clip_distance,
		texcoord, 
		normal, 
		binormal, 
		tangent, 
		fragment_to_camera_world, 
		fragment_position_shadow, 
		extinction, 
		inscatter, 
		true);
}

#endif //PIXEL_SHADER

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
void lightmap_debug_mode_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	//out float clip_distance : SV_ClipDistance,
	out float2 lightmap_texcoord:TEXCOORD0,
	out float3 normal:TEXCOORD1,
	out float2 texcoord:TEXCOORD2,
	out float3 tangent:TEXCOORD3,
	out float3 binormal:TEXCOORD4,
	out float3 fragment_to_camera_world:TEXCOORD5)
{

	float4 local_to_world_transform[3];
	fragment_to_camera_world= Camera_Position-vertex.position;

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	lightmap_texcoord= lightmap.texcoord;	
	normal= vertex.normal;
	texcoord= vertex.texcoord;
	tangent= vertex.tangent;
	binormal= vertex.binormal;
	
	//clip_distance = dot(position, v_clip_plane);
}

#ifdef PIXEL_SHADER

accum_pixel lightmap_debug_mode_ps(
	SCREEN_POSITION_INPUT(screen_position),
	//in float clip_distance : SV_ClipDistance,
	in float2 lightmap_texcoord:TEXCOORD0,
	in float3 normal:TEXCOORD1,
	in float2 texcoord:TEXCOORD2,
	in float3 tangent:TEXCOORD3,
	in float3 binormal:TEXCOORD4,
	in float3 fragment_to_camera_world:TEXCOORD5) : SV_Target
{   	
	float4 out_color;
	
	out_color= display_debug_modes(
		lightmap_texcoord,
		normal,
		texcoord,
		tangent,
		binormal,
		0.0f,
		0.0f,
		0.0f,
		0.0f);

	return convert_to_render_target(out_color, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
	
}

#endif //PIXEL_SHADER
