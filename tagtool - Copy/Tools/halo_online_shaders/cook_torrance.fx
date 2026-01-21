#ifndef _COOK_TORRANCE_FX_
#define _COOK_TORRANCE_FX_

/*
cook_torrance.fx
Mon, Jul 25, 2005 5:01pm (haochen)
*/

//****************************************************************************
// Cook Torrance Material Model parameters
//****************************************************************************

PARAM(float3,	fresnel_color);				//reflectance at normal incidence
PARAM(float,	fresnel_power);

PARAM(float,	roughness);					//roughness
PARAM(float,	albedo_blend);				//how much to blend in the albedo color to fresnel f0
PARAM(float3,	specular_tint);

PARAM(bool,		albedo_blend_with_specular_tint);
PARAM(bool,		use_fresnel_color_environment);
PARAM(float3,	fresnel_color_environment);
PARAM(float,	rim_fresnel_coefficient);
PARAM(float3,	rim_fresnel_color);
PARAM(float,	rim_fresnel_power);
PARAM(float,	rim_fresnel_albedo_blend);

PARAM(float,	analytical_anti_shadow_control);

PARAM_SAMPLER_2D(g_sampler_cc0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_dd0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_c78d78);					//pre-integrated texture

#define A0_88			0.886226925f
#define A2_10			1.023326708f
#define A6_49			0.495415912f


float get_material_cook_torrance_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float get_material_cook_torrance_specular_power_scale(float power_or_roughness)
{
}

float3 get_analytical_specular_multiplier_cook_torrance_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_diffuse_multiplier_cook_torrance_ps()
{
	return diffuse_coefficient;
}

float get_material_cook_torrance_custom_cube_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float get_material_cook_torrance_scrolling_cube_mask_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float get_material_cook_torrance_scrolling_cube_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float get_material_cook_torrance_from_albedo_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float get_material_cook_torrance_rim_fresnel_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}

}

float get_material_cook_torrance_two_color_spec_tint_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float3 get_diffuse_multiplier_cook_torrance_two_color_spec_tint_ps()
{
	return diffuse_coefficient;
}

float3 get_analytical_specular_multiplier_cook_torrance_two_color_spec_tint_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float get_material_cook_torrance_custom_cube_specular_power_scale(float power_or_roughness)
{
}

float3 get_analytical_specular_multiplier_cook_torrance_custom_cube_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_analytical_specular_multiplier_cook_torrance_scrolling_cube_mask_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_analytical_specular_multiplier_cook_torrance_scrolling_cube_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_analytical_specular_multiplier_cook_torrance_from_albedo_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_analytical_specular_multiplier_cook_torrance_rim_fresnel_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

float3 get_diffuse_multiplier_cook_torrance_custom_cube_ps()
{
	return diffuse_coefficient;
}

float3 get_diffuse_multiplier_cook_torrance_scrolling_cube_mask_ps()
{
	return diffuse_coefficient;
}

float3 get_diffuse_multiplier_cook_torrance_scrolling_cube_ps()
{
	return diffuse_coefficient;
}

float3 get_diffuse_multiplier_cook_torrance_from_albedo_ps()
{
	return diffuse_coefficient;
}

float3 get_diffuse_multiplier_cook_torrance_rim_fresnel_ps()
{
	return diffuse_coefficient;
}
float get_material_cook_torrance_pbr_maps_specular_power(float power_or_roughness)
{
	//[branch]
	//if (roughness == 0)
	//{
	//	return 0;
	//}
	//else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float3 get_diffuse_multiplier_cook_torrance_pbr_maps_ps()
{
	return diffuse_coefficient;
}

float3 get_analytical_specular_multiplier_cook_torrance_pbr_maps_ps(float3 specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}

//*****************************************************************************
// Analytical Cook-Torrance for point light source only
//*****************************************************************************

void calc_material_analytic_specular_cook_torrance_ps(
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
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters= float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{	
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters= sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));				
	}

	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1-spatially_varying_material_parameters.g);

	float n_dot_l = dot( normal_dir, light_dir );
	float n_dot_v = dot( normal_dir, view_dir );
	float min_dot = min( n_dot_l, n_dot_v );
	
	if ( min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize( view_dir + light_dir );
		float n_dot_h = dot( normal_dir, half_vector );
		float v_dot_h = dot( view_dir, half_vector); 
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float  geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0= min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt( f0 );
		float3 n = ( 1.f + sqrt_f0 ) / ( 1.0 - sqrt_f0 );
		float3 g = sqrt( n*n + v_dot_h*v_dot_h - 1.f );
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h*gpc-1.f) / (v_dot_h*gmc+1.f);
		specular_fresnel_color= ( 0.5f * ( (gmc*gmc) / (gpc*gpc + 0.00001f) ) * ( 1.f + r*r ));
		
		//calculate the distribution term
		float t_roughness= max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared= t_roughness*t_roughness;			
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution= exp((cosine_alpha_squared-1)/(m_squared*cosine_alpha_squared))/(m_squared*cosine_alpha_squared*cosine_alpha_squared+0.00001f);
		
		//puting it all together
		analytic_specular_radiance= distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance= min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance= 0.00001f;
		specular_fresnel_color= specular_albedo_color;
	}
}

