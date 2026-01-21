#ifndef _PHONG_H2_FX_
#define _PHONG_H2_FX_

PARAM(int, 		light_type);
PARAM(float3,	normal_specular_tint);						// specular color of the normal specular lobe
PARAM(float3,	glancing_specular_tint);					// specular color of the glancing specular lobe
PARAM(float3,	normal_env_tint);						// specular color of the normal specular lobe
PARAM(float3,	glancing_env_tint);					// specular color of the glancing specular lobe
PARAM(float,	normal_env_brightness);				// mix albedo color into specular reflectance
PARAM(float,	glancing_env_brightness);				// mix albedo color into specular reflectance
/*
phong_h2.fx
Mon, Feb 19, 2007 5:41pm (haochen)
*/


//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************


float get_material_phong_h2_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_phong_h2_ps(float specular_mask)
{
	return 0.0f;
}

float3 get_diffuse_multiplier_phong_h2_ps()
{
	return 1.0f;
}

void calc_material_analytic_specular_phong_h2_ps(
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
//literal H2 code, as intepretted by an idiot
	int caseint = max(light_type, 3);
	float power_or_roughness= 0.0f;

	[branch]
	if (caseint == 0)
	{
		power_or_roughness = 0;
		material_parameters.rgb= float3(0.0f, 0.0f, environment_map_specular_contribution);
		material_parameters.a= power_or_roughness;
	}
	else if (caseint == 1)
	{
		power_or_roughness = 8;
		material_parameters.rgb= float3(0.3f, 0.0f, environment_map_specular_contribution);
		material_parameters.a= power_or_roughness;
	}
	else if (caseint == 2)
	{
		power_or_roughness = 2;
		material_parameters.rgb= float3(0.5f, 0.0f, environment_map_specular_contribution);
		material_parameters.a= power_or_roughness;
	}
	else if (caseint == 3)
	{
		power_or_roughness = 120;
		material_parameters.rgb= float3(0.05f, 0.0f, environment_map_specular_contribution);
		material_parameters.a= power_or_roughness;
	}
	else 
	{
		// We should NEVER EVER hit this
		material_parameters= float4(0, 0, 0, 0);
	}

//literal H2 code, as intepretted by an idiot
	//figure out the blended power and blended specular tint
	float NdotV = saturate(dot(normal_dir, view_dir));
	specular_fresnel_color= lerp(glancing_specular_tint, normal_specular_tint, NdotV);
	specular_albedo_color= lerp(glancing_env_tint * glancing_env_brightness, normal_env_tint * normal_env_brightness, NdotV);
    
	float l_dot_r = dot(light_dir, view_reflect_dir); 

    if (l_dot_r > 0)
    {
		//analytic_specular_radiance= pow(l_dot_r, power_or_roughness) * ((sqrt(power_or_roughness) + 1.0f) / 6.2832) * specular_fresnel_color * light_irradiance;
		analytic_specular_radiance= pow(l_dot_r, power_or_roughness) * ((power_or_roughness + 1.0f) / 6.2832) * specular_fresnel_color * light_irradiance;
	}
	else
	{
		analytic_specular_radiance= 0.0f;
	}
}

PARAM(float, roughness);
PARAM(float3, specular_tint);

float specular_power_from_roughness()
{
#if DX_VERSION == 11 || (defined(APPLY_FIXES))
	if (roughness == 0)
	{
		return 0;
	}
#endif	

	return 0.27291 * pow(roughness, -2.1973);
}

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
	x0= sh_lighting_coefficients[0].r * p_0;
	
	// linear
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].xyz);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].xyz);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].xyz);
	x1 *= p_1;
	
	s0= (x0 + x1 ) * tint;
		
}

void calc_material_phong_h2_ps(
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
	//}
	float4 material_parameters = 0.0f;
	float3 analytical_specular= 0.0f;
	float3 specular_albedo_color= 0.0f;
	float3 specular_fresnel_color= 0.0f;
	if (analytical_specular_contribution > 0.0f)
	{
		calc_material_analytic_specular_phong_h2_ps(
			view_dir,										// fragment to camera, in world space
			surface_normal,									// bumped fragment surface normal, in world space
			view_reflect_dir_world,								// view_dir reflected about surface normal, in world space
			analytical_light_dir,									// fragment to light, in world space
			analytical_light_intensity,								// light intensity at fragment; i.e. light_color
			diffuse_reflectance,							// diffuse reflectance (ignored for cook-torrance)
			texcoord,
			1,
			tangent_frame,
			misc,
			material_parameters,							// only when use_material_texture is defined
			specular_fresnel_color,						// fresnel(specular_albedo_color)
			specular_albedo_color,						// specular reflectance at normal incidence
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
			material_parameters.a,
			simple_light_diffuse_light,
			simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}

		float3 area_specular;
		float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};

		calculate_area_specular_phong_order_2(
			view_reflect_dir_world,
			temp,
			material_parameters.a,
			specular_albedo_color,
			area_specular);
		
	specular_radiance.xyz= (area_specular * area_specular_contribution + analytical_specular * material_parameters.r + simple_light_specular_light * material_parameters.r ) * specular_mask;
	
	specular_radiance.w= 0.0f;
	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light) * diffuse_coefficient;
	envmap_specular_reflectance_and_roughness= float4(area_specular * specular_mask, 1);
	envmap_area_specular_only= 1;//area_specular * prt_ravi_diff.z;
	
}


#endif // _phong_h2_FX_
