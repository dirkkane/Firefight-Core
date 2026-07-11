#ifndef _PBR_FX_
#define _PBR_FX_


#define _DISABLE_DIFFUSE_IN_ENTRY_POINTS
#define _PASS_EXTRA_PARAMETERS
/*
pbr.fx
Sat, March 15, 2025 1:36pm (oli :D)
*/
#define PI 3.14159265358979323846264338327950f
#define _epsilon 0.00001f

//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************


PARAM(bool, convert_material);
PARAM(bool, convert_spec_rough);
PARAM(float, roughness_bias);
PARAM(float, roughness_multiplier);
PARAM(float, metallic_bias);
PARAM(float, metallic_multiplier);

#ifdef PBR_ADVANCED
PARAM(float3, normal_specular);			//reflectance at normal incidence
PARAM(float3, glancing_specular);

PARAM(bool, 	iridescent);
PARAM(bool, 	aniso);
PARAM(float, 	anisotropy);
PARAM(bool, 	clear_coat);
PARAM(float, 	cc_roughness);

PARAM_SAMPLER_2D(material_masks);
#endif 
//*****************************************************************************
// cook-torrance for area light source in SH space
//*****************************************************************************

float3 color_screen (float3 a, float3 b){
    float3 white = float3(1.0,1.0,1.0);
    return (white - (white-a)*(white-b));
}

float get_material_pbr_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_pbr_ps(float specular_mask)
{
	return 0.0f;
}

float3 get_diffuse_multiplier_pbr_ps()
{
	return 1.0f;
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

float3 oren_nayar(
	in float3 view_dir,
	in float3 view_normal,
	in float3 view_light_dir,
	in float3 light_color,
	in float3 fresnel,
	in float  roughness,
	in float3 albedo
)
{
	float3 dif;
	float a2 = roughness * roughness;

		//float NdotL = max(dot(view_normal, view_light_dir), 0.0001f);
	float3 H = normalize(view_light_dir + view_dir);
	float NdotH = saturate(dot(view_normal, H));
    float NdotL = max(dot(view_normal, view_light_dir), 0.0001f);
	float NdotV = saturate(dot(view_normal, view_dir));
	//float HdotV = saturate(dot(view_dir, H));
	float LdotV = saturate(dot(view_light_dir, view_dir));

	float facing = 0.5 + 0.5 * LdotV;
	float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + NdotH) / max(NdotH, _epsilon));
	float smooth = 1.05 * (1 - pow(1 - NdotL, 5)) * (1 - pow(1 - NdotV, 5));
	float single = lerp(smooth, rough, a2) / PI;
	float multi = 0.1159 * a2;
	float3 hammon_dif = albedo * saturate((single + albedo * multi)) * (1 - fresnel) * light_color * NdotL;
	return hammon_dif;
}

float3 oren_nayar_and_sh(
	in float3 view_dir,
	in float3 view_normal,
	in float3 view_light_dir,
	in float3 light_color,
	in float rough,
	in float ao,
	in float4 sh_lighting_coefficients[10],
	in float3 albedo,
	in float3x3 tangent_frame,
	in float3 fresnel)
{
	float3 ONdif = oren_nayar(view_dir, view_normal, view_light_dir, light_color, fresnel, rough, albedo);
	//Crackhead attempt at redoing spherical harmonics
	float3 dir_eval= float3(-0.4886025f * view_light_dir.y, -0.4886025f * view_light_dir.z, -0.4886025 * view_light_dir.x);
	float4 lighting_constants[4] = {
		sh_lighting_coefficients[0],
		sh_lighting_coefficients[1],
		sh_lighting_coefficients[2],
		sh_lighting_coefficients[3]};

	lighting_constants[1].xyz -= dir_eval.zxy * light_color.x;//Replace constants with "sh_lighting_coefficients" if tool throws a fit.
	lighting_constants[2].xyz -= dir_eval.zxy * light_color.y;
	lighting_constants[3].xyz -= dir_eval.zxy * light_color.z;
	lighting_constants[0].xyz -= 0.2820948f * light_color;
	
	float3 x1;	
	x1.r = dot( view_normal, lighting_constants[1].rgb);		// linear red
	x1.g = dot( view_normal, lighting_constants[2].rgb);		// linear green
	x1.b = dot( view_normal, lighting_constants[3].rgb);		// linear blue
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb + (-2.f * c2) * x1) / PI;
	return ONdif + lightprobe_color * ao * albedo;
}

