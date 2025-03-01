#ifndef _TWO_LOBE_PHONG_FX_
#define _TWO_LOBE_PHONG_FX_

#include "shared_specular_reach.fx"
#include "vmf_util.fx"
//#include "templated\materials\diffuse_specular.fx"
//#include "templated\materials\phong_specular.fx"


/*
two_lobe_phong.fx
Mon, Nov 11, 2005 2:01pm (haochen)
*/

void calculate_area_specular_phong_order_2(
	in float3 reflection_dir,
	in float4 sh_lighting_coefficients[4],
	in float power,
	in float3 tint,
	out float3 s0)
{

	float p_0= 0.4231425f;									// 0.886227f			0.282095f * 1.5f;
	float p_1= -0.3805236f;									// 0.511664f * -2		exp(-0.5f * power_invert) * (-0.488602f);
	float p_2= -0.4018891f;									// 0.429043f * -2		exp(-2.0f * power_invert) * (-1.092448f);
	float p_3= -0.2009446f;									// 0.429043f * -1

	float3 x0, x1, x2, x3;
	
	//constant
	x0= sh_lighting_coefficients[0].rgb * p_0; // H3 sh_lighting_coefficients[0].rrr
	
	// linear
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].xyz);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].xyz);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].xyz);
	x1 *= p_1;
	
	s0= (x0 + x1 ) * tint;
		
}

//*****************************************************************************
// Analytical model for point light source only
//*****************************************************************************

float get_material_two_lobe_phong_reach_specular_power(float power_or_roughness)
{
	return power_or_roughness;
}


float3 get_analytical_specular_multiplier_two_lobe_phong_reach_ps(float specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution;
}

float3 get_diffuse_multiplier_two_lobe_phong_reach_ps()
{
	return diffuse_coefficient;
}

float analytical_Phong_specular(in float3 L, in float3 R, float fPower)
{
    float fRDotL = saturate(dot(R, L));

    return pow(saturate(fRDotL), fPower) * (1 + fPower);
}

float4 calc_material_analytic_specular_two_lobe_phong_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,	
	in float vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 normal_specular_blend_albedo_color,			// specular reflectance at normal incidence
	out float3 analytic_specular_radiance,					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
	out float3 additional_diffuse_radiance)
{
	float3 final_specular_tint_color;
	float3 surface_normal= tangent_frame[2];

	//figure out the blended power and blended specular tint
	float specular_roughness;
	float specular_power= 0.0f;
	calculate_fresnel(view_dir, normal_dir, diffuse_albedo_color, specular_power, specular_roughness, normal_specular_blend_albedo_color,final_specular_tint_color);
	material_parameters.rgb= float3(specular_coefficient, albedo_specular_tint_blend, environment_map_specular_contribution);
	material_parameters.a= specular_power;
	
	analytic_specular_radiance=analytical_Phong_specular(light_dir,view_reflect_dir,analytical_power)*final_specular_tint_color*light_irradiance;
    
	additional_diffuse_radiance = 0;
	return float4(final_specular_tint_color,specular_roughness);
}

void calc_material_analytic_specular_two_lobe_phong_reach_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l,
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
    float3 additional_diffuse_radiance;
    specular_fresnel_color = calc_material_analytic_specular_two_lobe_phong_ps(
		view_dir,
		normal_dir,
		view_reflect_dir,
		light_dir,
		light_irradiance,
		diffuse_albedo_color,
		texcoord,
		vertex_n_dot_l,
		tangent_frame,
		misc,
		material_parameters,
		specular_albedo_color,
		analytic_specular_radiance,
		additional_diffuse_radiance);
}

//*****************************************************************************
// area specular for area light source
//*****************************************************************************


//*****************************************************************************
// the material model
//*****************************************************************************
	
