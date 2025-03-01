#ifndef _COOK_TORRANCE_FX_
#define _COOK_TORRANCE_FX_

/*
cook_torrance.fx
Mon, Jul 25, 2005 5:01pm (haochen)
*/

//****************************************************************************
// Cook Torrance Material Model parameters
//****************************************************************************

// these should be global
float material_texture_black_roughness;
float material_texture_black_specular_multiplier;

PARAM_SAMPLER_2D(g_sampler_cc0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_dd0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_c78d78);					//pre-integrated texture

#define A0_88			0.886226925f
#define A2_10			1.023326708f
#define A6_49			0.495415912f

/* -------------- parameter list --------------------------
all dedicated external parameters for cook-torrance
the organism materials has a super-set of parameter list
of cook-torrance.
---------------------------------------------------------- */

float	roughness;					//roughness
float	albedo_blend;				//how much to blend in the albedo color to fresnel f0
float	analytical_roughness;		//point light roughness

#if ALBEDO_TYPE(calc_albedo_ps) != ALBEDO_TYPE_calc_albedo_four_change_color_applying_to_specular_ps

float3	fresnel_color;				//reflectance at normal incidence
float3	specular_tint;

#else

#define fresnel_color tertiary_change_color
#define specular_tint quaternary_change_color

#endif


float fresnel_curve_steepness;

// alias
#define normal_specular		specular_tint
#define glancing_specular	fresnel_color

// marco
#define SQR(x) ((x)*(x))

#include "vmf_util.fx"


float get_material_cook_torrance_reach_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
        return 0.27291 * pow(roughness, -1.3973f); 
    }
}

float get_material_cook_torrance_reach_specular_power_scale(float power_or_roughness)
{
}

float3 get_analytical_specular_multiplier_cook_torrance_reach_ps(float3 specular_mask)
{
    return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_diffuse_multiplier_cook_torrance_reach_ps()
{
    return diffuse_coefficient;
}

static void calculate_fresnel(
	in float3 view_dir,				
	in float3 normal_dir,
	in float3 albedo_color,
	out float power,
	out float3 normal_specular_blend_albedo_color,
	out float3 final_specular_color)
{
    float n_dot_v = saturate(dot( normal_dir, view_dir ));
    float fresnel_blend= pow(1.0f - n_dot_v, fresnel_curve_steepness);
    power= analytical_roughness;

    normal_specular_blend_albedo_color= lerp(normal_specular, albedo_color, albedo_blend);
    final_specular_color= lerp(normal_specular_blend_albedo_color, glancing_specular, fresnel_blend);   
}

//*****************************************************************************
// Analytical Cook-Torrance for point light source only
//*****************************************************************************

void calc_material_analytic_specular_cook_torrance_reach_ps(
	in float3 view_dir, // fragment to camera, in world space
	in float3 normal_dir, // bumped fragment surface normal, in world space
	in float3 view_reflect_dir, // view_dir reflected about surface normal, in world space
	in float3 L, // fragment to light, in world space
	in float3 light_irradiance, // light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color, // diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l, // original normal dot lighting direction (used for specular masking on far side of object)
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color, // fresnel(specular_albedo_color)
	out float3 normal_specular_blend_albedo_color, // specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{	
    float3 final_specular_color;
	float specular_power;
	calculate_fresnel(
	    view_dir, 
	    normal_dir, 
	    diffuse_albedo_color, 
	    specular_power, 
	    normal_specular_blend_albedo_color,
	    final_specular_color);

    // the following parameters can be supplied in the material texture
    // r: specular coefficient
    // g: albedo blend
    // b: environment contribution
    // a: roughless
    spatially_varying_material_parameters = float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, specular_power);
    if (use_material_texture)
    {	
	    //over ride shader supplied values with what's from the texture
	    float	power_modifier=	tex2D(material_texture, transform_texcoord(texcoord, material_texture_xform)).a;
	    spatially_varying_material_parameters.w=	lerp(material_texture_black_roughness, spatially_varying_material_parameters.w, power_modifier);
		spatially_varying_material_parameters.r	*=	lerp(material_texture_black_specular_multiplier, 1.0f, power_modifier);
    }
    
    float3 f0=normal_specular_blend_albedo_color;
    float3 f1=glancing_specular;

    float fVDotN=(dot(view_dir,normal_dir));
    float fLDotN=(dot(L,normal_dir));

    float3 H=normalize(L+view_dir);
    float fNDotH=(dot(H,normal_dir));
    float fHDotV=(dot(view_dir,H));
    
	float D= 0;
    float G;
    float D_area;
    float3 F;    
	
	//Beckmann distribution
    {	    
	    float m;//Root mean square slope of microfacets 
	    float sqr_tan_alpha= (1 - fNDotH * fNDotH) / (fNDotH * fNDotH);
	    m=saturate(spatially_varying_material_parameters.a);
	    D= exp( -sqr_tan_alpha / SQR(m) )/( SQR(m) * SQR( SQR(fNDotH)) + 0.00001f);
    }

	// fresnel
	{
	#if 0
		float blend_weight= pow((1-fHDotV),fresnel_curve_steepness);
		F=f0+(f1-f0)*blend_weight;
	#else
		F= final_specular_color;
	#endif
	}

	// calc G
	{
		float G1=2*fNDotH*fVDotN/fHDotV;
		float G2=2*fNDotH*fLDotN/fHDotV;
		G=saturate(min(G1,G2));
	}

	analytic_specular_radiance= D * G * F /(fVDotN)/3.141592658*light_irradiance;	
    specular_fresnel_color= final_specular_color;
}

