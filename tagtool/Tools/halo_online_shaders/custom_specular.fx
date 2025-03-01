#ifndef _CUSTOM_SPECULAR_FX_
#define _CUSTOM_SPECULAR_FX_


//****************************************************************************
// custom specular
//****************************************************************************

sampler2D	specular_lobe;							// specular power, tint	(indexed by direction towards sun, and material map)
sampler1D	glancing_falloff;						// fresnel curve
sampler2D	material_map;							// material map -- 
float4		material_map_xform;						// 

// float analytical_anti_shadow_control;				// do we need?


//*****************************************************************************
// Analytical model for point light source only
//*****************************************************************************
float get_material_custom_specular_specular_power(float power_or_roughness)
{
	return power_or_roughness;
}

float3 get_analytical_specular_multiplier_custom_specular_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution;
}

float3 get_diffuse_multiplier_custom_specular_ps()
{
	return diffuse_coefficient;
}

void calc_material_analytic_specular_custom_specular_ps(
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
	float3 surface_normal= tangent_frame[2];

	material_parameters.rgb= float3(specular_coefficient, 0.0f /* albedo_specular_tint_blend */, environment_map_specular_contribution);
	material_parameters.a= 50.0f;	// power_or_roughness;

    float n_dot_v = dot(normal_dir, view_dir);
    specular_fresnel_color=	tex1D(glancing_falloff, n_dot_v).rgb;

	// half-angle formula
	float3 half_dir=	normalize(view_dir + light_dir);
	float h_dot_n=		saturate(dot(half_dir, normal_dir));

	float material_sample=		tex2D(material_map, transform_texcoord(texcoord, material_map_xform)).g;

	float4 lobe_sample=	tex2D(specular_lobe, float2(h_dot_n, material_sample));

	analytic_specular_radiance= light_irradiance * specular_fresnel_color * lobe_sample.rgb * lobe_sample.rgb;
	specular_albedo_color= float3(1.0f, 1.0f, 1.0f);		// specular_tint
}


//*****************************************************************************
// the material model
//*****************************************************************************
	
void calc_material_custom_specular_ps(
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
	in float3x3 tangent_frame,				// = {tangent, binormal, normal};
	in float4 misc,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	inout float3 diffuse_radiance)
{
	float3 analytic_specular_radiance;
	float3 specular_fresnel_color;
	float3 specular_albedo_color;
	float4 material_parameters;
	
	calc_material_analytic_specular_custom_specular_ps(
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
		specular_fresnel_color,
		specular_albedo_color,
		analytic_specular_radiance);

/*		
	// apply anti-shadow
	if (analytical_anti_shadow_control > 0.0f)
	{
		float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		float ambientness= calculate_ambientness(temp, analytical_light_intensity, analytical_light_dir);
		float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
		analytic_specular_radiance*= ambient_multiplier;
	}
*/
/*
	// calculate simple dynamic lights	
	float3 simple_light_diffuse_light;//= 0.0f;
	float3 simple_light_specular_light;//= 0.0f;	
	
	if (!no_dynamic_lights)
	{
		float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
		calc_simple_lights_analytical(
			fragment_position_world,
			surface_normal,
	//		fragment_to_camera_world,
			view_reflect_dir,												// view direction = fragment to camera,   reflected around fragment normal
			material_parameters.a,
			simple_light_diffuse_light,
			simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}
*/

/*	
	float3 area_specular_radiance;
	if (order3_area_specular)
	{
		calculate_area_specular_phong_order_3(
			view_reflect_dir,
			sh_lighting_coefficients,
			material_parameters.a,
			specular_fresnel_color,
			area_specular_radiance);
	}
	else
	{
		float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};

		calculate_area_specular_phong_order_2(
			view_reflect_dir,
			temp,
			material_parameters.a,
			specular_fresnel_color,
			area_specular_radiance);
	}
*/
	
	//scaling and masking
//	specular_color.xyz= specular_mask * material_parameters.r * (
//		(simple_light_specular_light + max(analytic_specular_radiance, 0.0f)) * analytical_specular_contribution +
//		max(area_specular_radiance * area_specular_contribution, 0.0f));

	specular_color.xyz=	specular_mask * (analytic_specular_radiance * material_parameters.r);	
	specular_color.w= 0.0f;

	//modulate with prt	
	specular_color*= prt_ravi_diff.z;

	//output for environment stuff
	envmap_area_specular_only= prt_ravi_diff.z;		// area_specular_radiance * 
	envmap_specular_reflectance_and_roughness.xyz=	specular_fresnel_color * specular_mask * material_parameters.b * material_parameters.r;
	envmap_specular_reflectance_and_roughness.w=	0.0f;					// max(0.01f, 1.01 - material_parameters.a / 200.0f);		// convert specular power to roughness (cheap and bad approximation);

	//do diffuse
	//float3 diffuse_part= ravi_order_3(surface_normal, sh_lighting_coefficients);
	diffuse_radiance= prt_ravi_diff.x * diffuse_radiance;
//	diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_coefficient;
	diffuse_radiance= diffuse_radiance * diffuse_coefficient;
}


#endif 