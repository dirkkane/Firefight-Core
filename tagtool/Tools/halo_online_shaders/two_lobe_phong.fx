#ifndef _TWO_LOBE_PHONG_FX_
#define _TWO_LOBE_PHONG_FX_

/*
two_lobe_phong.fx
Mon, Nov 11, 2005 2:01pm (haochen)
*/

//****************************************************************************
// Two lobe phong material model parameters
//****************************************************************************

#ifdef APPLY_FIXES
#ifdef ALBEDO_DEFINED
#if ALBEDO_TYPE(calc_albedo_ps) == ALBEDO_TYPE_calc_albedo_four_change_color_applying_to_specular_ps
	#define normal_specular_tint tertiary_change_color
	#define glancing_specular_tint quaternary_change_color
	#define TINTS_DEFINED 1
#endif
#endif
#endif

PARAM(float,	normal_specular_power);						// power of the specular lobe at normal incident angle
#ifndef TINTS_DEFINED
PARAM(float3,	normal_specular_tint);						// specular color of the normal specular lobe
#endif
PARAM(float,	glancing_specular_power);					// power of the specular lobe at glancing incident angle
#ifndef TINTS_DEFINED
PARAM(float3,	glancing_specular_tint);					// specular color of the glancing specular lobe
#endif
PARAM(float,	fresnel_curve_steepness);					// 
PARAM(float,	albedo_specular_tint_blend);				// mix albedo color into specular reflectance

PARAM(float, analytical_anti_shadow_control);

PARAM_SAMPLER_2D(normal_specular_tint_map);
PARAM_SAMPLER_2D(glancing_specular_tint_map);

//*****************************************************************************
// artist fresnel
//*****************************************************************************

void calculate_fresnel(
	in float3 view_dir,				
	in float3 normal_dir,
	in float3 albedo_color,
	out float power,
	out float3 tint)
{
	//float n_dot_v = dot( normal_dir, view_dir );
    float n_dot_v = max(dot( normal_dir, view_dir ), 0.0f);
    float fresnel_blend= pow((1.0f - n_dot_v ), fresnel_curve_steepness); 
    power= lerp(normal_specular_power, glancing_specular_power, fresnel_blend);
    //float3 normal_tint= lerp(normal_specular_tint, albedo_color, albedo_specular_tint_blend);
    //tint= lerp(normal_tint, glancing_specular_tint, fresnel_blend);

    tint= lerp(normal_specular_tint, glancing_specular_tint, fresnel_blend);
    tint= lerp(tint, albedo_color, albedo_specular_tint_blend);
}

void calculate_fresnel_tint_map(
	in float2 texcoord,
	in float3 view_dir,				
	in float3 normal_dir,
	in float3 albedo_color,
	out float power,
	out float3 tint)
{
	//float n_dot_v = dot( normal_dir, view_dir );

    float3 nst = sample2D(normal_specular_tint_map, texcoord).xyz * normal_specular_tint;
    float3 gst = sample2D(glancing_specular_tint_map, texcoord).xyz * glancing_specular_tint;

    float n_dot_v = max(dot( normal_dir, view_dir ), 0.0f);
    float fresnel_blend= pow((1.0f - n_dot_v ), fresnel_curve_steepness); 
    power= lerp(normal_specular_power, glancing_specular_power, fresnel_blend);
    //float3 normal_tint= lerp(nst, albedo_color, albedo_specular_tint_blend);
    //tint= lerp(normal_tint, gst, fresnel_blend);

    tint= lerp(nst, gst, fresnel_blend);
    tint= lerp(tint, albedo_color, albedo_specular_tint_blend);
}

//*****************************************************************************
// Analytical model for point light source only
//*****************************************************************************

float get_material_two_lobe_phong_specular_power(float power_or_roughness)
{
	return power_or_roughness;
}


float3 get_analytical_specular_multiplier_two_lobe_phong_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution;
}

float3 get_analytical_specular_multiplier_two_lobe_phong_tint_map_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution;
}

float3 get_diffuse_multiplier_two_lobe_phong_ps()
{
	return diffuse_coefficient;
}

