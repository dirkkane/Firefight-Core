#ifndef _HAIR_MATERIAL_FX_
#define _HAIR_MATERIAL_FX_

/*
hair_material.fx
Mon, Feb 4, 2008 2:01pm (xwan)
*/

//****************************************************************************
// Organism material model parameters
//****************************************************************************

// diffuse
PARAM(float3, diffuse_tint);

// specular from lighting
PARAM(float, area_specular_coefficient);
PARAM(float, analytical_specular_coefficient);
PARAM(float3, specular_tint);
PARAM(float, specular_power);
PARAM_SAMPLER_2D(specular_map);
PARAM_SAMPLER_2D(specular_shift_map);
PARAM_SAMPLER_2D(specular_noise_map);

// specular from environment map
PARAM(float, environment_map_coefficient);
PARAM(float3, environment_map_tint);

// final tint
PARAM(float3, final_tint);

PARAM(float, analytical_anti_shadow_control);

#ifdef pc
	#define FORCE_BRANCH
#else
	#define FORCE_BRANCH	[branch]
#endif

void calc_material_analytic_specular_hair(	
	in float3 tangent_dir,									// tangent direction in world space
	in float3 reflect_half,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color	
	float power_or_roughness,
	out float3 analytic_specular_radiance)	
{   	
	const float t_dot_h = dot(tangent_dir, reflect_half); 	
	//if ( t_dot_h > 0 )
	{
		const float sin_t_h= sqrt( 1.0f - t_dot_h*t_dot_h);        
		analytic_specular_radiance= pow(sin_t_h, power_or_roughness) * light_irradiance;
	}
	//else
	//{
	//	analytic_specular_radiance= 0.0f;
	//}
}


void calculate_area_specular_phong_order_2(
	in float3 reflection_dir,
	in float4 sh_lighting_coefficients[10],		
	out float3 s0)
{
															//float power_invert= 0.5f;
	float p_0= 0.4231425f;									// 0.886227f			0.282095f * 1.5f;
	float p_1= -0.3805236f;									// 0.511664f * -2		exp(-0.5f * power_invert) * (-0.488602f);
	float p_2= -0.4018891f;									// 0.429043f * -2		exp(-2.0f * power_invert) * (-1.092448f);
	float p_3= -0.2009446f;									// 0.429043f * -1

	float3 x0, x1, x2, x3;
	
	//constant
	x0= sh_lighting_coefficients[0].r * p_0;
	
	// linear
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1]);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2]);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3]);
	x1 *= p_1;
	
	//s0= x0 + x1;		
	s0= x1;
}

//*****************************************************************************
// the material model
//*****************************************************************************
	
