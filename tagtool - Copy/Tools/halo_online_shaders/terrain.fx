#include "global.fx"
#include "hlsl_constant_mapping.fx"

#ifdef _NEW_LIGHTMAP_
#include "terrain_new.fx"
#else


#ifndef pc
#define ALPHA_OPTIMIZATION
#endif

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#define GAMMA2 true

#define NO_ALPHA_TO_COVERAGE

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
#include "clip_plane.fx"
#include "dynamic_light_clip.fx"


#ifdef pc
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
#endif // pc


void apply_pc_albedo_modifier(
	inout float4 albedo,
	in float3 normal)
{
#ifdef pc
	albedo.rgb= lerp(albedo.rgb, debug_tint.rgb, debug_tint.a);
	
	if (p_shader_pc_albedo_lighting!=0.f)
	{
		albedo.xyz= calc_pc_albedo_lighting(albedo, normal);
	}
#endif // pc
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

PARAM(float, global_albedo_tint_;

#define ACTIVE_MATERIAL(material_type) ACTIVE_##material_type
#define ACTIVE_diffuse_only 1
#define ACTIVE_diffuse_plus_specular 1
#define ACTIVE_off 0
#define ACTIVE_MATERIAL_COUNT (ACTIVE_MATERIAL(material_0_type) + ACTIVE_MATERIAL(material_1_type) + ACTIVE_MATERIAL(material_2_type) + ACTIVE_MATERIAL(material_3_type))

#define SPECULAR_MATERIAL(material_type) SPECULAR_##material_type
#define SPECULAR_diffuse_only 0
#define SPECULAR_diffuse_plus_specular 1
#define SPECULAR_off 0
#define SPECULAR_MATERIAL_COUNT (SPECULAR_MATERIAL(material_0_type) + SPECULAR_MATERIAL(material_1_type) + SPECULAR_MATERIAL(material_2_type) + SPECULAR_MATERIAL(material_3_type))

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
PARAM(float, albedo_specular_tint_blend_m_##material_number);


DECLARE_MATERIAL(0);
DECLARE_MATERIAL(1);
DECLARE_MATERIAL(2);
DECLARE_MATERIAL(3);


float3 sample_bumpmap(in sampler bump_map, in float2 texcoord)
{
	float3 bump= sample2D(bump_map, texcoord);
   
#if (DX_VERSION == 9) && defined(pc)
   bump.xy = bump.xy * (255.0f / 127.f) - (128.0f / 127.f);   
#endif

	bump.z= min(bump.x*bump.x + bump.y*bump.y, 1.0f);
	bump.z= sqrt(1 - bump.z);
   
	return bump;
}


float4 sample_blend_normalized(float2 texcoord)
{
	float4 blend= sample2D(blend_map, transform_texcoord(texcoord, blend_map_xform));

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

/*
void calc_bumpmap(
	in float2 texcoord,
	in sampler bump_map,
	in float4 bump_map_xform,
	in sampler detail_bump,
	in float4 detail_bump_xform,
	out float3 bump)
{
	bump= sample_bumpmap(bump_map, transform_texcoord(texcoord, bump_map_xform));
#if DETAIL_BUMP_ENABLED
	float3 detail= sample_bumpmap(detail_bump, transform_texcoord(texcoord, detail_bump_xform));
	bump.xy+= detail.xy;
	bump= normalize(bump);
#endif
}
*/

void calc_bumpmap(
	in float2 texcoord,
	in sampler bump_map,
	in float4 bump_map_xform,
	in sampler detail_bump,
	in float4 detail_bump_xform,
	out float3 bump)
{
	bump= sample2D(bump_map, transform_texcoord(texcoord, bump_map_xform));
#if DETAIL_BUMP_ENABLED
	float3 detail= sample_bumpmap(detail_bump, transform_texcoord(texcoord, detail_bump_xform));
	bump += detail;
#endif
#if (DX_VERSION == 11) || (! defined(pc))
	bump.z= min(bump.x*bump.x + bump.y*bump.y, 1.0f);
	bump.z= sqrt(1 - bump.z);
#endif
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
	
/*	// calculate area specular light
	
	//first, figure out the zonal harmonics coefficients using Ravi's approximation
	float power_invert= 1.0f / specular_power;
	float p_0= 1.0f * 0.28209479f;
	float p_1= exp(-0.5f * power_invert) * 0.488603f;
	float p_2= exp(-2.0f * power_invert) * 1.09255f;

	//do constant and linear
	float3 x0;
//	x0.r= dot(-reflection_dir, sh_lighting_coefficients[1] * p_1) + sh_lighting_coefficients[0].r * p_0;
//	x0.g= dot(-reflection_dir, sh_lighting_coefficients[2] * p_1) + sh_lighting_coefficients[0].g * p_0;
//	x0.b= dot(-reflection_dir, sh_lighting_coefficients[3] * p_1) + sh_lighting_coefficients[0].b * p_0;
	x0.r= dot(-reflection_dir, sh_lighting_coefficients[1]);	// matrix multiply  :)
	x0.g= dot(-reflection_dir, sh_lighting_coefficients[2]);
	x0.b= dot(-reflection_dir, sh_lighting_coefficients[3]);
	x0= x0 * p_1 + sh_lighting_coefficients[0] * p_0;
	
	float3 quadratic_a= reflection_dir.xyz * reflection_dir.yzx;
	float3 x1;
	x1.x= dot(quadratic_a, sh_lighting_coefficients[4]);
	x1.y= dot(quadratic_a, sh_lighting_coefficients[5]);
	x1.z= dot(quadratic_a, sh_lighting_coefficients[6]);
	x1 *= p_2;
	
	float4 quadratic_b = float4(reflection_dir.xyz*reflection_dir.xyz, 1.f/3.f);
	float3 x2;
	x2.x= dot(quadratic_b, sh_lighting_coefficients[7]);
	x2.y= dot(quadratic_b, sh_lighting_coefficients[8]);
	x2.z= dot(quadratic_b, sh_lighting_coefficients[9]);
	x2 *= p_2 * 0.5f;

	area_specular_light= (x0 + (x1 - x2));
/*
	//do constant and linear
	float3 x0;
	x0.r= dot(-reflection_dir, sh_lighting_coefficients[1] * p_1) + sh_lighting_coefficients[0].r * p_0;
	x0.g= dot(-reflection_dir, sh_lighting_coefficients[2] * p_1) + sh_lighting_coefficients[0].g * p_0;
	x0.b= dot(-reflection_dir, sh_lighting_coefficients[3] * p_1) + sh_lighting_coefficients[0].b * p_0;
	
	float3 quaratic_a= reflection_dir.xyz*reflection_dir.yzx;
	float3 x1;
	x1.x= dot(quaratic_a, sh_lighting_coefficients[4]) * p_2;
	x1.y= dot(quaratic_a, sh_lighting_coefficients[5]) * p_2;
	x1.z= dot(quaratic_a, sh_lighting_coefficients[6]) * p_2;
	
	float4 quaratic_b = float4( reflection_dir.xyz*reflection_dir.xyz, 1.f/3.f );
	float3 x2;
	x2.x= dot(quaratic_b, sh_lighting_coefficients[7]) * p_2 * 0.5f;
	x2.y= dot(quaratic_b, sh_lighting_coefficients[8]) * p_2 * 0.5f;
	x2.z= dot(quaratic_b, sh_lighting_coefficients[9]) * p_2 * 0.5f;

	area_specular_light= (x0 + (x1 - x2));
*/
}

/*
void calc_phong_specular(
	in float3 normal_dir,
	in float3 view_dir,
	in float3 light_dir,
	in float3 reflection_dir,
	in float3 light_color,
	in float4 sh_lighting_coefficients[10],
	in float3 specular_tint,
	in float power,
	in float fresnel_curve_steepness,
	in float3 albedo_color,
	in float albedo_specular_tint_blend,
	in float specular_mask,
	in float specular_coefficient,
	in float analytical_specular_contribution,
	in float area_specular_contribution,
	in float environment_map_specular_contribution,
	out float3 specular_color,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only)
{

	//do fresnel
    float n_dot_v =dot( normal_dir, view_dir );
    float fresnel_blend= pow((1.0f - clamp(n_dot_v, 0.0f, 1.0f)), fresnel_curve_steepness); 
    float3 normal_tint= lerp(specular_tint, albedo_color, albedo_specular_tint_blend);
    float3 tint= lerp(normal_tint, float3(1.0f, 1.0f, 1.0f), fresnel_blend);
    
    //analyical
    float3 analytical_specular;
	float n_dot_l = dot( normal_dir, light_dir );
    float l_dot_r = max(dot(light_dir, reflection_dir), 0.0f); 
    if (n_dot_l > 0 && n_dot_v > 0 )
    {
		analytical_specular= pow(l_dot_r, power) * ((power + 1.0f) / 6.2832) * tint * light_color;
	}
	else
	{
		analytical_specular= 0.0f;
	}
	
	//area specular
	float3 area_specular= 0.0f;
	
	//first, figure out the zonal harmonics coefficients using Ravi's approximation
	float power_invert= 1.0f / power;
	float p_0= 1.0f * 0.28209479f;
	float p_1= exp(-0.5f * power_invert) * 0.488603f;
	float p_2= exp(-2.0f * power_invert) * 1.09255f;

	//do constant and linear
	float3 x0;
	x0.r= dot(-reflection_dir, sh_lighting_coefficients[1] * p_1) + sh_lighting_coefficients[0].r * p_0;
	x0.g= dot(-reflection_dir, sh_lighting_coefficients[2] * p_1) + sh_lighting_coefficients[0].g * p_0;
	x0.b= dot(-reflection_dir, sh_lighting_coefficients[3] * p_1) + sh_lighting_coefficients[0].b * p_0;
	
	float3 quaratic_a= reflection_dir.xyz*reflection_dir.yzx;
	float3 x1;
	x1.x= dot(quaratic_a, sh_lighting_coefficients[4]) * p_2;
	x1.y= dot(quaratic_a, sh_lighting_coefficients[5]) * p_2;
	x1.z= dot(quaratic_a, sh_lighting_coefficients[6]) * p_2;
	
	float4 quaratic_b = float4( reflection_dir.xyz*reflection_dir.xyz, 1.f/3.f );
	float3 x2;
	x2.x= dot(quaratic_b, sh_lighting_coefficients[7]) * p_2 * 0.5f;
	x2.y= dot(quaratic_b, sh_lighting_coefficients[8]) * p_2 * 0.5f;
	x2.z= dot(quaratic_b, sh_lighting_coefficients[9]) * p_2 * 0.5f;

	area_specular= (x0 + (x1 - x2)) * tint;
	
	//scaling and masking
	specular_color= specular_mask * specular_coefficient * (
		max(analytical_specular * analytical_specular_contribution, 0.0f) +
		max(area_specular * area_specular_contribution, 0.0f));
					
	//output for environment stuff
	envmap_area_specular_only= area_specular;
	envmap_specular_reflectance_and_roughness.xyz=	environment_map_specular_contribution * specular_mask * specular_coefficient;
	envmap_specular_reflectance_and_roughness.w= 0.0f;
}
*/
/*
#define calc_material(material_type) calc_material_##material_type

float4 calc_material_off(
	float3 bump_normal,
	float4 albedo,
	float3 view_dir,
	float4 lighting_constants[10],
	float3 light_dir,
	float3 light_intensity,
	float2 fragment_position)
{
	return 0.0f;
}
							
float4 calc_material_diffuse_only(
	float3 bump_normal,
	float4 albedo,
	float3 view_dir,
	float4 lighting_constants[10],
	float3 light_dir,
	float3 light_intensity,
	float2 fragment_position)
{
	return float4(ravi_order_3(bump_normal, lighting_constants) * albedo, 0.0f);
}

float4 calc_material_diffuse_plus_specular(
	float3 bump_normal,
	float4 albedo,
	float3 view_dir,
	float4 lighting_constants[10],
	float3 light_dir,
	float3 light_intensity,
	float2 fragment_position)
{	
	float3 specular_radiance;
	float4 envmap_specular_reflectance_and_roughness;
	float3 envmap_area_specular_only;
		
	//reflect view around normal
	float3 reflection_dir= normalize( (dot(view_dir, bump_normal) * bump_normal - view_dir) * 2 + view_dir );
		
	calc_phong_specular(
		bump_normal,
		view_dir,
		light_dir,
		reflection_dir,
		light_intensity,
		lighting_constants,
		specular_tint_m_0,
		specular_power_m_0,
		fresnel_curve_steepness_m_0,
		albedo,
		albedo_specular_tint_blend_m_0,
		albedo.w,
		specular_coefficient_m_0,
		analytical_specular_contribution_m_0,
		area_specular_contribution_m_0,
		environment_specular_contribution_m_0,
		specular_radiance,
		envmap_specular_reflectance_and_roughness,
		envmap_area_specular_only);
					
	float3 envmap_radiance= calc_environment_map_ps(
		view_dir,
		bump_normal,
		reflection_dir,
		envmap_specular_reflectance_and_roughness,
		envmap_area_specular_only);
			
	//diffuse radiance
	float3 diffuse_radiance= ravi_order_3(bump_normal, lighting_constants);
	float4 out_color;
	out_color.xyz= diffuse_radiance * diffuse_coefficient_m_0 * albedo + specular_radiance + envmap_radiance;
	out_color.w= 1.0f;
	
	return out_color;
}
*/

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
	out float3 fragment_to_camera_world)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

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
	CLIP_OUTPUT
	out float4 texcoord : TEXCOORD0,
	out float4 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	/*out float3 fragment_to_camera_world : TEXCOORD4*/)
{
	float3 fragment_to_camera_world;	//should get compiled out because its not used
	default_vertex_transform_vs(vertex, position, texcoord.xy, normal, binormal, tangent, fragment_to_camera_world);
	texcoord.zw= 1.0f;
	
	CALC_CLIP(position);
}

#define DETAIL_MULTIPLIER 4.59479f

#ifndef pc
// unfortunately this breaks the compiler ###ctchou $PERF reinstate when the compiler is fixed
#define COMPILER_IFANY /*[ifAny]*/
#else
#define COMPILER_IFANY
#endif

#define ACCUMULATE_MATERIAL_ALBEDO(material, blend_amount, albedo_accumulate, blendweight)										\
COMPILER_IFANY																													\
if (blend_amount)																												\
{																																\
	float4 base=	sample2D(base_map_m_##material,		transform_texcoord(original_texcoord, base_map_m_##material##_xform));		\
	float4 detail=	sample2D(detail_map_m_##material,	transform_texcoord(original_texcoord, detail_map_m_##material##_xform));	\
	albedo_accumulate += base * detail * blendweight;																			\
}

#define ACCUMULATE_MATERIAL_BUMP(material, blend_amount, bump)		\
{																	\
	float3 material_bump_normal;									\
	calc_bumpmap(													\
		original_texcoord,											\
		bump_map_m_##material,										\
		bump_map_m_##material##_xform,								\
		detail_bump_m_##material,									\
		detail_bump_m_##material##_xform,							\
		material_bump_normal);										\
	bump_normal += material_bump_normal * blend_amount;				\
}

albedo_pixel albedo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	CLIP_INPUT
	in float4 original_texcoord : TEXCOORD0,
	in float4 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3)
{
	
	float4 blend;
	float4 blend2;

	blend= sample_blend_normalized(original_texcoord);
	{
		float4 mult= float4(global_albedo_tint * DETAIL_MULTIPLIER, 1.0f, global_albedo_tint * DETAIL_MULTIPLIER, 1.0f);
		blend2= blend.zzww * mult;
		blend= blend.xxyy * mult;
	}
	
	float4 albedo= 0.0f;
	float3 bump_normal= 0.0f;

	#if ACTIVE_MATERIAL(material_0_type)
		ACCUMULATE_MATERIAL_ALBEDO(0, blend.x, albedo, blend.xxxy);
		ACCUMULATE_MATERIAL_BUMP(0, blend.y, bump_normal);
	#endif
	
	#if ACTIVE_MATERIAL(material_1_type)	
		ACCUMULATE_MATERIAL_ALBEDO(1, blend.z, albedo, blend.zzzw);
		ACCUMULATE_MATERIAL_BUMP(1, blend.w, bump_normal);
	#endif

	#if ACTIVE_MATERIAL(material_2_type)
		ACCUMULATE_MATERIAL_ALBEDO(2, blend2.x, albedo, blend2.xxxy);
		ACCUMULATE_MATERIAL_BUMP(2, blend2.y, bump_normal);
	#endif
	
	#if ACTIVE_MATERIAL(material_3_type)
		ACCUMULATE_MATERIAL_ALBEDO(3, blend2.z, albedo, blend2.zzzw);
		ACCUMULATE_MATERIAL_BUMP(3, blend2.w, bump_normal);
	#endif
	
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

#ifdef pc
	apply_pc_albedo_modifier(albedo, bump_normal);
#endif

	return convert_to_albedo_target(albedo, bump_normal, normal.w, tangent_frame[2]);
}



//========================================
// methods for grabbing SH coefficients
//========================================
float3 decode_bpp16_luvw(
	in float4 val0,
	in float4 val1,
	in float l_range)
{	
	float L = val0.a * val1.a * l_range;
	float3 uvw = val0.xyz + val1.xyz;
	return (uvw * 2.0f - 2.0f) * L;	
}


#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_pixel

struct entry_point_data
{
	float2 lightmap_texcoord;
};
#define BUILD_ENTRY_POINT_DATA(data)	{ data.lightmap_texcoord= lightmap_texcoord; }
void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10])
{
	float3 sh_coefficients[9];

#ifdef DEBUG_UNCOMPRESSED_LIGHTMAPS
	if ( p_lightmap_compress_constant_using_dxt )
#endif //DEBUG_UNCOMPRESSED_LIGHTMAPS
	{	
#ifndef pc
		float4 sh_dxt_vector_0;
		float4 sh_dxt_vector_1;
		float4 sh_dxt_vector_2;
		float4 sh_dxt_vector_3;
		float4 sh_dxt_vector_4;
		float4 sh_dxt_vector_5;
		float4 sh_dxt_vector_6;
		float4 sh_dxt_vector_7;
		float4 sh_dxt_vector_8;
		float4 sh_dxt_vector_9;
		float4 sh_dxt_vector_10;
		float4 sh_dxt_vector_11;
		float4 sh_dxt_vector_12;
		float4 sh_dxt_vector_13;
		float4 sh_dxt_vector_14;
		float4 sh_dxt_vector_15;
		float4 sh_dxt_vector_16;
		float4 sh_dxt_vector_17;

		/*
		sh_dxt_vector_0 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.5f/18));	
		sh_dxt_vector_1 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 1.5f/18));	

		sh_dxt_vector_2 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 2.5f/18));	
		sh_dxt_vector_3 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 3.5f/18));	

		sh_dxt_vector_4 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 4.5f/18));	
		sh_dxt_vector_5 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 5.5f/18));	

		sh_dxt_vector_6 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 6.5f/18));	
		sh_dxt_vector_7 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 7.5f/18));	

		sh_dxt_vector_8 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 8.5f/18));	
		sh_dxt_vector_9 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 9.5f/18));	

		sh_dxt_vector_10 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 10.5f/18));	
		sh_dxt_vector_11 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 11.5f/18));	

		sh_dxt_vector_12 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 12.5f/18));	
		sh_dxt_vector_13 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 13.5f/18));	

		sh_dxt_vector_14 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 14.5f/18));	
		sh_dxt_vector_15 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 15.5f/18));	

		sh_dxt_vector_16 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 16.5f/18));	
		sh_dxt_vector_17 = tex3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 17.5f/18));	
		*/
		
		float3 lightmap_texcoord_bottom= float3(data.lightmap_texcoord, 0.0f);
		float3 lightmap_texcoord_up= float3(data.lightmap_texcoord, 11.5f / 18.0f);

		asm{ tfetch3D sh_dxt_vector_0, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 0.5 };
		asm{ tfetch3D sh_dxt_vector_1, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 1.5 };

		asm{ tfetch3D sh_dxt_vector_2, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 2.5 };
		asm{ tfetch3D sh_dxt_vector_3, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 3.5 };

		asm{ tfetch3D sh_dxt_vector_4, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 4.5 };
		asm{ tfetch3D sh_dxt_vector_5, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 5.5 };

		asm{ tfetch3D sh_dxt_vector_6, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 6.5 };
		asm{ tfetch3D sh_dxt_vector_7, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 7.5 };

		asm{ tfetch3D sh_dxt_vector_8, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ=-3.0 };
		asm{ tfetch3D sh_dxt_vector_9, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ=-2.0 };

		asm{ tfetch3D sh_dxt_vector_10, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ=-1.0 };
		asm{ tfetch3D sh_dxt_vector_11, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 0.0 };

		asm{ tfetch3D sh_dxt_vector_12, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 1.0 };
		asm{ tfetch3D sh_dxt_vector_13, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 2.0 };

		asm{ tfetch3D sh_dxt_vector_14, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 3.0 };
		asm{ tfetch3D sh_dxt_vector_15, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 4.0 };

		asm{ tfetch3D sh_dxt_vector_16, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 5.0 };
		asm{ tfetch3D sh_dxt_vector_17, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 6.0 };		

		sh_coefficients[0] = decode_bpp16_luvw(sh_dxt_vector_0, sh_dxt_vector_1, p_lightmap_compress_constant_0.x);	
		sh_coefficients[1] = decode_bpp16_luvw(sh_dxt_vector_2, sh_dxt_vector_3, p_lightmap_compress_constant_0.y);	
		sh_coefficients[2] = decode_bpp16_luvw(sh_dxt_vector_4, sh_dxt_vector_5, p_lightmap_compress_constant_0.z);	
		sh_coefficients[3] = decode_bpp16_luvw(sh_dxt_vector_6, sh_dxt_vector_7, p_lightmap_compress_constant_1.x);	
		sh_coefficients[4] = decode_bpp16_luvw(sh_dxt_vector_8, sh_dxt_vector_9, p_lightmap_compress_constant_1.y);	
		sh_coefficients[5] = decode_bpp16_luvw(sh_dxt_vector_10, sh_dxt_vector_11, p_lightmap_compress_constant_1.z);	
		sh_coefficients[6] = decode_bpp16_luvw(sh_dxt_vector_12, sh_dxt_vector_13, p_lightmap_compress_constant_2.x);	
		sh_coefficients[7] = decode_bpp16_luvw(sh_dxt_vector_14, sh_dxt_vector_15, p_lightmap_compress_constant_2.y);	
		sh_coefficients[8] = decode_bpp16_luvw(sh_dxt_vector_16, sh_dxt_vector_17, p_lightmap_compress_constant_2.z);	
#else
		sh_coefficients[0]= float4(1.0f, 1.0f, 1.0f, 0.0f);
		sh_coefficients[1]= 0.0f;
		sh_coefficients[2]= 0.0f;
		sh_coefficients[3]= 0.0f;
		sh_coefficients[4]= 0.0f;
		sh_coefficients[5]= 0.0f;
		sh_coefficients[6]= 0.0f;
		sh_coefficients[7]= 0.0f;
		sh_coefficients[8]= 0.0f;
#endif

	}
#ifdef DEBUG_UNCOMPRESSED_LIGHTMAPS
	else
	{
#if defined(ALPHA_OPTIMIZATION)
		float4 sh_coefficients0;
		float4 sh_coefficients1;
		float4 sh_coefficients2;
		float4 sh_coefficients3;
		float4 sh_coefficients4;
		float4 sh_coefficients5;
		float4 sh_coefficients6;
		float4 sh_coefficients7;
		float4 sh_coefficients8;
		float3 lightmap_texcoord_hack= float3(data.lightmap_texcoord, 0.0f);
		asm{ tfetch3D sh_coefficients0, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 0.5 }; sh_coefficients[0] = sh_coefficients0.xyz;
		asm{ tfetch3D sh_coefficients1, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 1.5 }; sh_coefficients[1] = sh_coefficients1.xyz;
		asm{ tfetch3D sh_coefficients2, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 2.5 }; sh_coefficients[2] = sh_coefficients2.xyz;
		asm{ tfetch3D sh_coefficients3, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 3.5 }; sh_coefficients[3] = sh_coefficients3.xyz;
		asm{ tfetch3D sh_coefficients4, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 4.5 }; sh_coefficients[4] = sh_coefficients4.xyz;
		asm{ tfetch3D sh_coefficients5, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 5.5 }; sh_coefficients[5] = sh_coefficients5.xyz;
		asm{ tfetch3D sh_coefficients6, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 6.5 }; sh_coefficients[6] = sh_coefficients6.xyz;
		asm{ tfetch3D sh_coefficients7, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 7.5 }; sh_coefficients[7] = sh_coefficients7.xyz;
		asm{ tfetch3D sh_coefficients8, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ=-0.5 }; sh_coefficients[8] = sh_coefficients8.xyz;

#else 
		sh_coefficients[0]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.05555f));	//0.5/9
		sh_coefficients[1]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.16666f));	//1.5/9
		sh_coefficients[2]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.27777f));	//2.5/9
		sh_coefficients[3]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.38888f));	//3.5/9
		sh_coefficients[4]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.50000f));	//4.5/9
		sh_coefficients[5]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.61111f));	//5.5/9
		sh_coefficients[6]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.72222f));	//6.5/9
		sh_coefficients[7]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.83333f));	//7.5/9	
		sh_coefficients[8]= sample3D(lightprobe_texture_array, float3(data.lightmap_texcoord, 0.94444f));	//8.5/9