//*****************************************************************************
// cook-torrance for area light source in SH space
//*****************************************************************************

float3 sh_rotate_023(
	int irgb,
	float3 rotate_x,
	float3 rotate_z,
	float4 sh_0,
	float4 sh_312[3])
{
    float3 result = float3(
			sh_0[irgb],
			-dot(rotate_z.xyz, sh_312[irgb].xyz),
			dot(rotate_x.xyz, sh_312[irgb].xyz));
			
    return result;
	
}
	
#define c_view_z_shift 0.5f/32.0f
#define	c_roughness_shift 0.0f

#define SWIZZLE xyzw

//linear
void sh_glossy_ct_2(
	in float3 view_dir,
	in float3 rotate_z,
	in float4 sh_0,
	in float4 sh_312[3],
	in float roughness,
	in float r_dot_l,
	in float power,
	out float3 specular_part,
	out float3 schlick_part)
{
	//build the local frame
    float3 rotate_x = normalize(view_dir - dot(view_dir, rotate_z) * rotate_z); // view vector projected onto tangent plane
    float3 rotate_y = cross(rotate_z, rotate_x); // third one, 90 degrees  :)
	
	//local view
    float t_roughness = max(roughness, 0.05f);
    float2 view_lookup = float2(pow(dot(view_dir, rotate_x), power) + c_view_z_shift, t_roughness + c_roughness_shift);
	
	// bases: 0,2,3,6
    float4 c_value = sample2D(g_sampler_cc0236, view_lookup).SWIZZLE;
    float4 d_value = sample2D(g_sampler_dd0236, view_lookup).SWIZZLE;
	
    float4 quadratic_a, quadratic_b, sh_local;
				
    quadratic_a.xyz = rotate_z.yzx * rotate_z.xyz * (-SQRT3);
    quadratic_b = float4(rotate_z.xyz * rotate_z.xyz, 1.0f / 3.0f) * 0.5f * (-SQRT3);
	
    sh_local.xyz = sh_rotate_023(
		0,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
    sh_local.w = 0.0f;

	//c0236 dot L0236
    sh_local *= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.r = dot(c_value, sh_local);
    schlick_part.r = dot(d_value, sh_local);

    sh_local.xyz = sh_rotate_023(
		1,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
    sh_local.w = 0.0f;
	
    sh_local *= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.g = dot(c_value, sh_local);
    schlick_part.g = dot(d_value, sh_local);

    sh_local.xyz = sh_rotate_023(
		2,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
    sh_local.w = 0.0f;

    sh_local *= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.b = dot(c_value, sh_local);
    schlick_part.b = dot(d_value, sh_local);
    schlick_part = schlick_part * 0.01f;
}

//quadratic area specularity
void sh_glossy_ct_3(
	in float3 view_dir,
	in float3 rotate_z,
	in float4 sh_0,
	in float4 sh_312[3],
	in float4 sh_457[3],
	in float4 sh_8866[3],
	in float roughness,
	in float r_dot_l,
	in float power,
	out float3 specular_part,
	out float3 schlick_part)
{
	//build the local frame
    float3 rotate_x = normalize(view_dir - dot(view_dir, rotate_z) * rotate_z); // view vector projected onto tangent plane
    float3 rotate_y = cross(rotate_z, rotate_x); // third one, 90 degrees  :)
	
	//local view
    float t_roughness = max(roughness, 0.05f);
    float2 view_lookup = float2(pow(dot(view_dir, rotate_x), power) + c_view_z_shift, t_roughness + c_roughness_shift);
	
	// bases: 0,2,3,6
    float4 c_value = sample2D(g_sampler_cc0236, view_lookup).SWIZZLE;
    float4 d_value = sample2D(g_sampler_dd0236, view_lookup).SWIZZLE;
	
    float4 quadratic_a, quadratic_b, sh_local;
				
    quadratic_a.xyz = rotate_z.yzx * rotate_z.xyz * (-SQRT3);
    quadratic_b = float4(rotate_z.xyz * rotate_z.xyz, 1.0f / 3.0f) * 0.5f * (-SQRT3);
	
    sh_local.xyz = sh_rotate_023(
		0,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
    sh_local.w = dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyzw, sh_8866[0].xyzw);

	//c0236 dot L0236
    sh_local *= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.r = dot(c_value, sh_local);
    schlick_part.r = dot(d_value, sh_local);

    sh_local.xyz = sh_rotate_023(
		1,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
    sh_local.w = dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyzw, sh_8866[1].xyzw);
				
    sh_local *= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.g = dot(c_value, sh_local);
    schlick_part.g = dot(d_value, sh_local);

    sh_local.xyz = sh_rotate_023(
		2,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
		
    sh_local.w = dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyzw, sh_8866[2].xyzw);
		
    sh_local *= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.b = dot(c_value, sh_local);
    schlick_part.b = dot(d_value, sh_local);

	// basis - 7
    c_value = sample2D(g_sampler_c78d78, view_lookup).SWIZZLE;
    quadratic_a.xyz = rotate_x.xyz * rotate_z.yzx + rotate_x.yzx * rotate_z.xyz;
    quadratic_b.xyz = rotate_x.xyz * rotate_z.xyz;
    sh_local.rgb = float3(dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyz, sh_8866[0].xyz),
						 dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyz, sh_8866[1].xyz),
						 dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyz, sh_8866[2].xyz));
	
  
    sh_local *= r_dot_l;
	//c7 * L7
    specular_part.rgb += c_value.x * sh_local.rgb;
	//d7 * L7
    schlick_part.rgb += c_value.z * sh_local.rgb;
	
		//basis - 8
    quadratic_a.xyz = rotate_x.xyz * rotate_x.yzx - rotate_y.yzx * rotate_y.xyz;
    quadratic_b.xyz = 0.5f * (rotate_x.xyz * rotate_x.xyz - rotate_y.xyz * rotate_y.xyz);
    sh_local.rgb = float3(-dot(quadratic_a.xyz, sh_457[0].xyz) - dot(quadratic_b.xyz, sh_8866[0].xyz),
		-dot(quadratic_a.xyz, sh_457[1].xyz) - dot(quadratic_b.xyz, sh_8866[1].xyz),
		-dot(quadratic_a.xyz, sh_457[2].xyz) - dot(quadratic_b.xyz, sh_8866[2].xyz));
    sh_local *= r_dot_l;
	
	//c8 * L8
    specular_part.rgb += c_value.y * sh_local.rgb;
	//d8 * L8
    schlick_part.rgb += c_value.w * sh_local.rgb;
	
    schlick_part = schlick_part * 0.01f;
}