void calc_material_analytic_specular_pbr_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	inout float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vert_n_dot_l,
	in float3 surface_normal,
	inout float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));

	//Should probably make different material models for each of these conditions to avoid dumb if statements
	if(!convert_material && !convert_spec_rough)
	{
		material_parameters.y= clamp(material_parameters.y * roughness_multiplier + roughness_bias, 0.005, 1.0);
		material_parameters.z= saturate(material_parameters.z * metallic_multiplier + metallic_bias);
	}
	else
	{
		if(convert_spec_rough)
		{
			material_parameters.xyz = float3(1, 
											 clamp(material_parameters.y * roughness_multiplier + roughness_bias, 0.005, 1.0), 
											 saturate(material_parameters.x * metallic_multiplier + metallic_bias));
		}
		else
		{
			material_parameters.x = 1;
			material_parameters.y = clamp((1 - misc.x) * roughness_multiplier + roughness_bias, 0.005, 1.0);
			material_parameters.z = saturate(misc.x * metallic_multiplier + metallic_bias);
		}
	}

	float3 T, B;
	orthonormal_basis(normal_dir, T, B);

    float3 H    = normalize(light_dir + view_dir);
    float NdotL = max(dot(normal_dir, light_dir), _epsilon);
	float NdotV = max(dot(normal_dir, view_dir), _epsilon);
    float LdotH = max(dot(light_dir, H), _epsilon);
	float VdotH = max(dot(view_dir, H), _epsilon);
    float NdotH = max(dot(normal_dir, H), _epsilon);
    float min_dot = min(NdotL, NdotV);
	float a2 = material_parameters.y * material_parameters.y;

	specular_albedo_color = lerp((float3)0.04f, diffuse_albedo_color, material_parameters.z);
	specular_albedo_color = min(specular_albedo_color, 0.999);
	
#ifdef PBR_ADVANCED
	//R = coat roughness, G = coat mask, B = anisotropy, A = anisotropy mask
	misc = saturate(sample2D(material_masks, transform_texcoord(texcoord, material_texture_xform)));

	material_parameters.w = material_parameters.w * iridescent;
	misc.w *= aniso;
	misc.y *= clear_coat;
	if(material_parameters.w > 0.0f)
	{
		specular_albedo_color *= lerp(1, normal_specular, material_parameters.w * material_parameters.z);
		specular_albedo_color = lerp(specular_albedo_color, pow(1 - 5 * sqrt(specular_albedo_color), 2) / pow(5 - sqrt(specular_albedo_color), 2), misc.z);
		float3 a_lasagne = 17.6513846 * (specular_albedo_color - glancing_specular) + 8.16666667 * (1 - specular_albedo_color);
		float3 schlick = FresnelSchlick(specular_albedo_color, VdotH);
    	float3 lasagne = saturate(schlick - a_lasagne * VdotH * pow(1 - VdotH, 6));
		specular_fresnel_color= lerp(schlick, lasagne, material_parameters.w);
	}
	else
	{
		specular_albedo_color = lerp(specular_albedo_color, pow(1 - 5 * sqrt(specular_albedo_color), 2) / pow(5 - sqrt(specular_albedo_color), 2), misc.z);
		specular_fresnel_color = FresnelSchlick(specular_albedo_color, VdotH);
	}

    //Normal Distribution Function

	misc.z = clamp((misc.z * 2.0 - 1.0) * anisotropy, -1.0, 1.0);
	float aniso_ = misc.z * misc.w;
	float at = max(a2 * (1 - aniso_), _epsilon);
	float ab = max(a2 * (1 + aniso_), _epsilon);

	float aniso_ndf = ndf_aniso_ggx(NdotH, view_dir, H, T, B, at, ab);

	float G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, at, ab);

	analytic_specular_radiance = aniso_ndf * specular_fresnel_color * G;
                	
    	//denominator  = hammon_visibility;//max(4.0 * NdotV * NdotL, 0.0001);
	if(misc.y > 0)
	{
		misc.x = saturate(misc.x * cc_roughness);
		float coat_rough = misc.x * misc.x;
		float cc_NDF = ndf_aniso_ggx(NdotH, view_dir, H, T, B, coat_rough, coat_rough);
		float cc_G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, coat_rough, coat_rough);

		float3 cc_F = FresnelSchlick(0.04f, VdotH);
		float3 cc_spec = cc_NDF * cc_F * cc_G;
		analytic_specular_radiance *= pow(1 - cc_F * misc.y, 2);
		analytic_specular_radiance += cc_spec * misc.y;
		specular_fresnel_color = cc_F * misc.y;
	}
	else
	{
		specular_fresnel_color = 0.0f;
	}
#else
		specular_fresnel_color = FresnelSchlick(specular_albedo_color, VdotH);
		specular_albedo_color = specular_albedo_color;

		float NDF = ndf_aniso_ggx(NdotH, view_dir, H, T, B, a2, a2);
		//Hammon's Smith Approximation from Titanfall 2 (replalces denominator)
		float G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, a2, a2);
		//Final GGX
		analytic_specular_radiance = NDF * specular_fresnel_color * G;

		specular_fresnel_color = 0.0f;

#endif
    analytic_specular_radiance = (NdotV != 0.0f) ? analytic_specular_radiance * light_irradiance * NdotL : 0.00001f;

}

PARAM(float, roughness);
PARAM(float3, specular_tint);