#endif
	}
#endif //DEBUG_UNCOMPRESSED_LIGHTMAPS

	// pack the lightmap data
	pack_constants_texture_array(sh_coefficients, sh_lighting_coefficients);
}

#elif ENTRY_POINT(entry_point) == ENTRY_POINT_static_sh

struct entry_point_data
{
	float4 unused;
};
#define BUILD_ENTRY_POINT_DATA(data)	{ data.unused= 0.0f; }
void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10])
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
}

#elif ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_vertex

struct entry_point_data
{
	float4	p0_3_r;
	float4	p0_3_g;
	float4	p0_3_b;
};
#define BUILD_ENTRY_POINT_DATA(data)	{ data.p0_3_r= p0_3_r;	data.p0_3_g= p0_3_g;	data.p0_3_b= p0_3_b;	}
void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10])
{
	// sample the light probe texture and build sh_lighting_coefficients
	float4 L0_3[3]= {data.p0_3_r, data.p0_3_g, data.p0_3_b};
	float4 L4_7[3]= {float4(0.0f, 0.0f, 0.0f, 0.0f), float4(0.0f, 0.0f, 0.0f, 0.0f), float4(0.0f, 0.0f, 0.0f, 0.0f)};
	pack_constants(L0_3, L4_7, sh_lighting_coefficients);
}

