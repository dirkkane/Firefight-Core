#ifndef _PBR_SPEC_GLOSS_FX_
#define _PBR_SPEC_GLOSS_FX_

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
PARAM(float4, 	mat_albedo_tint);
PARAM(bool, 	tag_colour_change);
PARAM(float3,	albedo_cc_col);
PARAM(float3,	specular_cc_col);
PARAM(float3,	albedo_cc_col_2);
PARAM(float3,	specular_cc_col_2);
//PARAM(bool, 	chameleon);
PARAM(float, 	gloss_bias);
PARAM(float, 	gloss_scale);
PARAM(float4, 	metalness);

#ifdef H2A_ADVANCED
PARAM(bool, 	enable_carpaint);
PARAM(float, 	paint_gloss_scale);
PARAM(float, 	paint_gloss_bias);
PARAM(float4,	paint_metalness);
PARAM(bool, 	enable_aniso);
PARAM(float,	anisotropy);
#endif

#ifdef H2A_ADVANCED_MASKED
PARAM(float4, 	mask_albedo_tint);
PARAM(float, 	mask_gloss_bias);
PARAM(float, 	mask_gloss_scale);
PARAM(float4, 	mask_metalness);
PARAM(bool, 	enable_mask_carpaint);
PARAM(float, 	mask_paint_gloss_bias);
PARAM(float,  	mask_paint_gloss_scale);
PARAM(float4,	mask_paint_metalness);
PARAM(bool, 	enable_mask_aniso);
PARAM(float,	mask_anisotropy);
#endif

/*PARAM(float4, 	mask_front_colour);
PARAM(float,  	mask_front_power);
PARAM(float4, 	mask_mid_colour);
PARAM(float, 	mask_mid_power);
PARAM(float4, 	mask_rim_colour);
PARAM(float, 	mask_rim_power);*/
//PARAM(bool,		mask_carpaint);
//PARAM(float, 	mask_paint_gloss_bias);
//PARAM(float,	mask_paint_gloss_scale);
//PARAM(float4,	mask_paint_metalness);*/
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

float3 color_screen (float3 a, float3 b){
    float3 white = float3(1.0,1.0,1.0);
    return (white - (white-a)*(white-b));
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

	float3 H = normalize(view_light_dir + view_dir);
	
    float NoL = max(dot(view_normal, view_light_dir), 0.0); 
	float NoH = max(dot(view_normal, H), 0.0); 
	float NoV = max(dot(view_normal, view_dir), 0.0);
	float LoV = max(dot(view_light_dir, view_dir), 0.0);

	float facing = 0.5 + 0.5 * LoV;
	float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + NoH) / max(NoH, _epsilon));
	float smooth = 1.05 * (1 - pow(1 - NoL, 5)) * (1 - pow(1 - NoV, 5));
	float single = (1 / PI) * lerp(smooth, rough, roughness);
	float multi = 0.1159 * roughness;

	bool NdotLisPos = NoL > 0.0f;
	bool NdotVisPos = NoV > 0.0f;
	dif = NdotVisPos * NdotLisPos * albedo * (single + albedo * multi) * light_color * NoL * fresnel;

	return dif;
}

float3 oren_nayar_and_sh(
	in float3 view_dir,
	in float3 view_normal,
	in float3 view_light_dir,
	in float3 light_color,
	in float rough,
	in float4 sh_lighting_coefficients[10],
	in float3 albedo,
	in float3x3 tangent_frame,
	in float3 fresnel,
	out float3 sh)
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
	sh = lightprobe_color;
	return ONdif + lightprobe_color * albedo;
}

void calc_material_analytic_specular_h2a_ps(
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
    float3 H = normalize(light_dir + view_dir);
    float NdotL = max(dot(normal_dir, light_dir), _epsilon);
    float NdotV = max(dot(normal_dir, view_dir), _epsilon);
    float NdotH = max(dot(normal_dir, H), _epsilon);
	float LdotH = max(dot(light_dir, H), _epsilon);
    float VdotH = max(dot(view_dir, H), _epsilon);

	float specular_mask = misc.w;

	material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));
	if(tag_colour_change)
	{
		diffuse_albedo_color = lerp(diffuse_albedo_color, diffuse_albedo_color * albedo_cc_col, specular_mask);
		diffuse_albedo_color = lerp(diffuse_albedo_color, diffuse_albedo_color * albedo_cc_col_2, 1 - specular_mask);
		material_parameters.xyz = lerp(material_parameters.xyz, material_parameters.xyz * specular_cc_col, specular_mask);
		material_parameters.xyz = lerp(material_parameters.xyz, material_parameters.xyz * specular_cc_col_2, 1 - specular_mask);
	}
	specular_albedo_color = 0;
	float4 spec_gloss = material_parameters;

	float3 T, B;
	orthonormal_basis(normal_dir, T, B);