//*****************************************************************************
// Analytical Cook-Torrance for point light source only
//*****************************************************************************

void calc_material_analytic_specular_cook_torrance_two_color_spec_tint_ps(
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
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters= float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{	
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters= sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));				
	}

	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1-spatially_varying_material_parameters.g);

	float n_dot_l = dot( normal_dir, light_dir );
	float n_dot_v = dot( normal_dir, view_dir );
	float min_dot = min( n_dot_l, n_dot_v );
	
	if ( min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize( view_dir + light_dir );
		float n_dot_h = dot( normal_dir, half_vector );
		float v_dot_h = dot( view_dir, half_vector); 
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float  geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0= min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt( f0 );
		float3 n = ( 1.f + sqrt_f0 ) / ( 1.0 - sqrt_f0 );
		float3 g = sqrt( n*n + v_dot_h*v_dot_h - 1.f );
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h*gpc-1.f) / (v_dot_h*gmc+1.f);
		specular_fresnel_color= ( 0.5f * ( (gmc*gmc) / (gpc*gpc + 0.00001f) ) * ( 1.f + r*r ));
		
		//calculate the distribution term
		float t_roughness= max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared= t_roughness*t_roughness;			
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution= exp((cosine_alpha_squared-1)/(m_squared*cosine_alpha_squared))/(m_squared*cosine_alpha_squared*cosine_alpha_squared+0.00001f);
		
		//puting it all together
		analytic_specular_radiance= distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance= min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance= 0.00001f;
		specular_fresnel_color= specular_albedo_color;
	}
}

void calc_material_analytic_specular_cook_torrance_pbr_maps_ps(
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
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: roughless
	spatially_varying_material_parameters= sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)).xxyy;
	spatially_varying_material_parameters.y = albedo_blend;
	spatially_varying_material_parameters.z = environment_map_specular_contribution;

	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1-spatially_varying_material_parameters.g);

	float n_dot_l = dot( normal_dir, light_dir );
	float n_dot_v = dot( normal_dir, view_dir );
	float min_dot = min( n_dot_l, n_dot_v );
	
	if ( min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize( view_dir + light_dir );
		float n_dot_h = dot( normal_dir, half_vector );
		float v_dot_h = dot( view_dir, half_vector); 
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float  geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0= min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt( f0 );
		float3 n = ( 1.f + sqrt_f0 ) / ( 1.0 - sqrt_f0 );
		float3 g = sqrt( n*n + v_dot_h*v_dot_h - 1.f );
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h*gpc-1.f) / (v_dot_h*gmc+1.f);
		specular_fresnel_color= ( 0.5f * ( (gmc*gmc) / (gpc*gpc + 0.00001f) ) * ( 1.f + r*r ));
		
		//calculate the distribution term
		float t_roughness= max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared= t_roughness*t_roughness;			
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution= exp((cosine_alpha_squared-1)/(m_squared*cosine_alpha_squared))/(m_squared*cosine_alpha_squared*cosine_alpha_squared+0.00001f);
		
		//puting it all together
		analytic_specular_radiance= distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance= min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance= 0.00001f;
		specular_fresnel_color= specular_albedo_color;
	}
}

void calc_material_analytic_specular_cook_torrance_custom_cube_ps(
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
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters= float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{	
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters= sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));				
	}

	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1-spatially_varying_material_parameters.g);

	float n_dot_l = dot( normal_dir, light_dir );
	float n_dot_v = dot( normal_dir, view_dir );
	float min_dot = min( n_dot_l, n_dot_v );
	
	if ( min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize( view_dir + light_dir );
		float n_dot_h = dot( normal_dir, half_vector );
		float v_dot_h = dot( view_dir, half_vector); 
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float  geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0= min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt( f0 );
		float3 n = ( 1.f + sqrt_f0 ) / ( 1.0 - sqrt_f0 );
		float3 g = sqrt( n*n + v_dot_h*v_dot_h - 1.f );
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h*gpc-1.f) / (v_dot_h*gmc+1.f);
		specular_fresnel_color= ( 0.5f * ( (gmc*gmc) / (gpc*gpc + 0.00001f) ) * ( 1.f + r*r ));
		
		//calculate the distribution term
		float t_roughness= max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared= t_roughness*t_roughness;			
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution= exp((cosine_alpha_squared-1)/(m_squared*cosine_alpha_squared))/(m_squared*cosine_alpha_squared*cosine_alpha_squared+0.00001f);
		
		//puting it all together
		analytic_specular_radiance= distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance= min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance= 0.00001f;
		specular_fresnel_color= specular_albedo_color;
	}
}