#else

struct entry_point_data
{
};
#define BUILD_ENTRY_POINT_DATA(data)	ERROR_you_must_define_entry_point
void get_sh_coefficients(
	inout entry_point_data data,
	out float4 sh_lighting_coefficients[10])
{
	sh_lighting_coefficients[0]= float4(1.0f, 0.0f, 1.0f, 0.0f);
	sh_lighting_coefficients[1]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[2]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[3]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[4]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[5]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[6]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[7]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[8]= float4(0.0f, 0.0f, 0.0f, 0.0f);
	sh_lighting_coefficients[9]= float4(0.0f, 0.0f, 0.0f, 0.0f);
}

#endif



//===================
// static_per_pixel
//===================

void static_per_pixel_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float4 lightmap_texcoord : TEXCOORD4,
	out float3 fragment_to_camera_world : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	default_vertex_transform_vs(vertex, position, texcoord, normal, binormal, tangent, fragment_to_camera_world);
	
	lightmap_texcoord= float4(lightmap.texcoord, 0, 0);

	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	CALC_CLIP(position);
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


void blend_surface_parameters(
	in float2 texcoord,
	in float4 blend,
	out float diffuse_coefficient,
	out specular_parameters specular)
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
}


accum_pixel static_lighting_shared_ps(
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
	get_sh_coefficients(data, sh_lighting_coefficients);

	// get blend values
	float4 blend= sample_blend_normalized(original_texcoord);
	
	// calculate blended surface parameters
	float diffuse_coefficient;
	specular_parameters specular;
	blend_surface_parameters(
		original_texcoord,
		blend,		
		diffuse_coefficient,
		specular);

	// normalize interpolated values

#ifndef ALPHA_OPTIMIZATION
	normal= normalize(normal);
	binormal= normalize(binormal);
	tangent= normalize(tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = {tangent, binormal, normal};

#ifndef pc
	fragment_position.xy+= p_tiling_vpos_offset.xy;
#endif
	// rotate bump normal into world space
#if DX_VERSION == 11
	float3 bump_normal = normal_texture.Load(int3(fragment_position.xy, 0)).xyz * 2.0f - 1.0f;
#else
	float3 bump_normal= tex2D(normal_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy) * 2.0f - 1.0f;
#endif

	float3 simple_light_diffuse_light;//= 0.0f;
	float3 simple_light_specular_light;//= 0.0f;
//	#if SPECULAR_MATERIAL_COUNT > 0
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
//	#else
		// ###ctchou $PERF can make diffuse-only simple light calculation - saves dynamic light specular calculation for diffuse-only terrains
//	#endif

#if DX_VERSION == 11
	float4 albedo = albedo_texture.Load(int3(fragment_position.xy, 0));
#else
	float4 albedo= sample2D(albedo_texture, (fragment_position.xy + float2(0.5f, 0.5f))/texture_size.xy);
#endif

	// if any material is active, evaluate the diffuse lobe
	
	float3 diffuse_light= 0.0f;
	diffuse_light= ravi_order_3(bump_normal, sh_lighting_coefficients);

	// if any material is specular, evaluate the combined specular lobe
	float3 analytical_specular_light= 0.0f;
	float3 area_specular_light= 0.0f;
	float3 specular_tint= 0.0f;
	float3 envmap_light= 0.0f;
	#if SPECULAR_MATERIAL_COUNT > 0
	
		//pull out the dominant directional light
		float3 analytical_light_dir= -normalize(sh_lighting_coefficients[1].xyz + sh_lighting_coefficients[2].xyz + sh_lighting_coefficients[3].xyz);

		//use a truncated version of Peter PIke Sloan's idea of pulling out dominant light, only constant and linear coefficients.
		float3 analytical_light_intensity;
		analytical_light_intensity.r= dot(-analytical_light_dir, sh_lighting_coefficients[1] * (0.488603f)) + sh_lighting_coefficients[0].r * 0.28209479f;
		analytical_light_intensity.g= dot(-analytical_light_dir, sh_lighting_coefficients[2] * (0.488603f)) + sh_lighting_coefficients[0].g * 0.28209479f;
		analytical_light_intensity.b= dot(-analytical_light_dir, sh_lighting_coefficients[3] * (0.488603f)) + sh_lighting_coefficients[0].b * 0.28209479f;
		analytical_light_intensity*= 3.1415926535f;

		float n_dot_v			= dot( bump_normal, view_dir );

		calc_phong_outgoing_light(
			bump_normal,
			view_dir,
			view_reflect_dir,
			n_dot_v,
			specular.power,
			analytical_light_dir,
			analytical_light_intensity,
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
			area_specular_light);
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

	out_color.rgb= (out_color.rgb * extinction + inscatter) * g_exposure.rrr;
	return convert_to_render_target(out_color, true, false);
}


#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_pixel
accum_pixel static_per_pixel_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
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
	return static_lighting_shared_ps(
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

//===================
// static_per_vertex
//===================

#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_per_vertex
void static_per_vertex_vs(
	in vertex_type vertex,
	in float4 c0_3_r : TEXCOORD3,
	in float4 c0_3_g : TEXCOORD4,
	in float4 c0_3_b : TEXCOORD5,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 probe0_3_r : TEXCOORD5,
	out float4 probe0_3_g : TEXCOORD6,
	out float4 probe0_3_b : TEXCOORD7,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	default_vertex_transform_vs(vertex, position, texcoord, normal, binormal, tangent, fragment_to_camera_world);	
	
	probe0_3_r= c0_3_r;
	probe0_3_g= c0_3_g;
	probe0_3_b= c0_3_b;
	
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);	
	
	CALC_CLIP(position);
}

accum_pixel static_per_vertex_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 p0_3_r : TEXCOORD5,
	in float4 p0_3_g : TEXCOORD6,
	in float4 p0_3_b : TEXCOORD7,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)
{
	entry_point_data data;
	BUILD_ENTRY_POINT_DATA(data);
	return static_lighting_shared_ps(
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
#endif // ENTRY_POINT_static_per_vertex

//================
// static_sh
//================

#if ENTRY_POINT(entry_point) == ENTRY_POINT_static_sh
void static_sh_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	default_vertex_transform_vs(vertex, position, texcoord, normal, binormal, tangent, fragment_to_camera_world);
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	CALC_CLIP(position);
}

accum_pixel static_sh_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
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
	return static_lighting_shared_ps(
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
#endif	// ENTRY_POINT_static_sh

PARAM_SAMPLER_2D(dynamic_light_gel_texture);

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
	out float3 fragment_to_camera_world : TEXCOORD4,
	out float4 fragment_position_shadow : TEXCOORD5,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)		// homogenous coordinates of the fragment position in projective shadow space)
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
	
#if DX_VERSION == 11	
	clip_distance = calc_dynamic_light_clip_distance(position);
#endif
}

