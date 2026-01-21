#ifndef _glass_FX_
#define _glass_FX_

/*
glass_material.fx
Mon, Feb 19, 2007 5:41pm (haochen)
*/


//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************


float get_material_glass_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_glass_ps(float3 specular_mask)
{
	return 0.0f;
}

float3 get_diffuse_multiplier_glass_ps()
{
	return 1.0f;
}

void calc_material_analytic_specular_glass_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vert_n_dot_l,
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	specular_fresnel_color= 0.0f;
	analytic_specular_radiance= 0.0f;
	specular_albedo_color= 0.0f;
	material_parameters= 1.0f;
}

PARAM(float, fresnel_coefficient);
PARAM(float, fresnel_curve_steepness);
PARAM(float, fresnel_curve_bias);
PARAM(float, roughness);

void calc_material_glass_ps(
	in float3 view_dir,
	in float3 fragment_to_camera_world,
	in float3 surface_normal,
	in float3 view_reflect_dir_world,
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
	out float4 specular_radiance,
	inout float3 diffuse_radiance)
{

	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;

	float3 area_specular= 0.0f;
	if (area_specular_contribution > 0.0f)
	{
		calculate_area_specular_new_phong_3(
			view_reflect_dir_world,
			sh_lighting_coefficients,
			roughness,
			false,
			area_specular);
	}

	float3 analytical_specular= 0.0f;
	if (analytical_specular_contribution > 0.0f)
	{
		calculate_analytical_specular_new_phong_3(
			analytical_light_dir,
			analytical_light_intensity,
			view_reflect_dir_world,
			roughness,
			analytical_specular);
	}

	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;

	if (!no_dynamic_lights)
	{
		calc_simple_lights_analytical(
			fragment_position_world,
			surface_normal,
			view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
			//(roughness == 0) ? 0 : (0.27291 * pow(roughness, -2.1973)),
			0.27291 * pow(roughness, -2.1973),
			simple_light_diffuse_light,
			simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}

	float fresnel= fresnel_coefficient+(1.0f - fresnel_coefficient) * pow(1.0 - max(dot(surface_normal, view_dir), 0.0f), fresnel_curve_steepness) + fresnel_curve_bias;
	specular_radiance.xyz= (area_specular * area_specular_contribution + analytical_specular * analytical_specular_contribution + simple_light_specular_light) * specular_coefficient * specular_mask;
	specular_radiance.w= fresnel;
	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light) * diffuse_coefficient;
	float3 env_multiplyer= specular_coefficient * fresnel * specular_mask.xxx; // TODO confirm spec mask here, might have input wrong
	envmap_specular_reflectance_and_roughness= float4(env_multiplyer.r, env_multiplyer.g, env_multiplyer.b, roughness);
	envmap_area_specular_only= sh_lighting_coefficients[0].xyz;
}


#endif // _glass_FX_