#ifdef H2A_ADVANCED
//=====================================================
//		PARAMETERS
//=====================================================
	material_parameters.xyz= clamp(material_parameters.xyz * metalness.xyz + metalness.w, 0.0, 1.0);
	material_parameters.w= 1 - clamp(material_parameters.w * gloss_scale + gloss_bias, 0.0, 0.999);
	
	float clearcoat_rough = 1 - clamp(spec_gloss.w * paint_gloss_scale + paint_gloss_bias, 0.0, 0.999);
	float3 clearcoat_spec_col = clamp(spec_gloss.xyz * paint_metalness.xyz + paint_metalness.w, 0.0, 1.0);
	float clearcoat_scale = enable_carpaint;

	float aniso_scale = clamp((anisotropy * 2.0 - 1.0) * enable_aniso, -1.0, 1.0);
	
	#ifdef H2A_ADVANCED_MASKED
		material_parameters.xyz = 	lerp(material_parameters.xyz,
										clamp(spec_gloss.xyz * mask_metalness.xyz + mask_metalness.w, 0.0, 1.0),
										specular_mask);

		material_parameters.w = 	lerp(material_parameters.w,
										1 - clamp(spec_gloss.w * mask_gloss_scale + mask_gloss_bias, 0.0, 0.999),
										specular_mask);

		clearcoat_rough = lerp(clearcoat_rough, 1 - clamp((spec_gloss.w * mask_paint_gloss_scale + mask_paint_gloss_bias), 0.0, 0.999), specular_mask);
		clearcoat_spec_col = lerp(clearcoat_spec_col, clamp(spec_gloss.xyz * mask_paint_metalness.xyz + mask_paint_metalness.w, 0.0, 1.0), specular_mask);
		clearcoat_scale = lerp(clearcoat_scale, enable_mask_carpaint, specular_mask);

		aniso_scale = lerp(aniso_scale, clamp((mask_anisotropy * 2.0 - 1.0) * enable_mask_aniso, -1.0, 1.0), specular_mask);
	#endif

	float a2 = material_parameters.w * material_parameters.w;
	float a2_coat = clearcoat_rough * clearcoat_rough;
	float at = a2 * (1 - aniso_scale);
	float ab = a2 * (1 + aniso_scale);

//=====================================================
//		BRDF
//=====================================================
	float NDF = ndf_aniso_ggx(NdotH, view_dir, H, T, B, at, ab);
	float3 F = FresnelSchlick(material_parameters.xyz, LdotH);
	float G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, at, ab);
	float3 Ks = NDF * F * G;
	specular_fresnel_color = (1 - F);
	if(clearcoat_scale > 0.0f)
	{
	float coat_NDF = ndf_aniso_ggx(NdotH, view_dir, H, T, B, a2_coat, a2_coat);
	float3 coat_F = FresnelSchlick(clearcoat_spec_col, LdotH);
	float coat_G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, a2_coat, a2_coat);

	Ks *= pow(1 - (coat_F * clearcoat_scale), 2);
	Ks += coat_NDF * coat_F * coat_G * clearcoat_scale;
	specular_fresnel_color *= (1 - (coat_F * clearcoat_scale));
	}

	specular_albedo_color = clearcoat_spec_col;
	analytic_specular_radiance = Ks * NdotL * light_irradiance;

	misc.x = clearcoat_rough;
	misc.y = clearcoat_scale;
	misc.z = at;
	misc.w = ab;