accum_pixel dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
#if DX_VERSION == 11	
	in s_dynamic_light_clip_distance clip_distance,
#endif	
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4,
	in float4 fragment_position_shadow : TEXCOORD5,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)		// homogenous coordinates of the fragment position in projective shadow space
{
	// get blend values
	float4 blend= sample_blend_normalized(texcoord);
	
	// calculate blended surface parameters
	float diffuse_coefficient;
	specular_parameters specular;
	blend_surface_parameters(
		texcoord,
		blend,		
		diffuse_coefficient,
		specular);

	// normalize interpolated values
	normal= normalize(normal);
	binormal= normalize(binormal);
	tangent= normalize(tangent);

	// setup tangent frame
	float3x3 tangent_frame = {tangent, binormal, normal};

#ifndef pc
	fragment_position.xy+= p_tiling_vpos_offset.xy;
#endif
   	// rotate bump normal into world space
#if DX_VERSION == 11
	float3 bump_normal = normal_texture.Load(int3(fragment_position.xy, 0)).xyz * 2.0f - 1.0f;
#else
	float3 bump_normal= sample2D(normal_texture, (fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy) * 2.0f - 1.0f;
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
		float4 diffuse_albedo= sample2D(albedo_texture, (fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy);
#endif

		// calculate view reflection direction (in world space of course)
		///  DESC: 18 7 2007   13:49 BUNGIE\yaohhu :
		///    do not need normlize, but bump_normal is not normalized. It is possible incorrect before/after optimization.
		///float3 view_reflect_dir	= normalize( (dot(view_dir, bump_normal) * bump_normal - view_dir) * 2 + view_dir );
		float3 view_reflect_dir	= -normalize(reflect(view_dir, bump_normal));

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
	
		unshadowed_percentage= sample_percentage_closer_PCF_3x3_block(fragment_position_shadow, depth_bias);		// depth_bias

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
	}
	
	// set color channels
	out_color.rgb= (out_color.rgb * extinction) * g_exposure.rrr;			// don't need inscatter because that has been added already in static lighting pass
	out_color.w= 1.0f;

	return convert_to_render_target(out_color, true, true);
}

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
void lightmap_debug_mode_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	CLIP_OUTPUT
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
	
	CALC_CLIP(position);
}

accum_pixel lightmap_debug_mode_ps(
	SCREEN_POSITION_INPUT(screen_position),
	CLIP_INPUT
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

	return convert_to_render_target(out_color, true, false);
	
}

#endif