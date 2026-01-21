#ifndef _FOLIAGE_ONLY_FX_
#define _FOLIAGE_ONLY_FX_

/*
foliage.fx
Tue, Jan 10, 2005 5:41pm (ctchou)
*/


//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************


float get_material_foliage_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_foliage_ps(float3 specular_mask)
{
	return 0.0f;
}

float3 get_diffuse_multiplier_foliage_ps()
{
	return 1.0f;
}

void calc_material_analytic_specular_foliage_ps(
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

void calc_material_foliage_ps(
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

	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	
	if (!no_dynamic_lights)
	{
		float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;

		calc_simple_lights_analytical(
			fragment_position_world,
			surface_normal,
			view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
			1.0f,
			simple_light_diffuse_light,
			simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}

	//float3 diffuse_part= ravi_order_0(surface_normal, sh_lighting_coefficients);
	diffuse_radiance= diffuse_radiance * prt_ravi_diff.x;
	diffuse_radiance= simple_light_diffuse_light + diffuse_radiance;
	specular_radiance= 0.0f;
	
	envmap_specular_reflectance_and_roughness= float4(1.0f, 1.0f, 1.0f, 0.0f);
	envmap_area_specular_only= 0.282094815f * sh_lighting_coefficients[0].xyz;

		
}


#endif // _foliage_FX_