#ifdef SHADER_30

void calc_material_cook_torrance_base(
	in float3 view_dir,						// normalized
	in float3 fragment_to_camera_world,
	in float3 view_normal,					// normalized
	in float3 view_reflect_dir_world,		// normalized
	in float4 sh_lighting_coefficients[10],	//NEW LIGHTMAP: changing to linear
	in float3 view_light_dir,				// normalized
	in float3 light_color,
	in float3 albedo_color,
	in float3 specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	in float3x3 tangent_frame,				// = {tangent, binormal, normal};
	in float4 misc,
	in float3 spec_tint,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	inout float3 diffuse_radiance)
{  

#ifdef pc
	if (p_shader_pc_specular_enabled!=0.f)
#endif // pc
	{
	
	
		float3 final_specular_tint_color;			// fresnel_specular_albedo
		float3 normal_specular_blend_albedo_color;		// specular_albedo (no fresnel)
		float4 per_pixel_parameters;
		float3 specular_analytical;			// specular radiance
		float4 spatially_varying_material_parameters;
		
		calc_material_analytic_specular_cook_torrance_reach_ps(
			view_dir,
			view_normal,
			view_reflect_dir_world,
			view_light_dir,
			light_color,
			albedo_color,
			texcoord,
			prt_ravi_diff.w,
			tangent_frame,
			misc,
			spatially_varying_material_parameters,
			final_specular_tint_color,
			normal_specular_blend_albedo_color,
			specular_analytical);
		
		float3 simple_light_diffuse_light; //= 0.0f;
		float3 simple_light_specular_light; //= 0.0f;
		
		if (!no_dynamic_lights)
		{
			float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
			calc_simple_lights_analytical_reach(
				fragment_position_world,
				view_normal,
				view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
				GET_MATERIAL_SPECULAR_POWER(material_type)(spatially_varying_material_parameters.a), // todo: power?
				simple_light_diffuse_light,
				simple_light_specular_light);
			simple_light_specular_light*= final_specular_tint_color;
		}
		else
		{
			simple_light_diffuse_light= 0.0f;
			simple_light_specular_light= 0.0f;
		}

		float3 sh_glossy= 0.0f;
		// calculate area specular
		//float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;
		float r_dot_l= saturate(dot(view_light_dir, view_reflect_dir_world));

		//calculate the area sh
		float3 specular_part=0.0f;
		float3 schlick_part=0.0f;
		
// here is where vmf would come into play.
// we are using order2 as per macro in reach.
// UPDATE: using order3 for more accurate lighting
		//if (order3_area_specular)
		{
			float4 sh_0= sh_lighting_coefficients[0];
			float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			float4 sh_457[3]= {sh_lighting_coefficients[4], sh_lighting_coefficients[5], sh_lighting_coefficients[6]};
			float4 sh_8866[3]= {sh_lighting_coefficients[7], sh_lighting_coefficients[8], sh_lighting_coefficients[9]};
			sh_glossy_ct_3(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				sh_457,
				sh_8866,	//NEW_LIGHTMAP: changing to linear
				roughness,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
		//else
		//{
		//
		//	float4 sh_0= sh_lighting_coefficients[0];
		//	float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		//	
		//	sh_glossy_ct_2(
		//		view_dir,
		//		view_normal,
		//		sh_0,
		//		sh_312,
		//		roughness,
		//		r_dot_l,
		//		1,
		//		specular_part,
		//		schlick_part);	
		//}
						
		sh_glossy= specular_part * normal_specular_blend_albedo_color + (1 - normal_specular_blend_albedo_color) * schlick_part;

		//dual_vmf_diffuse_specular_with_fresnel_emulated(
		//	view_dir,
		//	view_normal,
		//	view_light_dir,
		//	light_color,
		//	final_specular_tint_color.rgb,
		//	roughness,
		//	sh_glossy
		//);
		
		//float3 fake_prebaked_analytical_light = spec_tint; // (input)envmap_area_specular_only * final_specular_tint_color.rgb

		float raised_analytical_dot_product= saturate(dot(view_light_dir, view_normal)*0.45f+0.55f);
		
		float fake_analytical_mask = 1.0f;
		float fake_cloud_mask = 1.0f;
		float3 fake_prebaked_analytical_light = raised_analytical_dot_product * light_color/* * fake_analytical_mask * fake_cloud_mask*/ * 0.25f * prt_ravi_diff.z;
		envmap_specular_reflectance_and_roughness.w= spatially_varying_material_parameters.a;
		envmap_area_specular_only= fake_prebaked_analytical_light * final_specular_tint_color.rgb + final_specular_tint_color.rgb * sh_glossy * prt_ravi_diff.z; // todo
				
		//scaling and masking
		
		specular_color.xyz= specular_mask * spatially_varying_material_parameters.r * 
			(
			(simple_light_specular_light + specular_analytical) * 
			analytical_specular_contribution +
			max(sh_glossy, 0.0f) * area_specular_contribution);
			
		specular_color.w= 0.0f;
		
		envmap_specular_reflectance_and_roughness.xyz=	spatially_varying_material_parameters.b * 
			specular_mask * 
			spatially_varying_material_parameters.r;		// ###ctchou $TODO this ain't right
		
		// from entry point
		float analytical_light_dot_product_result=saturate(dot(view_light_dir,view_normal));
		diffuse_radiance += fake_analytical_mask * analytical_light_dot_product_result *
			light_color / 3.14159265358979323846 * fake_analytical_mask;

		diffuse_radiance= diffuse_radiance * prt_ravi_diff.x;
		diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_coefficient;
		specular_color*= prt_ravi_diff.z;		
		
		//diffuse_color= 0.0f;
		//specular_color= spatially_varying_material_parameters.r;
	}
#ifdef pc
	else
	{
		envmap_specular_reflectance_and_roughness= float4(0.f, 0.f, 0.f, 0.f);
		envmap_area_specular_only= float3(0.f, 0.f, 0.f);
		specular_color= 0.0f;
		diffuse_radiance= ravi_order_3(view_normal, sh_lighting_coefficients) * prt_ravi_diff.x;
	}
#endif // pc
}

void calc_material_cook_torrance_reach_ps(
	in float3 view_dir,						// normalized
	in float3 fragment_to_camera_world,
	in float3 view_normal,					// normalized
	in float3 view_reflect_dir_world,		// normalized
	in float4 sh_lighting_coefficients[10],	//NEW LIGHTMAP: changing to linear
	in float3 view_light_dir,				// normalized
	in float3 light_color,
	in float3 albedo_color,
	in float3 specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	in float3x3 tangent_frame,				// = {tangent, binormal, normal};
	in float4 misc,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	inout float3 diffuse_radiance
)
{
	calc_material_cook_torrance_base(view_dir, fragment_to_camera_world, view_normal, view_reflect_dir_world, sh_lighting_coefficients, view_light_dir, light_color, albedo_color, specular_mask, texcoord, prt_ravi_diff, tangent_frame, misc, specular_tint, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, specular_color, diffuse_radiance);
}

#else

void calc_material_model_cook_torrance_reach_ps(
	in float3 v_view_dir,
	in float3 fragment_to_camera_world,
	in float3 v_view_normal,
	in float3 view_reflect_dir_world,
	in float4 sh_lighting_coefficients[10],
	in float3 v_view_light_dir,
	in float3 light_color,
	in float3 albedo_color,
	in float3 specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	out float3 diffuse_color)
{
    diffuse_color = diffuse_in;
    specular_color = 0.0f;

    envmap_specular_reflectance_and_roughness.xyz = environment_map_specular_contribution * specular_mask * specular_coefficient;
    envmap_specular_reflectance_and_roughness.w = roughness; // TODO: replace with whatever you use for roughness	

    envmap_area_specular_only = 1.0f;
}
#endif

#endif //ifndef _SH_GLOSSY_FX_