float3 get_diffuse_multiplier_two_lobe_phong_tint_map_ps()
{
	return diffuse_coefficient;
}

void calc_material_analytic_specular_two_lobe_phong_ps(
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

	//figure out the blended power and blended specular tint
	float power_or_roughness= 0.0f;
	specular_fresnel_color= 0.0f;
	calculate_fresnel(view_dir, normal_dir, diffuse_albedo_color, power_or_roughness, specular_fresnel_color);
	specular_albedo_color= normal_specular_tint;
	material_parameters.rgb= float3(specular_coefficient, albedo_specular_tint_blend, environment_map_specular_contribution);
	material_parameters.a= power_or_roughness;
    
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

void calc_material_analytic_specular_two_lobe_phong_tint_map_ps(
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

	//figure out the blended power and blended specular tint
	float power_or_roughness= 0.0f;
	specular_fresnel_color= 0.0f;
	calculate_fresnel_tint_map(texcoord, view_dir, normal_dir, diffuse_albedo_color, power_or_roughness, specular_fresnel_color);
	specular_albedo_color= sample2D(normal_specular_tint_map, texcoord).xyz;
	material_parameters.rgb= float3(specular_coefficient, albedo_specular_tint_blend, environment_map_specular_contribution);
	material_parameters.a= power_or_roughness;
    
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


/*
void calculate_analytical_phong(
  	in float3 normal_dir,
	in float3 view_dir,	
	in float3 reflect_dir,
	in float3 light_dir,
	in float3 light_color,
	in float power,
	in float3 tint,
	out float3 specular)
{			
    float n_dot_l = dot( normal_dir, light_dir );
    float n_dot_v = dot( normal_dir, view_dir );
    float l_dot_r = max(dot(light_dir, reflect_dir), 0.0f); 
    
    if (n_dot_l > 0 && n_dot_v > 0 )
    {
		specular= pow(l_dot_r, power) * ((power + 1.0f) / 6.2832) * tint * light_color;
	}
	else
	{
		specular= 0.0f;
	}
}
*/


//*****************************************************************************
// area specular for area light source
//*****************************************************************************
void calculate_area_specular_phong_order_3(
	in float3 reflection_dir,
	in float4 sh_lighting_coefficients[10],
	in float power,
	in float3 tint,
	out float3 s0)
{
	
	//float power_invert= 1.0f/(power+ 0.00001f);
	//float p_0= 0.282095f * 1.5f;
	//float p_1= exp(-0.5f * power_invert) * (-0.488602f);
	//float p_2= exp(-2.0f * power_invert) * (-1.092448f);
	
	float p_0= 0.4231425f;									// 0.886227f			0.282095f * 1.5f;
	float p_1= -0.3805236f;									// 0.511664f * -2		exp(-0.5f * power_invert) * (-0.488602f);
	float p_2= -0.4018891f;									// 0.429043f * -2		exp(-2.0f * power_invert) * (-1.092448f);
	float p_3= -0.2009446f;									// 0.429043f * -1

	float3 x0, x1, x2, x3;
	
	//constant
#ifdef APPLY_FIXES
	x0= sh_lighting_coefficients[0].rgb * p_0;
#else
    x0 = sh_lighting_coefficients[0].r * p_0;
#endif
	
	// linear
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].xyz);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].xyz);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].xyz);
	x1 *= p_1;
	
	//quadratic
	float3 quadratic_a= (reflection_dir.xyz)*(reflection_dir.yzx);
	x2.x= dot(quadratic_a, sh_lighting_coefficients[4].xyz);
	x2.y= dot(quadratic_a, sh_lighting_coefficients[5].xyz);
	x2.z= dot(quadratic_a, sh_lighting_coefficients[6].xyz);
	x2 *= p_2;

	float4 quadratic_b = float4( reflection_dir.xyz*reflection_dir.xyz, 1.f/3.f );
	x3.x= dot(quadratic_b, sh_lighting_coefficients[7]);
	x3.y= dot(quadratic_b, sh_lighting_coefficients[8]);
	x3.z= dot(quadratic_b, sh_lighting_coefficients[9]);
	x3 *= p_3;
	
	s0= (x0 + x1 + x2 + x3) * tint;
		
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
#ifdef APPLY_FIXES
	x0= sh_lighting_coefficients[0].rgb * p_0;
