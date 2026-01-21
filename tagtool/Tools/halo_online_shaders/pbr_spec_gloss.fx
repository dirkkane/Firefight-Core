#ifndef _PBR_SPEC_GLOSS_FX_
#define _PBR_SPEC_GLOSS_FX_

/*
pbr.fx
Sat, March 15, 2025 1:36pm (oli :D)
*/

#define PI 3.14159265358979323846264338327950

//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************

PARAM(bool, use_specular_tints);
PARAM(float, gloss_bias);
PARAM(float, gloss_multiplier);
PARAM(float4, specular_tint);
PARAM(float,  specular_bias);
PARAM(float, fresnel_curve_steepness);

PARAM(float3, normal_specular);			//reflectance at normal incidence
PARAM(float3, glancing_specular);
PARAM(float, albedo_blend);

//*****************************************************************************
// cook-torrance for area light source in SH space
//*****************************************************************************

float get_material_pbr_spec_gloss_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_pbr_spec_gloss_ps(float specular_mask)
{
	return specular_coefficient;
}

float3 get_diffuse_multiplier_pbr_spec_gloss_ps()
{
	return diffuse_coefficient;
}

float3 EnvBRDFApprox(in float3 SpecularColor, in float Roughness, in float NoV )
{
	const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
	float4 r = Roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
	return SpecularColor * AB.x + AB.y;
}

float3 FresnelSchlick(in float3 f0, in float3 f1, in float dot_prod)
{
	float power = use_specular_tints ? fresnel_curve_steepness : 5.0;
	return f0 + (f1 - f0) * pow(1 - dot_prod, power);
}

float3 FresnelSchlickRoughness(in float3 f0, in float rough, in float dot_prod)
{
	float gloss = 1 - rough;
	return f0 + (max(gloss, f0) - f0) * pow(1 - dot_prod, 5);
}

void calc_material_analytic_specular_pbr_spec_gloss_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vert_n_dot_l,
	in float3x3 surface_normal,
	in float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));

	//Should probably make different material models for each of these conditions to avoid dumb if statements

	material_parameters.xyz= clamp(material_parameters.xyz * specular_tint + specular_bias, 0.0, 1.0);
	material_parameters.w= 1 - clamp(material_parameters.w * gloss_multiplier + gloss_bias, 0.0, 0.999);

    float3 H    = normalize(light_dir + view_dir);
    float NdotL = clamp(dot(normal_dir, light_dir), 0.0001, 1.0);
	float NdotV = clamp(abs(dot(normal_dir, view_dir)), 0.0001, 1.0);
    float LdotH = clamp(dot(light_dir, H), 0.0001, 1.0);
	float VdotH = clamp(dot(view_dir, H), 0.0001, 1.0);
    float NdotH = clamp(dot(normal_dir, H), 0.0001, 1.0);
    float min_dot = min(NdotL, NdotV);

    float a2_sqrd   = pow(material_parameters.w, 4);

	float3 f0 = material_parameters.xyz == (float3)0.0 ? 0.04 : material_parameters.xyz;
	specular_albedo_color = f0;
	float3 f1 = use_specular_tints ? glancing_specular : 1;
	if(use_specular_tints)
	{
		f0 = lerp(normal_specular, material_parameters.xyz, albedo_blend);
	}
	float3 F = FresnelSchlick(f0, f1, VdotH);
	specular_albedo_color = f0;
	specular_fresnel_color = F;

    //Normal Distribution Function
    float NDFdenom = max((NdotH * a2_sqrd - NdotH) * NdotH + 1.0, 0.0001);
    float NDF = a2_sqrd / (PI * NDFdenom * NDFdenom);

    //Geometry
    float L = 2.0 * NdotL / (NdotL + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotL * NdotL)));
	float V = 2.0 * NdotV / (NdotV + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotV * NdotV)));
    float G = L * V;

    //Final GGX
    float3 numerator    = NDF * 
                          G * 
                          F;
    float3 denominator  = max(4.0 * NdotV * NdotL, 0.0001);
	
    analytic_specular_radiance = (NdotV != 0.0f) ? (numerator / denominator) * light_irradiance * NdotL : 0.00001f;
}

void calc_material_pbr_spec_gloss_ps(
	in float3 view_dir,
	in float3 fragment_to_camera_world,
	in float3 surface_normal,
	in float3 view_reflect_dir_world,
	in float4 sh_lighting_coefficients[10],
	in float3 analytical_light_dir,
	in float3 analytical_light_intensity,
	in float3 diffuse_reflectance,
	in float  specular_mask,
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

		float3 fresnel_analytical;			// fresnel_specular_albedo
		float3 effective_reflectance;		// specular_albedo (no fresnel)
		float4 per_pixel_parameters;
		float3 specular_analytical;			// specular radiance
		float4 spatially_varying_material_parameters;
		
		calc_material_analytic_specular_pbr_spec_gloss_ps(
			view_dir,
			surface_normal,
			view_reflect_dir_world,
			analytical_light_dir,
			analytical_light_intensity,
			diffuse_reflectance,
			texcoord,
			prt_ravi_diff.w,
			tangent_frame,
			float4(specular_mask,0,0,0),
			spatially_varying_material_parameters,
			fresnel_analytical,
			effective_reflectance,
			specular_analytical);

	
		float rough = spatially_varying_material_parameters.w;


	float3 area_specular;
	float3 NdotV = saturate(dot(surface_normal, view_dir));
	float3 f0 = effective_reflectance;
	float3 f1 = use_specular_tints ? glancing_specular : 1;
	float3 fRough;
	if (use_specular_tints)
	{
		fRough = FresnelSchlick(f0, f1, NdotV);
	}
	else
	{
		fRough = FresnelSchlickRoughness(f0, rough, NdotV);
	}

	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	if (!no_dynamic_lights)
	{
		calc_simple_lights_spec_gloss(
				fragment_position_world,
				surface_normal,
				view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
				view_dir,
				f0,
				f1,
				5,
				rough,
				diffuse_reflectance,
				simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
				simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}

	
	envmap_specular_reflectance_and_roughness= float4(EnvBRDFApprox(fRough, rough, NdotV) * diffuse_radiance, rough);
	envmap_area_specular_only = prt_ravi_diff.z * specular_coefficient;

	float metallic = max(max(f0.r, f0.g), f0.b);

	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light) * (1 - FresnelSchlickRoughness(metallic, rough, NdotV)) * prt_ravi_diff.x * diffuse_coefficient;
		
	specular_radiance.xyz= (simple_light_specular_light + specular_analytical) * prt_ravi_diff.z * specular_coefficient;//EnvBRDFApprox(fRough, rough, NdotV)
	
	specular_radiance.w= 0.0f;
}
	//Look into setting up the normal map here so you don't have Halo 3's weird Zbump bullshit.
#endif // _pbr_FX_