void calc_material_analytic_specular_cook_torrance_scrolling_cube_mask_ps(
	in float3 view_dir, // fragment to camera, in world space
	in float3 normal_dir, // bumped fragment surface normal, in world space
	in float3 view_reflect_dir, // view_dir reflected about surface normal, in world space
	in float3 light_dir, // fragment to light, in world space
	in float3 light_irradiance, // light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color, // diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l, // original normal dot lighting direction (used for specular masking on far side of object)
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color, // fresnel(specular_albedo_color)
	out float3 specular_albedo_color, // specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters = float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters = sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));
	}

	specular_albedo_color = diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1 - spatially_varying_material_parameters.g);

	float n_dot_l = dot(normal_dir, light_dir);
	float n_dot_v = dot(normal_dir, view_dir);
	float min_dot = min(n_dot_l, n_dot_v);
	
	if (min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize(view_dir + light_dir);
		float n_dot_h = dot(normal_dir, half_vector);
		float v_dot_h = dot(view_dir, half_vector);
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0 = min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt(f0);
		float3 n = (1.f + sqrt_f0) / (1.0 - sqrt_f0);
		float3 g = sqrt(n * n + v_dot_h * v_dot_h - 1.f);
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h * gpc - 1.f) / (v_dot_h * gmc + 1.f);
		specular_fresnel_color = (0.5f * ((gmc * gmc) / (gpc * gpc + 0.00001f)) * (1.f + r * r));
		
		//calculate the distribution term
		float t_roughness = max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared = t_roughness * t_roughness;
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution = exp((cosine_alpha_squared - 1) / (m_squared * cosine_alpha_squared)) / (m_squared * cosine_alpha_squared * cosine_alpha_squared + 0.00001f);
		
		//puting it all together
		analytic_specular_radiance = distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance = min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance = 0.00001f;
		specular_fresnel_color = specular_albedo_color;
	}
}

void calc_material_analytic_specular_cook_torrance_scrolling_cube_ps(
	in float3 view_dir, // fragment to camera, in world space
	in float3 normal_dir, // bumped fragment surface normal, in world space
	in float3 view_reflect_dir, // view_dir reflected about surface normal, in world space
	in float3 light_dir, // fragment to light, in world space
	in float3 light_irradiance, // light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color, // diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l, // original normal dot lighting direction (used for specular masking on far side of object)
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color, // fresnel(specular_albedo_color)
	out float3 specular_albedo_color, // specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters = float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters = sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));
	}

	specular_albedo_color = diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1 - spatially_varying_material_parameters.g);

	float n_dot_l = dot(normal_dir, light_dir);
	float n_dot_v = dot(normal_dir, view_dir);
	float min_dot = min(n_dot_l, n_dot_v);
	
	if (min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize(view_dir + light_dir);
		float n_dot_h = dot(normal_dir, half_vector);
		float v_dot_h = dot(view_dir, half_vector);
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0 = min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt(f0);
		float3 n = (1.f + sqrt_f0) / (1.0 - sqrt_f0);
		float3 g = sqrt(n * n + v_dot_h * v_dot_h - 1.f);
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h * gpc - 1.f) / (v_dot_h * gmc + 1.f);
		specular_fresnel_color = (0.5f * ((gmc * gmc) / (gpc * gpc + 0.00001f)) * (1.f + r * r));
		
		//calculate the distribution term
		float t_roughness = max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared = t_roughness * t_roughness;
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution = exp((cosine_alpha_squared - 1) / (m_squared * cosine_alpha_squared)) / (m_squared * cosine_alpha_squared * cosine_alpha_squared + 0.00001f);
		
		//puting it all together
		analytic_specular_radiance = distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance = min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance = 0.00001f;
		specular_fresnel_color = specular_albedo_color;
	}
}