#else
	material_parameters.xyz= clamp(material_parameters.xyz * metalness.xyz + metalness.w, 0.0, 1.0);
	material_parameters.w= 1 - clamp(material_parameters.w * gloss_scale + gloss_bias, 0.0, 0.999);

	float a2 = material_parameters.w * material_parameters.w;
	float NDF = ndf_aniso_ggx(NdotH, view_dir, H, T, B, a2, a2);
	float3 F = FresnelSchlick(material_parameters.xyz, LdotH);
	float G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, a2, a2);

	specular_fresnel_color = (1 - F);
	analytic_specular_radiance = NDF * F * G * NdotL * light_irradiance;

	misc.x = 0.0f;
	misc.y = 0.0f;
	misc.z = a2;
	misc.w = a2;
#endif
}

void calc_material_h2a_ps(
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

		float3 albedo = diffuse_reflectance;
		misc = float4(tangent_frame[1],specular_mask);

		calc_material_analytic_specular_h2a_ps(
			view_dir,
			surface_normal,
			view_reflect_dir_world,
			analytical_light_dir,
			analytical_light_intensity,
			diffuse_reflectance,
			texcoord,
			prt_ravi_diff.w,
			tangent_frame[2],
			misc,
			material_parameters,
			fresnel_analytical,
			effective_reflectance,
			specular_analytical);

	float3 NdotV = saturate(dot(surface_normal, view_dir));

	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	if (!no_dynamic_lights)
	{
#ifdef	H2A_ADVANCED
		calc_simple_lights_spec_gloss_advanced(
				fragment_position_world,
				surface_normal,
				view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
				view_dir,
				material_parameters.rgb,
				effective_reflectance,
				material_parameters.w,
				misc,
				diffuse_reflectance,
				simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
				simple_light_specular_light);
#else
		calc_simple_lights_spec_gloss(
				fragment_position_world,
				surface_normal,
				view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
				view_dir,
				material_parameters.rgb,
				material_parameters.w,
				diffuse_reflectance,
				simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
				simple_light_specular_light);
#endif
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}
	
	//float metallic = 1 - max(max(f0.r, f0.g), f0.b);
	float3 sh;
	diffuse_radiance = oren_nayar_and_sh(
							view_dir,
							surface_normal,
							analytical_light_dir,
							analytical_light_intensity,
							material_parameters.w,
							sh_lighting_coefficients,
							diffuse_reflectance,
							tangent_frame,
							fresnel_analytical,
							sh);

	float3 cubemap_sh;
	calculate_area_specular_new_phong_3(
	view_reflect_dir_world,
	sh_lighting_coefficients,
	1.0f,
	1,
	cubemap_sh);
	//float NdotV = saturate(dot(surface_normal, view_dir));
	float3 env_fresnel = FresnelSchlickRoughness(material_parameters.rgb, material_parameters.w, NdotV);
	env_fresnel = EnvBRDFApprox(env_fresnel, material_parameters.w, NdotV);

#ifdef H2A_ADVANCED
	float3 env_fresnel_cc = FresnelSchlickRoughness(effective_reflectance, misc.x, NdotV);
	env_fresnel_cc = EnvBRDFApprox(env_fresnel_cc, misc.x, NdotV);

	env_fresnel *= (1 - env_fresnel_cc);
	envmap_specular_reflectance_and_roughness= float4(env_fresnel * cubemap_sh, material_parameters.w);
	envmap_area_specular_only = env_fresnel_cc * cubemap_sh;
#else
	envmap_specular_reflectance_and_roughness= float4(env_fresnel * cubemap_sh, material_parameters.w);
	envmap_area_specular_only = 0;
#endif

	//envmap_specular_reflectance_and_roughness= float4();
	//envmap_area_specular_only = float3(max(max(sh.r, sh.g), sh.b), misc.x, specular_mask);

	

	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light);
		
	specular_radiance.xyz= (simple_light_specular_light + specular_analytical) * prt_ravi_diff.z * specular_coefficient;
	
	specular_radiance.w= 0.0f;
}

void calc_material_analytic_specular_h2a_advanced_ps(
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
	calc_material_analytic_specular_h2a_ps(
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

void calc_material_h2a_advanced_ps(
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
	calc_material_h2a_ps(
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

void calc_material_analytic_specular_h2a_advanced_mask_ps(
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
	calc_material_analytic_specular_h2a_ps(
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

void calc_material_h2a_advanced_mask_ps(
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
	calc_material_h2a_ps(
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
	//Look into setting up the normal map here so you don't have Halo 3's weird Zbump bullshit.
#endif // _pbr_FX_