void calc_material_two_lobe_phong_reach_ps(
	in float3 view_dir,
	in float3 fragment_to_camera_world,
	in float3 surface_normal,
	in float3 view_reflect_dir,
	in float4 sh_lighting_coefficients[10],
	in float3 analytical_light_dir,
	in float3 analytical_light_intensity,
	in float3 diffuse_reflectance,
	in float3 specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	in float3x3 tangent_frame, // = {tangent, binormal, normal};
	in float4 misc,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	inout float3 diffuse_radiance)
{

	float3 analytic_specular_radiance;
	float3 normal_specular_blend_albedo_color;
	float4 material_parameters;
	
	float3 analytical_specular_color;
	float3 additional_diffuse_radiance;
	float4 final_specular_tint_color=calc_material_analytic_specular_two_lobe_phong_ps(
		view_dir,
		surface_normal,
		view_reflect_dir,
		analytical_light_dir,
		analytical_light_intensity,
		diffuse_reflectance,
		texcoord,	
		prt_ravi_diff.w,
		tangent_frame,
		misc,
		material_parameters,
		normal_specular_blend_albedo_color,
		analytic_specular_radiance, 
		additional_diffuse_radiance);

	//analytic_specular_radiance*=sh_lighting_coefficients[0].a;

	// calculate simple dynamic lights	
	float3 simple_light_diffuse_light;//= 0.0f;
	float3 simple_light_specular_light;//= 0.0f;	
	
	if (!no_dynamic_lights)
	{
		float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
		
		// todo: switch to reach lights
		calc_simple_lights_analytical_reach(
			fragment_position_world,
			surface_normal,
	//		fragment_to_camera_world,
			view_reflect_dir,												// view direction = fragment to camera,   reflected around fragment normal
			analytical_power,
			simple_light_diffuse_light,
			simple_light_specular_light);
		simple_light_specular_light*= final_specular_tint_color.xyz;
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}
	
	float3 area_specular_radiance;
	//{
	//	float4 vmf[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
	//
    //    dual_vmf_diffuse_specular_with_fresnel(
	//		view_dir,
	//		surface_normal,
	//		vmf,
	//		final_specular_tint_color,
	//		final_specular_tint_color.a,
	//		area_specular_radiance);
	//}
	{
		float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		
		calculate_area_specular_phong_order_2(
			view_reflect_dir,
			temp,
			material_parameters.a,
			final_specular_tint_color.rgb,
			area_specular_radiance);
		
		// todo: fix indirect lighting
		/*
		dual_vmf_diffuse_specular_with_fresnel_emulated(
			view_dir,
			surface_normal,
			analytical_light_dir,
			analytical_light_intensity,
			final_specular_tint_color.rgb,
			final_specular_tint_color.a,
			area_specular_radiance
		);
		*/
	}
	
	//scaling and masking
    specular_color.xyz= specular_mask * material_parameters.r * (
		(simple_light_specular_light + max(analytic_specular_radiance, 0.0f)) * analytical_specular_contribution +
		max(area_specular_radiance * area_specular_contribution, 0.0f));
		
	specular_color.w= 0.0f;

	//modulate with prt	
	specular_color*= prt_ravi_diff.z;	

	//output for environment stuff
	float raised_analytical_dot_product= saturate(dot(analytical_light_dir, surface_normal)*0.45f+0.55f);
		
	float fake_analytical_mask = 1.0f;
	float fake_cloud_mask = 1.0f;
	float3 fake_prebaked_analytical_light = raised_analytical_dot_product * analytical_light_intensity/* * fake_analytical_mask * fake_cloud_mask*/ * 0.25f * prt_ravi_diff.z;
	envmap_area_specular_only= fake_prebaked_analytical_light * final_specular_tint_color.rgb + area_specular_radiance * prt_ravi_diff.z;
	envmap_specular_reflectance_and_roughness.xyz=	material_parameters.b * specular_mask * material_parameters.r;
	envmap_specular_reflectance_and_roughness.w= max(0.01f, 1.01 - material_parameters.a / 200.0f);		// convert specular power to roughness (cheap and bad approximation);

	// from entry point
	float analytical_light_dot_product_result=saturate(dot(analytical_light_dir,surface_normal));
	diffuse_radiance += fake_analytical_mask * analytical_light_dot_product_result * 
		analytical_light_intensity / 3.14159265358979323846 * fake_analytical_mask;
	
	//do diffuse
	diffuse_radiance= prt_ravi_diff.x * diffuse_radiance;
	diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_coefficient;
	
}


#endif 