void calc_material_analytic_specular_cook_torrance_from_albedo_ps(
	in float3 view_dir, // fragment to camera, in world space
	in float3 normal_dir, // bumped fragment surface normal, in world space
	in float3 view_reflect_dir, // view_dir reflected about surface normal, in world space
	in float3 light_dir, // fragment to light, in world space
	in float3 light_irradiance, // light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color, // diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l, // original normal dot lighting direction (used for specular masking on far side of object)
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color, // fresnel(specular_albedo_color)
	out float3 specular_albedo_color, // specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters = float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters = sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));
	}

	specular_albedo_color = diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1 - spatially_varying_material_parameters.g);

	float n_dot_l = dot(normal_dir, light_dir);
	float n_dot_v = dot(normal_dir, view_dir);
	float min_dot = min(n_dot_l, n_dot_v);
	
	if (min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize(view_dir + light_dir);
		float n_dot_h = dot(normal_dir, half_vector);
		float v_dot_h = dot(view_dir, half_vector);
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0 = min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt(f0);
		float3 n = (1.f + sqrt_f0) / (1.0 - sqrt_f0);
		float3 g = sqrt(n * n + v_dot_h * v_dot_h - 1.f);
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h * gpc - 1.f) / (v_dot_h * gmc + 1.f);
		specular_fresnel_color = (0.5f * ((gmc * gmc) / (gpc * gpc + 0.00001f)) * (1.f + r * r));
		
		//calculate the distribution term
		float t_roughness = max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared = t_roughness * t_roughness;
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution = exp((cosine_alpha_squared - 1) / (m_squared * cosine_alpha_squared)) / (m_squared * cosine_alpha_squared * cosine_alpha_squared + 0.00001f);
		
		//puting it all together
		analytic_specular_radiance = distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance = min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance = 0.00001f;
		specular_fresnel_color = specular_albedo_color;
	}
}

