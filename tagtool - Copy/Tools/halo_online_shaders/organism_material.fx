#ifndef _ORGANISM_MATERIAL_FX_
#define _ORGANISM_MATERIAL_FX_

/*
organism.fx
Wed, Apr 4, 2007 2:01pm (xwan)
It's a totally hack of sub-translucent materials, but I bet it works.
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

// specular from environment map
PARAM(float, environment_map_coefficient);
PARAM(float3, environment_map_tint);

// fresnel coefficient
PARAM(float, fresnel_curve_steepness);

// rim effects
PARAM(float, rim_coefficient);
PARAM(float3, rim_tint);
PARAM(float, rim_power);
PARAM(float, rim_start);
PARAM(float, rim_maps_transition_ratio);

// ambient
PARAM(float, ambient_coefficient);
PARAM(float3, ambient_tint);

// parameter textures
PARAM_SAMPLER_2D(occlusion_parameter_map);

// subsurface
PARAM(float, subsurface_coefficient);
PARAM(float3, subsurface_tint);
PARAM(float, subsurface_propagation_bias);
PARAM(float, subsurface_normal_detail);
PARAM_SAMPLER_2D(subsurface_map);

// transparence
PARAM(float, transparence_coefficient);
PARAM(float3, transparence_tint);
PARAM(float, transparence_normal_bias);
PARAM(float, transparence_normal_detail);
PARAM_SAMPLER_2D(transparence_map);

// final tint
PARAM(float3, final_tint);

PARAM(float, analytical_anti_shadow_control);


#ifdef pc
	#define FORCE_BRANCH
#else
	#define FORCE_BRANCH	[branch]
#endif

void calc_material_analytic_specular(	
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color	
	float power_or_roughness,
	out float3 analytic_specular_radiance)	
{   	
	float l_dot_r = dot(light_dir, view_reflect_dir); 	
    if (l_dot_r > 0)
    {
		analytic_specular_radiance= pow(l_dot_r, power_or_roughness) * ((power_or_roughness + 1.0f) / 6.2832) * light_irradiance;
	}
	else
	{
		analytic_specular_radiance= 0.0f;
	}
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
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].xyz);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].xyz);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].xyz);
	x1 *= p_1;
	
	//s0= x0 + x1;		
	s0= x1;
}

//*****************************************************************************
// the material model
//*****************************************************************************
	
void calc_material_organism_ps(
	in float3 view_dir,
	in float3 fragment_to_camera_world,
	in float3 bump_normal,
	in float3 view_reflect_by_bump_dir,
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
	out float4 output_color,
	inout float3 diffuse_radiance)
{	
	const float3 surface_normal= tangent_frame[2];

	// sample specular map
	float4 specular_map_color= sample2D(specular_map, texcoord);
	float power_or_roughness= specular_map_color.a * specular_power;	

	// calculate simple dynamic lights	
	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
	float3 simple_lights_bump_diffuse= 0.0f;
	float3 simple_lights_bump_specular= 0.0f;
	
	if (!no_dynamic_lights)
	{			
		calc_simple_lights_analytical(
			fragment_position_world,
			bump_normal,
			view_reflect_by_bump_dir,	
			power_or_roughness * dot(specular_map_color.rgb, specular_map_color.rgb),
			simple_lights_bump_diffuse,
			simple_lights_bump_specular);

		simple_lights_bump_specular*= 0.33f; // lower power magic
	}

	// calculate diffuse color
	float3 diffuse_color;
	{
		diffuse_color= 
			(simple_lights_bump_diffuse + diffuse_radiance) * 
			diffuse_coefficient * diffuse_tint; // * albedo.xyz * albedo.w
	}

	// calculate specular from analytic and area
	float3 specular_color;
	{
		float3 analytic_specular_radiance;		
		calc_material_analytic_specular(		
			bump_normal,
			view_reflect_by_bump_dir,
			analytical_light_dir,
			analytical_light_intensity,		
			power_or_roughness,
			analytic_specular_radiance);

		float3 area_specular_radiance;
		calculate_area_specular_phong_order_2(
			view_reflect_by_bump_dir,
			sh_lighting_coefficients,						
			area_specular_radiance);
		area_specular_radiance= max(area_specular_radiance, 0);

		specular_color=
			analytic_specular_radiance*analytical_specular_coefficient + 
			area_specular_radiance*area_specular_coefficient + 
			simple_lights_bump_specular*analytical_specular_coefficient;

		specular_color*=
			specular_tint * specular_map_color.rgb;
	}

	// calculate environment parameters
	{
		envmap_area_specular_only= prt_ravi_diff.z;
		envmap_specular_reflectance_and_roughness.xyz= environment_map_tint * environment_map_coefficient * specular_map_color.rgb;
		envmap_specular_reflectance_and_roughness.w= 1.0f;
	}

	
	// begin the hack of skin	
	float2 occlusion_map_value= sample2D(occlusion_parameter_map, texcoord).xy;
	float ambient_occlusion= occlusion_map_value.x;
	float visibility_occlusion= occlusion_map_value.y;	

	// calculate rim lighting
	float3 rim_color_specular= 0.0f;
	float3 rim_color_diffuse= 0.0f;
	FORCE_BRANCH
	if ( rim_coefficient > 0.01f)
	{
		float3 rim_color;
		float rim_ratio= saturate(1.0f - dot(view_dir, bump_normal));
		rim_ratio= saturate( (rim_ratio - rim_start) / max(1.0f - rim_start, 0.001f) );
		rim_ratio= pow(rim_ratio, rim_power);
		rim_color= analytical_light_intensity * rim_ratio * rim_tint * rim_coefficient;	

		// calculate contribution from specular map and diffuse map individually
		rim_color_specular= rim_color * rim_maps_transition_ratio * specular_map_color.rgb;
		rim_color_diffuse= rim_color * (1.0f - rim_maps_transition_ratio);
	}	

	// calculate ambient lighting
	float3 ambient_color= 0.0f;
	FORCE_BRANCH
	if ( ambient_coefficient > 0.01f)
	{
		ambient_color= 
			ambient_occlusion *				// ambient occlusion
			sh_lighting_coefficients[0].xyz *	// ambient light
			ambient_tint *
			ambient_coefficient; // albedo.xyz * albedo.w;
	}

	// calculate subsurface
	float3 subsurface_color= 0.0f;
	FORCE_BRANCH
	if ( subsurface_coefficient > 0.01f)
	{
		float4 subsurface_map_color= sample2D(subsurface_map, texcoord);

		float3 subsurface_normal=
			normalize(			
				lerp(surface_normal, bump_normal, subsurface_normal_detail) +				
				analytical_light_dir*subsurface_propagation_bias*subsurface_map_color.w); 
		
		float3 area_radiance_subsurface;
		calculate_area_specular_phong_order_2(
			subsurface_normal,
			sh_lighting_coefficients,			
			area_radiance_subsurface);
		area_radiance_subsurface= max(area_radiance_subsurface, 0.0f);
		
		float3 simple_lights_subsurface_diffuse= 0.0f;
		if (!no_dynamic_lights)
		{
			//float3 simple_light_subsurface_normal=
			//	normalize( lerp(surface_normal, bump_normal, subsurface_normal_detail) );

			float3 simple_lights_subsurface_specular= 0.0f;		
			calc_simple_lights_analytical(
				fragment_position_world,
				surface_normal,
				float3(0.0f, 0.0f, 1.0f),	
				power_or_roughness,
				simple_lights_subsurface_diffuse,
				simple_lights_subsurface_specular);
		}

		subsurface_color= 
			(area_radiance_subsurface + simple_lights_subsurface_diffuse) *
			subsurface_tint *
			subsurface_coefficient * 			
			subsurface_map_color.xyz * 
			ambient_occlusion;
	}

	// calculate transparence
	float3 transparence_color= 0.0f;
	FORCE_BRANCH
	if ( transparence_coefficient > 0.01f)
	{
		float4 transparence_map_color= sample2D(transparence_map, texcoord);

		float3 area_radiance_transparence= 0.0f;
		calculate_area_specular_phong_order_2(
			-view_dir,
			// TODO hack normalize(-view_dir + surface_normal * transparence_normal_bias)
			sh_lighting_coefficients,			
			area_radiance_transparence);
		area_radiance_transparence= max(area_radiance_transparence, 0.0f);

		float3 dynamic_radiance_trasparence= 0.0f;
		calc_simple_lights_analytical_diffuse_translucent(
			fragment_position_world,
			-view_dir,
			0.0f,		
			dynamic_radiance_trasparence);

		// add normal hack here
		float normal_bias= 0.0f;
		{			
			float3 transparence_normal=
				normalize( lerp(surface_normal, bump_normal, transparence_normal_detail) );

			float normal_weight= dot(view_dir, transparence_normal);
			if ( transparence_normal_bias < 0.0f)
			{
				normal_weight= 1.0f - normal_weight;
			}
			normal_bias= saturate(1.0f - normal_weight*abs(transparence_normal_bias * transparence_map_color.w));
		}

		transparence_color=
			(area_radiance_transparence + dynamic_radiance_trasparence) *
			normal_bias *
			transparence_tint *
			transparence_coefficient *
			transparence_map_color.xyz;		
	}

	//do color output
	output_color.xyz=
		rim_color_specular +
		specular_color+ 		
		subsurface_color +
		transparence_color;
	output_color.w= 0.0f; 	
	
	//do albedo
	diffuse_radiance= 		
		diffuse_color +
		rim_color_diffuse +
		ambient_color;

	// final tint
	output_color.xyz*= final_tint;
	diffuse_radiance*= final_tint;
}


////////////////////////////////////////////////////////////////////////////////////////////
// No idea
////////////////////////////////////////////////////////////////////////////////////////////

float3 get_analytical_specular_multiplier_organism_ps(float3 specular_mask)
{
	return 1.0f;
}

float3 get_diffuse_multiplier_organism_ps()
{
	return 0.0f;
}

void calc_material_analytic_specular_organism_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 bump_normal,									// bumped fragment surface normal, in world space
	in float3 view_reflect_by_bump_dir,						// view_dir reflected about surface normal, in world space
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

	// sample specular map
	float4 specular_map_color= sample2D(specular_map, texcoord);
	float power_or_roughness= specular_map_color.a * specular_power * dot(specular_map_color.rgb, specular_map_color.rgb);	

	// calculate simple dynamic lights	
	float3 simple_lights_bump_diffuse= saturate(dot(light_dir, bump_normal)) * light_irradiance;
	float3 simple_lights_bump_specular= 0.0f;
	{		
		float l_dot_r = dot(light_dir, view_reflect_by_bump_dir); 
		if (l_dot_r > 0)
		{		
			simple_lights_bump_specular= pow(l_dot_r, power_or_roughness) * light_irradiance;
		}
		else
		{
			simple_lights_bump_specular= 0.0f;
		}
		simple_lights_bump_specular*= power_or_roughness * 0.33f; // lower power magic
	}

	// calculate diffuse color
	float3 diffuse_color= 
			simple_lights_bump_diffuse * diffuse_coefficient * diffuse_tint;

	// calculate specular from analytic and area
	float3 specular_color=			
			simple_lights_bump_specular* analytical_specular_coefficient *
			specular_tint * specular_map_color.rgb;

	// begin the hack of skin	
	float2 occlusion_map_value= sample2D(occlusion_parameter_map, texcoord).xy;
	float ambient_occlusion= occlusion_map_value.x;
	float visibility_occlusion= occlusion_map_value.y;	

	// calculate subsurface
	float3 subsurface_color= 0.0f;
	FORCE_BRANCH
	if ( subsurface_coefficient > 0.01f)
	{
		float4 subsurface_map_color= sample2D(subsurface_map, texcoord);

		float3 subsurface_normal=
			normalize(			
				lerp(surface_normal, bump_normal, subsurface_normal_detail) +				
				light_dir*subsurface_propagation_bias*subsurface_map_color.w); 
		
		float3 simple_lights_subsurface_diffuse= saturate(dot(light_dir, subsurface_normal)) * light_irradiance;		

		subsurface_color= 
			simple_lights_subsurface_diffuse * 
			subsurface_tint *
			subsurface_coefficient * 			
			subsurface_map_color.rgb *
			ambient_occlusion;	
	}

	//do color output
	analytic_specular_radiance= 			
		specular_color+ 		
		subsurface_color +	
		diffuse_color * diffuse_albedo_color;

	analytic_specular_radiance*= final_tint;

	// bullshits
	material_parameters= 0.0f;
	specular_fresnel_color= 0.0f;
	specular_albedo_color= 0.0f;
}

#undef FORCE_BRANCH
#endif //_ORGANISM_MATERIAL_FX_