float specular_power_from_roughness(in float rough)
{
#if DX_VERSION == 11
	if (rough == 0)
	{
		return 0;
	}
#endif	

	return 0.27291 * pow(rough, -2.1973);
}

void calc_material_pbr_ps(
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
	inout float4 misc,
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
	float4 material_parameters;
	misc = float4(specular_mask,0,0,0);
	float3 albedo = diffuse_reflectance;
	calc_material_analytic_specular_pbr_ps(
		view_dir,
		surface_normal,
		view_reflect_dir_world,
		analytical_light_dir,
		analytical_light_intensity,
		albedo,
		texcoord,
		prt_ravi_diff.w,
		tangent_frame[2],
		misc,
		material_parameters,
		fresnel_analytical,
		effective_reflectance,
		specular_analytical);

	float NdotV = saturate(dot(surface_normal, view_dir));

#ifdef PBR_ADVANCED
	float3 f1 = 17.6513846 * (effective_reflectance - glancing_specular) + 8.16666667 * (1 - effective_reflectance);
#endif

	//f1 = use_specular_tints ? glancing_specular : 1;
	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	if (!no_dynamic_lights)
	{
#ifdef PBR_ADVANCED
		calc_simple_lights_pbr_advanced(
				fragment_position_world,
				surface_normal,
				view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
				view_dir,
				effective_reflectance,
				f1,
				float2(material_parameters.y, material_parameters.w),
				misc,
				albedo,
				simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
				simple_light_specular_light);
#else
		calc_simple_lights_pbr(
				fragment_position_world,
				surface_normal,
				view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
				view_dir,
				effective_reflectance,
				material_parameters.y,
				albedo,
				simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
				simple_light_specular_light);
#endif 
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}
	
	diffuse_radiance = oren_nayar_and_sh(
							view_dir,
							surface_normal,
							analytical_light_dir,
							analytical_light_intensity,
							material_parameters.y,
							material_parameters.x,
							sh_lighting_coefficients,
							albedo,
							tangent_frame,
							fresnel_analytical);

//calculate the area sh
	float3 fresnel;
	float3 fresnel_coat;
	
	float3 cubemap_sh;
	calculate_area_specular_new_phong_3(
		view_reflect_dir_world,
		sh_lighting_coefficients,
		1.0, //Roughness of 1 stops a dark patch appearing
		1,
		cubemap_sh);
	cubemap_sh *= material_parameters.x;

#ifdef PBR_ADVANCED
	fresnel = FresnelSchlickRoughness(effective_reflectance, material_parameters.y, NdotV);
	fresnel = saturate(fresnel - (f1 * NdotV * pow(1 - NdotV, 6)) * material_parameters.w);
	fresnel = EnvBRDFApprox(fresnel, material_parameters.y, NdotV);

	fresnel_coat = EnvBRDFApprox(FresnelSchlickRoughness(0.04f, misc.x, NdotV), misc.x, NdotV);
	fresnel *= (1 - fresnel_coat * misc.y);

	fresnel *= cubemap_sh;
	fresnel_coat *= cubemap_sh;
#else
	fresnel = FresnelSchlickRoughness(effective_reflectance, material_parameters.y, NdotV);
	fresnel = EnvBRDFApprox(fresnel, material_parameters.y, NdotV) * cubemap_sh;
	fresnel_coat = 0.0f;
#endif

	envmap_specular_reflectance_and_roughness=  float4(fresnel, material_parameters.y);
	envmap_area_specular_only = fresnel_coat * misc.y;
	
	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light) * (1 - material_parameters.z);
		
	specular_radiance.xyz= (simple_light_specular_light + specular_analytical);
	
	specular_radiance.w= 0.0f;
}

void calc_material_analytic_specular_pbr_advanced_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	inout float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vert_n_dot_l,
	in float3 surface_normal,
	inout float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	calc_material_analytic_specular_pbr_ps(
		view_dir,
		normal_dir,									
		view_reflect_dir,
		light_dir,
		light_irradiance,
		diffuse_albedo_color,
		texcoord,
		vert_n_dot_l,
		surface_normal,
		misc,
		material_parameters,
		specular_fresnel_color,
		specular_albedo_color,
		analytic_specular_radiance);
}

void calc_material_pbr_advanced_ps(
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
	inout float4 misc,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_radiance,
	inout float3 diffuse_radiance)
{
	calc_material_pbr_ps(
		view_dir,
		fragment_to_camera_world,
		surface_normal,
		view_reflect_dir_world,
		sh_lighting_coefficients,
		analytical_light_dir,
		analytical_light_intensity,
		diffuse_reflectance,
		specular_mask,
		texcoord,
		prt_ravi_diff,
		tangent_frame, // = {tangent, binormal, normal};
		misc,
		envmap_specular_reflectance_and_roughness,
		envmap_area_specular_only,
		specular_radiance,
		diffuse_radiance);
}
#endif // _pbr_FX_