void calc_material_analytic_specular_cook_torrance_rim_fresnel_ps(
	in float3 view_dir, // fragment to camera, in world space
	in float3 normal_dir, // bumped fragment surface normal, in world space
	in float3 view_reflect_dir, // view_dir reflected about surface normal, in world space
	in float3 light_dir, // fragment to light, in world space
	in float3 light_irradiance, // light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color, // diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l, // original normal dot lighting direction (used for specular masking on far side of object)
	in float3x3 tangent_frame,
	in float4 misc,
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color, // fresnel(specular_albedo_color)
	out float3 specular_albedo_color, // specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	float3 surface_normal= tangent_frame[2];

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	spatially_varying_material_parameters= float4(specular_coefficient, albedo_blend, environment_map_specular_contribution, roughness);
	if (use_material_texture)
	{	
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters *= sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));
	}

	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1-spatially_varying_material_parameters.g);
	if (albedo_blend_with_specular_tint) {
		specular_albedo_color = fresnel_color;
	}

	float n_dot_l = dot( normal_dir, light_dir );
	float n_dot_v = dot( normal_dir, view_dir );
	float min_dot = min( n_dot_l, n_dot_v );
	
	if ( min_dot > 0)
	{
		// compute geometric attenuation
		float3 half_vector = normalize( view_dir + light_dir );
		float n_dot_h = dot( normal_dir, half_vector );
		float v_dot_h = dot( view_dir, half_vector); 
		
		// VH may be negative by numerical errors, so we need saturate(VH)
		float  geometry_term = 2 * n_dot_h * min_dot / (saturate(v_dot_h) + 0.00001f); // G = saturate(G)
		
		//calculate fresnel term
		float3 f0= min(specular_albedo_color, 0.999f);
		float3 sqrt_f0 = sqrt( f0 );
		float3 n = ( 1.f + sqrt_f0 ) / ( 1.0 - sqrt_f0 );
		float3 g = sqrt( n*n + v_dot_h*v_dot_h - 1.f );
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h*gpc-1.f) / (v_dot_h*gmc+1.f);
		specular_fresnel_color= ( 0.5f * ( (gmc*gmc) / (gpc*gpc + 0.00001f) ) * ( 1.f + r*r ));
		
		//calculate the distribution term
		float t_roughness= max(spatially_varying_material_parameters.a, 0.05f);
		float m_squared= t_roughness*t_roughness;			
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution= exp((cosine_alpha_squared-1)/(m_squared*cosine_alpha_squared))/(m_squared*cosine_alpha_squared*cosine_alpha_squared+0.00001f);
		
		//puting it all together
		analytic_specular_radiance= distribution * saturate(geometry_term) / (3.14159265 * n_dot_v + 0.00001f) * specular_fresnel_color;
		analytic_specular_radiance= min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance= 0.00001f;
		specular_fresnel_color= specular_albedo_color;
	}
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
	float3 result= float3(
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
	float3 rotate_x= normalize(view_dir - dot(view_dir, rotate_z) * rotate_z);		// view vector projected onto tangent plane
	float3 rotate_y= cross(rotate_z, rotate_x);										// third one, 90 degrees  :)
	
	//local view
	float t_roughness = max(roughness, 0.05f);
	float2 view_lookup = float2(pow(dot(view_dir, rotate_x), power) + c_view_z_shift, t_roughness + c_roughness_shift);
	
	// bases: 0,2,3,6
	float4 c_value= sample2D( g_sampler_cc0236, view_lookup ).SWIZZLE;
	float4 d_value= sample2D( g_sampler_dd0236, view_lookup ).SWIZZLE;
	
	float4 quadratic_a, quadratic_b, sh_local;
				
	quadratic_a.xyz= rotate_z.yzx * rotate_z.xyz * (-SQRT3);
	quadratic_b= float4(rotate_z.xyz * rotate_z.xyz, 1.0f/3.0f) * 0.5f * (-SQRT3);
	
	sh_local.xyz= sh_rotate_023(
		0,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
	sh_local.w= 0.0f;

	//c0236 dot L0236
	sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
	specular_part.r= dot( c_value, sh_local ); 
	schlick_part.r= dot( d_value, sh_local );

	sh_local.xyz= sh_rotate_023(
		1,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
	sh_local.w= 0.0f;	
	
	sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
	specular_part.g= dot( c_value, sh_local );
	schlick_part.g= dot( d_value, sh_local );

	sh_local.xyz= sh_rotate_023(
		2,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
	sh_local.w= 0.0f;

	sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
	specular_part.b= dot( c_value, sh_local );
	schlick_part.b= dot( d_value, sh_local );
	schlick_part= schlick_part * 0.01f;
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
	float3 rotate_x= normalize(view_dir - dot(view_dir, rotate_z) * rotate_z);		// view vector projected onto tangent plane
	float3 rotate_y= cross(rotate_z, rotate_x);										// third one, 90 degrees  :)
	
	//local view
	float t_roughness = max(roughness, 0.05f);
	float2 view_lookup = float2(pow(dot(view_dir, rotate_x), power) + c_view_z_shift, t_roughness + c_roughness_shift);
	
	// bases: 0,2,3,6
	float4 c_value= sample2D( g_sampler_cc0236, view_lookup ).SWIZZLE;
	float4 d_value= sample2D( g_sampler_dd0236, view_lookup ).SWIZZLE;
	
	float4 quadratic_a, quadratic_b, sh_local;
				
	quadratic_a.xyz= rotate_z.yzx * rotate_z.xyz * (-SQRT3);
	quadratic_b= float4(rotate_z.xyz * rotate_z.xyz, 1.0f/3.0f) * 0.5f * (-SQRT3);
	
	sh_local.xyz= sh_rotate_023(
		0,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
	sh_local.w= dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyzw, sh_8866[0].xyzw);

	//c0236 dot L0236
	sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
	specular_part.r= dot( c_value, sh_local ); 
	schlick_part.r= dot( d_value, sh_local );

	sh_local.xyz= sh_rotate_023(
		1,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);
	sh_local.w= dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyzw, sh_8866[1].xyzw);
				
	sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
	specular_part.g= dot( c_value, sh_local );
	schlick_part.g= dot( d_value, sh_local );

	sh_local.xyz= sh_rotate_023(
		2,
		rotate_x,
		rotate_z,
		sh_0,
		sh_312);	
		
	sh_local.w= dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyzw, sh_8866[2].xyzw);
		
	sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
	specular_part.b= dot( c_value, sh_local );
	schlick_part.b= dot( d_value, sh_local );

	// basis - 7
	c_value= sample2D( g_sampler_c78d78, view_lookup ).SWIZZLE;
	quadratic_a.xyz = rotate_x.xyz * rotate_z.yzx + rotate_x.yzx * rotate_z.xyz;
	quadratic_b.xyz = rotate_x.xyz * rotate_z.xyz;
	sh_local.rgb= float3(dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyz, sh_8866[0].xyz),
						 dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyz, sh_8866[1].xyz),
						 dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyz, sh_8866[2].xyz));
	
  
	sh_local*= r_dot_l;
	//c7 * L7
	specular_part.rgb+= c_value.x*sh_local.rgb;
	//d7 * L7
	schlick_part.rgb+= c_value.z*sh_local.rgb;
	
		//basis - 8
	quadratic_a.xyz = rotate_x.xyz * rotate_x.yzx - rotate_y.yzx * rotate_y.xyz;
	quadratic_b.xyz = 0.5f*(rotate_x.xyz * rotate_x.xyz - rotate_y.xyz * rotate_y.xyz);
	sh_local.rgb= float3(-dot(quadratic_a.xyz, sh_457[0].xyz) - dot(quadratic_b.xyz, sh_8866[0].xyz),
		-dot(quadratic_a.xyz, sh_457[1].xyz) - dot(quadratic_b.xyz, sh_8866[1].xyz),
		-dot(quadratic_a.xyz, sh_457[2].xyz) - dot(quadratic_b.xyz, sh_8866[2].xyz));
	sh_local*= r_dot_l;
	
	//c8 * L8
	specular_part.rgb+= c_value.y*sh_local.rgb;
	//d8 * L8
	schlick_part.rgb+= c_value.w*sh_local.rgb;
	
	schlick_part= schlick_part * 0.01f;
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
	
	
		float3 fresnel_analytical;			// fresnel_specular_albedo
		float3 effective_reflectance;		// specular_albedo (no fresnel)
		float4 per_pixel_parameters;
		float3 specular_analytical;			// specular radiance
		float4 spatially_varying_material_parameters;
		
		calc_material_analytic_specular_cook_torrance_ps(
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
			fresnel_analytical,
			effective_reflectance,
			specular_analytical);

		// apply anti-shadow
		if (analytical_anti_shadow_control > 0.0f)
		{
			float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			float ambientness= calculate_ambientness(
				temp,
				light_color,
				view_light_dir);
			float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
			specular_analytical *= ambient_multiplier;
		}
		
		float3 simple_light_diffuse_light; //= 0.0f;
		float3 simple_light_specular_light; //= 0.0f;
		
		if (!no_dynamic_lights)
		{
			float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
			calc_simple_lights_analytical(
				fragment_position_world,
				view_normal,
				view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
				GET_MATERIAL_SPECULAR_POWER(material_type)(spatially_varying_material_parameters.a),
				simple_light_diffuse_light,
				simple_light_specular_light);
		}
		else
		{
			simple_light_diffuse_light= 0.0f;
			simple_light_specular_light= 0.0f;
		}

		float3 sh_glossy= 0.0f;
		// calculate area specular
		float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;

		//calculate the area sh
		float3 specular_part=0.0f;
		float3 schlick_part=0.0f;
		
		if (order3_area_specular)
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
				spatially_varying_material_parameters.a,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
		else
		{
	
			float4 sh_0= sh_lighting_coefficients[0];
			float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			
			sh_glossy_ct_2(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				spatially_varying_material_parameters.a,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
						
		sh_glossy= specular_part * effective_reflectance + (1 - effective_reflectance) * schlick_part;
		envmap_specular_reflectance_and_roughness.w= spatially_varying_material_parameters.a;
		envmap_area_specular_only= sh_glossy * prt_ravi_diff.z * spec_tint;
				
		//scaling and masking
		
		specular_color.xyz= specular_mask * spatially_varying_material_parameters.r * spec_tint * (
			(simple_light_specular_light * effective_reflectance + specular_analytical) * analytical_specular_contribution +
			max(sh_glossy, 0.0f) * area_specular_contribution);
			
		specular_color.w= 0.0f;
		
		envmap_specular_reflectance_and_roughness.xyz=	spatially_varying_material_parameters.b * specular_mask * spatially_varying_material_parameters.r;		// ###ctchou $TODO this ain't right
				
		float diffuse_adjusted= diffuse_coefficient;
		if (use_material_texture)
		{
			diffuse_adjusted= 1.0f - spatially_varying_material_parameters.r;
		}
			
		diffuse_radiance= diffuse_radiance * prt_ravi_diff.x;
		diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_adjusted;
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

void calc_material_cook_torrance_custom_cube_ps(
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
	float3 custom_spec_tint = sampleCUBE(custom_cube, view_normal).xyz;

	calc_material_cook_torrance_base(view_dir, fragment_to_camera_world, view_normal, view_reflect_dir_world, sh_lighting_coefficients, view_light_dir, light_color, albedo_color, specular_mask, texcoord, prt_ravi_diff, tangent_frame, misc, custom_spec_tint, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, specular_color, diffuse_radiance);
}

PARAM_SAMPLER_CUBE(tint_blend_mask_cubemap);
PARAM(float3, specular_second_tint);

void calc_material_cook_torrance_scrolling_cube_mask_ps(
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
	float3 spec_blend = sampleCUBE(tint_blend_mask_cubemap, misc).xyz;
	float3 spec_tint = spec_blend.y * specular_tint * 2 + spec_blend.z * specular_second_tint * 2;

	calc_material_cook_torrance_base(view_dir, fragment_to_camera_world, view_normal, view_reflect_dir_world, sh_lighting_coefficients, view_light_dir, light_color, albedo_color, specular_mask, texcoord, prt_ravi_diff, tangent_frame, misc, spec_tint, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, specular_color, diffuse_radiance);
}

PARAM_SAMPLER_CUBE(spec_tint_cubemap);

void calc_material_cook_torrance_scrolling_cube_ps(
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
	float3 spec_tint = sampleCUBE(spec_tint_cubemap, misc).xyz;

	calc_material_cook_torrance_base(view_dir, fragment_to_camera_world, view_normal, view_reflect_dir_world, sh_lighting_coefficients, view_light_dir, light_color, albedo_color, specular_mask, texcoord, prt_ravi_diff, tangent_frame, misc, spec_tint, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, specular_color, diffuse_radiance);
}

void calc_material_cook_torrance_from_albedo_ps(
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
	float3 spec_tint = albedo_color;

	calc_material_cook_torrance_base(view_dir, fragment_to_camera_world, view_normal, view_reflect_dir_world, sh_lighting_coefficients, view_light_dir, light_color, albedo_color, specular_mask, texcoord, prt_ravi_diff, tangent_frame, misc, spec_tint, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, specular_color, diffuse_radiance);
}

void calc_material_cook_torrance_rim_fresnel_ps(
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

#ifdef pc
//	if (p_shader_pc_specular_enabled!=0.f)
#endif // pc
	{
	
	
		float3 fresnel_analytical;			// fresnel_specular_albedo
		float3 effective_reflectance;		// specular_albedo (no fresnel)
		float4 per_pixel_parameters;
		float3 specular_analytical;			// specular radiance
		float4 spatially_varying_material_parameters;
		
		calc_material_analytic_specular_cook_torrance_rim_fresnel_ps(
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
			fresnel_analytical,
			effective_reflectance,
			specular_analytical);

		// apply anti-shadow
		if (analytical_anti_shadow_control > 0.0f)
		{
			float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			float ambientness= calculate_ambientness(
				temp,
				light_color,
				view_light_dir);
			float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
			specular_analytical *= ambient_multiplier;
		}
		
		float3 simple_light_diffuse_light; //= 0.0f;
		float3 simple_light_specular_light; //= 0.0f;
		
		if (!no_dynamic_lights)
		{
			float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
			calc_simple_lights_analytical(
				fragment_position_world,
				view_normal,
				view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
				get_material_cook_torrance_rim_fresnel_specular_power(roughness),
				simple_light_diffuse_light,
				simple_light_specular_light);
		}
		else
		{
			simple_light_diffuse_light= 0.0f;
			simple_light_specular_light= 0.0f;
		}

		// calculate area specular
		float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;

		//calculate the area sh
		float3 specular_part=0.0f;
		float3 schlick_part=0.0f;

		float3 rim_specular_part=0.0f;
		float3 rim_schlick_part=0.0f;
		
		if (order3_area_specular)
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
				spatially_varying_material_parameters.a,
				r_dot_l,
				fresnel_power,
				specular_part,
				schlick_part);

		if (rim_fresnel_coefficient > 0.0f) {
			sh_glossy_ct_3(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				sh_457,
				sh_8866,	//NEW_LIGHTMAP: changing to linear
				spatially_varying_material_parameters.a,
				r_dot_l,
				rim_fresnel_power,
				rim_specular_part,
				rim_schlick_part);
		}
		}
		else
		{
	
			float4 sh_0= sh_lighting_coefficients[0];
			float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			
			sh_glossy_ct_2(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				spatially_varying_material_parameters.a,
				r_dot_l,
				fresnel_power,
				specular_part,
				schlick_part);

		if (rim_fresnel_coefficient > 0.0f) {
			sh_glossy_ct_2(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				spatially_varying_material_parameters.a,
				r_dot_l,
				rim_fresnel_power,
				rim_specular_part,
				rim_schlick_part);
		}
		}

		float3 sh_glossy= specular_part * effective_reflectance + (1 - effective_reflectance) * schlick_part;
		
		float3 sh_glossy_env = sh_glossy;
		if (use_fresnel_color_environment) {
			float3 specular_albedo_color_env = albedo_color * spatially_varying_material_parameters.g + fresnel_color_environment * (1-spatially_varying_material_parameters.g);
			if (albedo_blend_with_specular_tint) {
			specular_albedo_color_env = fresnel_color_environment;
			}
			sh_glossy_env = specular_part * specular_albedo_color_env + (1 - specular_albedo_color_env) * schlick_part;
		}

		float3 res_specular_tint = specular_tint;
		if (albedo_blend_with_specular_tint) {
			res_specular_tint = albedo_color * spatially_varying_material_parameters.g + specular_tint * (1-spatially_varying_material_parameters.g);
		}

		envmap_specular_reflectance_and_roughness.w= spatially_varying_material_parameters.a;
		envmap_area_specular_only= sh_glossy_env * prt_ravi_diff.z * res_specular_tint;

		//scaling and masking
		specular_color.xyz= specular_mask * spatially_varying_material_parameters.r * res_specular_tint * (
			(simple_light_specular_light * effective_reflectance + specular_analytical) * analytical_specular_contribution +
			max(sh_glossy, 0.0f) * area_specular_contribution);

		// rim fresnel
		specular_color.xyz += specular_mask * spatially_varying_material_parameters.r *
			rim_fresnel_coefficient * lerp(rim_fresnel_color, albedo_color, rim_fresnel_albedo_blend) * rim_schlick_part;
			
		specular_color.w= 0.0f;
			
		envmap_specular_reflectance_and_roughness.xyz=	spatially_varying_material_parameters.b * specular_mask * spatially_varying_material_parameters.r;		// ###ctchou $TODO this ain't right
				
		float diffuse_adjusted= diffuse_coefficient;
		//if (use_material_texture)
		//{
		//	diffuse_adjusted *= 1.0f - spatially_varying_material_parameters.r;
		//}
			
		diffuse_radiance= diffuse_radiance * prt_ravi_diff.x;
		diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_adjusted;
		specular_color*= prt_ravi_diff.z;		
		
		//diffuse_color= 0.0f;
		//specular_color= spatially_varying_material_parameters.r;
	}
#ifdef pc
//	else
//	{
//		envmap_specular_reflectance_and_roughness= float4(0.f, 0.f, 0.f, 0.f);
//		envmap_area_specular_only= float3(0.f, 0.f, 0.f);
//		specular_color= 0.0f;
//		diffuse_radiance= ravi_order_3(view_normal, sh_lighting_coefficients) * prt_ravi_diff.x;
//	}
#endif // pc
}