void calc_material_hair_ps(
	in float3 view_dir,
	in float3 fragment_to_camera_world,
	in float3 bump_normal,
	in float3 view_reflect_by_bump_dir,
	in float4 sh_lighting_coefficients[10],
	in float3 analytical_light_dir,
	in float3 analytical_light_intensity,
	in float3 diffuse_reflectance,
	in float  specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	in float3x3 tangent_frame,				// = {tangent, binormal, normal};
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 output_color,
	inout float3 diffuse_radiance)
{	
	const float3 surface_tangent= tangent_frame[1];
	const float3 surface_normal= tangent_frame[2];
	
	float specular_shift= sample2D(specular_shift_map, texcoord).x;
	specular_shift-= 0.5f;
	float specular_noise= sample2D(specular_noise_map, texcoord).x;

	float3 tangent_0= surface_tangent + surface_normal*specular_shift;
	float3 tangent_1= surface_tangent - surface_normal*specular_shift*specular_noise;
	normalize(tangent_0);
	normalize(tangent_1);


	float3 bi_view_dir= cross(view_dir, surface_tangent);		

	
	float3 area_specular_normal_0= cross(tangent_0, bi_view_dir);
	normalize(area_specular_normal_0);		
	float3 view_reflect_by_hair_0= reflect(-view_dir, area_specular_normal_0);	

	float3 area_specular_normal_1= cross(tangent_1, bi_view_dir);
	normalize(area_specular_normal_1);		
	float3 view_reflect_by_hair_1= reflect(-view_dir, area_specular_normal_1);	
	

	// sample specular map
	float4 specular_map_color= sample2D(specular_map, texcoord);
	float power_or_roughness= specular_map_color.a * specular_power;	

	// calculate simple dynamic lights	
	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
	float3 simple_lights_bump_diffuse= 0.0f;
	float3 simple_lights_bump_specular_0= 0.0f;
	float3 simple_lights_bump_specular_1= 0.0f;
	
	if (!no_dynamic_lights)
	{			
		calc_simple_lights_analytical(
			fragment_position_world,
			area_specular_normal_0,
			view_reflect_by_hair_0,	
			sqrt(power_or_roughness), // dim the power as a hack
			simple_lights_bump_diffuse,
			simple_lights_bump_specular_0);

		calc_simple_lights_analytical(
			fragment_position_world,
			area_specular_normal_1,
			view_reflect_by_hair_1,	
			sqrt(power_or_roughness), // dim the power as a hack
			simple_lights_bump_diffuse,
			simple_lights_bump_specular_1);
	}

	// calculate diffuse color
	float3 diffuse_color;
	{
		diffuse_color= 
			(simple_lights_bump_diffuse + diffuse_radiance) * 
			diffuse_coefficient * diffuse_tint; // * albedo.xyz * albedo.w
	}

	// calculate specular from analytic and area
	float3 analytic_specular_radiance;
	{
		float3 reflect_half= view_dir + analytical_light_dir;
		reflect_half= normalize(reflect_half);

		float3 specular_0, specular_1;
		calc_material_analytic_specular_hair(		
			tangent_0,
			reflect_half,
			analytical_light_dir,
			analytical_light_intensity,		
			power_or_roughness,
			specular_0);

		calc_material_analytic_specular_hair(		
			tangent_1,
			reflect_half,
			analytical_light_dir,
			analytical_light_intensity,		
			power_or_roughness*specular_noise,
			specular_1);

		analytic_specular_radiance= 
			specular_0 + simple_lights_bump_specular_0 + 
			(specular_1 + simple_lights_bump_specular_1) *specular_noise;
	}

	float3 area_specular_radiance;
	{
		calculate_area_specular_phong_order_2(			
			view_reflect_by_hair_1,
			sh_lighting_coefficients,						
			area_specular_radiance);
		area_specular_radiance= max(area_specular_radiance, 0);
	}

	float3 specular_color=
		analytic_specular_radiance*analytical_specular_coefficient + 
		area_specular_radiance*area_specular_coefficient;

	specular_color*=
		specular_tint * specular_map_color.rgb;


	// calculate environment parameters
	{
		envmap_area_specular_only= prt_ravi_diff.z;
		envmap_specular_reflectance_and_roughness.xyz= environment_map_tint * environment_map_coefficient * specular_map_color.rgb;
		envmap_specular_reflectance_and_roughness.w= 1.0f;
	}
	
	//do color output
	output_color.xyz=
		specular_color;
	output_color.w= 1.0f; 	
	
	//do albedo
	diffuse_radiance= 		
		diffuse_color;

	// final tint
	output_color.xyz*= final_tint * prt_ravi_diff.z;
	diffuse_radiance*= final_tint * prt_ravi_diff.x;
}


////////////////////////////////////////////////////////////////////////////////////////////
// No idea
////////////////////////////////////////////////////////////////////////////////////////////

float3 get_analytical_specular_multiplier_hair_ps(float specular_mask)
{
	return 1.0f;
}

float3 get_diffuse_multiplier_hair_ps()
{
	return 0.0f;
}

void calc_material_analytic_specular_hair_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 bump_normal,									// bumped fragment surface normal, in world space
	in float3 view_reflect_by_bump_dir,						// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l,
	in float3x3 tangent_frame,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];
	float3 surface_tangent= tangent_frame[1];

	// sample specular map
	float4 specular_map_color= sample2D(specular_map, texcoord);
	float power_or_roughness= specular_map_color.a * specular_power;	

	// calculate diffuse color
	float3 simple_lights_bump_diffuse= saturate(dot(light_dir, bump_normal)) * light_irradiance;	
	float3 diffuse_color= 
			simple_lights_bump_diffuse * diffuse_coefficient * diffuse_tint;

	// calculate specular from analytic and area
		// calculate specular from analytic and area
	float3 specular_color;
	{
		float3 reflect_half= view_dir + light_dir;
		reflect_half= normalize(reflect_half);

		float specular_shift= sample2D(specular_shift_map, texcoord).x;
		specular_shift-= 0.5f;

		float specular_noise= sample2D(specular_noise_map, texcoord).x;

		float3 tangent_0= surface_tangent + surface_normal*specular_shift;
		float3 tangent_1= surface_tangent - surface_normal*specular_shift*specular_noise;
		normalize(tangent_0);
		normalize(tangent_1);

		float3 specular_0, specular_1;
		calc_material_analytic_specular_hair(		
			tangent_0,
			reflect_half,
			light_dir,
			light_irradiance,		
			power_or_roughness,
			specular_0);

		calc_material_analytic_specular_hair(		
			tangent_1,
			reflect_half,
			light_dir,
			light_irradiance,		
			power_or_roughness*specular_noise,
			specular_1);

		specular_color= specular_0 + specular_1*specular_noise;
	}

	specular_color*= analytical_specular_coefficient *
			specular_tint * specular_map_color.rgb;

	//do color output
	analytic_specular_radiance= 			
		specular_color+ 				
		diffuse_color * diffuse_albedo_color;

	analytic_specular_radiance*= final_tint;

	// bullshits
	material_parameters= 0.0f;
	specular_fresnel_color= 0.0f;
	specular_albedo_color= 0.0f;
}

#undef FORCE_BRANCH
#endif //_HAIR_MATERIAL_FX_