#else
    x0 = sh_lighting_coefficients[0].r * p_0;
#endif
	
	// linear
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].xyz);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].xyz);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].xyz);
	x1 *= p_1;
	
	s0= (x0 + x1 ) * tint;
		
}

//*****************************************************************************
// the material model
//*****************************************************************************
	
void calc_material_two_lobe_phong_ps(
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
/*	calculate_analytical_phong(
		surface_normal, 
		view_dir,
		view_reflect_dir,
		analytical_light_dir,
		analytical_light_intensity,
		power,
		tint,
		analytical);
*/
	float3 analytic_specular_radiance;
	float3 specular_fresnel_color;
	float3 specular_albedo_color;
	float4 material_parameters;
	
	calc_material_analytic_specular_two_lobe_phong_ps(
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
		
	// apply anti-shadow
	if (analytical_anti_shadow_control > 0.0f)
	{
		float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		float ambientness= calculate_ambientness(temp, analytical_light_intensity, analytical_light_dir);
		float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
		analytic_specular_radiance*= ambient_multiplier;
	}

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
	
	//scaling and masking
	specular_color.xyz= specular_mask * material_parameters.r * (
		(simple_light_specular_light + max(analytic_specular_radiance, 0.0f)) * analytical_specular_contribution +
		max(area_specular_radiance * area_specular_contribution, 0.0f));
		
	specular_color.w= 0.0f;

	//modulate with prt	
	specular_color*= prt_ravi_diff.z;	

	//output for environment stuff
	envmap_area_specular_only= area_specular_radiance * prt_ravi_diff.z;
	envmap_specular_reflectance_and_roughness.xyz=	material_parameters.b * specular_mask * material_parameters.r;
	envmap_specular_reflectance_and_roughness.w= max(0.01f, 1.01 - material_parameters.a / 200.0f);		// convert specular power to roughness (cheap and bad approximation);

	//do diffuse
	//float3 diffuse_part= ravi_order_3(surface_normal, sh_lighting_coefficients);
	diffuse_radiance= prt_ravi_diff.x * diffuse_radiance;
	diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_coefficient;
	
}

//*****************************************************************************
// the material model
//*****************************************************************************
	
void calc_material_two_lobe_phong_tint_map_ps(
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
	float3 specular_fresnel_color;
	float3 specular_albedo_color;
	float4 material_parameters;
	
	calc_material_analytic_specular_two_lobe_phong_tint_map_ps(
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
		
	// apply anti-shadow
	if (analytical_anti_shadow_control > 0.0f)
	{
		float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		float ambientness= calculate_ambientness(temp, analytical_light_intensity, analytical_light_dir);
		float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
		analytic_specular_radiance*= ambient_multiplier;
	}

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
	
	//scaling and masking
	specular_color.xyz= specular_mask * material_parameters.r * (
		(simple_light_specular_light + max(analytic_specular_radiance, 0.0f)) * analytical_specular_contribution +
		max(area_specular_radiance * area_specular_contribution, 0.0f));
		
	specular_color.w= 0.0f;

	//modulate with prt	
	specular_color*= prt_ravi_diff.z;	

	//output for environment stuff
	envmap_area_specular_only= area_specular_radiance * prt_ravi_diff.z;
	envmap_specular_reflectance_and_roughness.xyz=	material_parameters.b * specular_mask * material_parameters.r;
	envmap_specular_reflectance_and_roughness.w= max(0.01f, 1.01 - material_parameters.a / 200.0f);		// convert specular power to roughness (cheap and bad approximation);

	//do diffuse
	//float3 diffuse_part= ravi_order_3(surface_normal, sh_lighting_coefficients);
	diffuse_radiance= prt_ravi_diff.x * diffuse_radiance;
	diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_coefficient;
	
}


#endif 