PARAM_SAMPLER_CUBE(spec_blend_map);

void calc_material_cook_torrance_two_color_spec_tint_ps(
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
	float3 spec_blend = sampleCUBE(spec_blend_map, view_normal).xyz;
	float3 spec_tint = spec_blend.y * specular_tint * 2 + spec_blend.z * specular_second_tint * 2;

	calc_material_cook_torrance_base(view_dir, fragment_to_camera_world, view_normal, view_reflect_dir_world, sh_lighting_coefficients, view_light_dir, light_color, albedo_color, specular_mask, texcoord, prt_ravi_diff, tangent_frame, misc, spec_tint, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, specular_color, diffuse_radiance);
}

PARAM_SAMPLER_2D(spec_tint_map);

void calc_material_cook_torrance_pbr_maps_ps(
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
	float3 spec_tint = sample2D(spec_tint_map, texcoord).xyz;

#ifdef pc
	if (p_shader_pc_specular_enabled!=0.f)
#endif // pc
	{
	
	
		float3 fresnel_analytical;			// fresnel_specular_albedo
		float3 effective_reflectance;		// specular_albedo (no fresnel)
		float4 per_pixel_parameters;
		float3 specular_analytical;			// specular radiance
		float4 spatially_varying_material_parameters;
		
		calc_material_analytic_specular_cook_torrance_pbr_maps_ps(
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
			fresnel_analytical,
			effective_reflectance,
			specular_analytical);

		// apply anti-shadow
		if (analytical_anti_shadow_control > 0.0f)
		{
			float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			float ambientness= calculate_ambientness(
				temp,
				light_color,
				view_light_dir);
			float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
			specular_analytical *= ambient_multiplier;
		}
		
		float3 simple_light_diffuse_light; //= 0.0f;
		float3 simple_light_specular_light; //= 0.0f;
		
		if (!no_dynamic_lights)
		{
			float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
			calc_simple_lights_analytical(
				fragment_position_world,
				view_normal,
				view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
				GET_MATERIAL_SPECULAR_POWER(material_type)(spatially_varying_material_parameters.a),
				simple_light_diffuse_light,
				simple_light_specular_light);
		}
		else
		{
			simple_light_diffuse_light= 0.0f;
			simple_light_specular_light= 0.0f;
		}

		float3 sh_glossy= 0.0f;
		// calculate area specular
		float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;

		//calculate the area sh
		float3 specular_part=0.0f;
		float3 schlick_part=0.0f;
		
		if (order3_area_specular)
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
				spatially_varying_material_parameters.a,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
		else
		{
	
			float4 sh_0= sh_lighting_coefficients[0];
			float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			
			sh_glossy_ct_2(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				spatially_varying_material_parameters.a,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
						
		sh_glossy= specular_part * effective_reflectance + (1 - effective_reflectance) * schlick_part;
		envmap_specular_reflectance_and_roughness.w= spatially_varying_material_parameters.a;
		envmap_area_specular_only= sh_glossy * prt_ravi_diff.z * spec_tint;
				
		//scaling and masking
		
		specular_color.xyz= specular_mask * spatially_varying_material_parameters.r * spec_tint * (
			(simple_light_specular_light * effective_reflectance + specular_analytical) * analytical_specular_contribution +
			max(sh_glossy, 0.0f) * area_specular_contribution);
			
		specular_color.w= 0.0f;
		
		envmap_specular_reflectance_and_roughness.xyz=	spatially_varying_material_parameters.b * specular_mask * spatially_varying_material_parameters.r;		// ###ctchou $TODO this ain't right
				
		float diffuse_adjusted= diffuse_coefficient;
		if (use_material_texture)
		{
			diffuse_adjusted= 1.0f - spatially_varying_material_parameters.r;
		}
			
		diffuse_radiance= diffuse_radiance * prt_ravi_diff.x;
		diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_adjusted;
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

void calc_material_cook_torrance_ps(
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

void calc_material_model_cook_torrance_ps(
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
	diffuse_color= diffuse_in;
	specular_color= 0.0f;

	envmap_specular_reflectance_and_roughness.xyz=	environment_map_specular_contribution * specular_mask * specular_coefficient;
	envmap_specular_reflectance_and_roughness.w=	roughness;			// TODO: replace with whatever you use for roughness	

	envmap_area_specular_only= 1.0f;
}
#endif

#endif //ifndef _SH_GLOSSY_FX_
