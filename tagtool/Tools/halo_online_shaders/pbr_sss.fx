#ifndef _PBR_SSS_FX_
#define _PBR_SSS_FX_


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
PARAM(float, normal_blur_mip);
PARAM_SAMPLER_2D(ss_curvature_map);
PARAM_SAMPLER_2D(ss_thickness_map);
PARAM_SAMPLER_2D(ss_lut);
PARAM(float, ss_distortion);
PARAM(float, ss_power);
PARAM(float, ss_scale);
PARAM(float3, ss_colour);
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

void calc_material_analytic_specular_pbr_sss_ps(
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
	}

	float3 T, B;
	orthonormal_basis(normal_dir, T, B);

    float3 H    = normalize(light_dir + view_dir);
    float NdotL = clamp(dot(normal_dir, light_dir), 0.0001, 1.0);
	float NdotV = max(dot(normal_dir, view_dir), _epsilon);
    float LdotH = clamp(dot(light_dir, H), 0.0001, 1.0);
	float VdotH = max(dot(view_dir, H), _epsilon);
    float NdotH = clamp(dot(normal_dir, H), 0.0001, 1.0);
    float min_dot = min(NdotL, NdotV);
	float a2 = material_parameters.y * material_parameters.y;

	specular_albedo_color = 0.04f;
	specular_fresnel_color = FresnelSchlick(specular_albedo_color, VdotH);

	float NDF = ndf_aniso_ggx(NdotH, view_dir, H, T, B, a2, a2);
	float G = G_aniso(NdotH, NdotL, NdotV, view_dir, light_dir, T, B, a2, a2);
	analytic_specular_radiance = NDF * specular_fresnel_color * G;

    analytic_specular_radiance = analytic_specular_radiance * light_irradiance * NdotL;

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

float3 approx_sss_direct(in float NdotL, in float curvature)
{
	NdotL = mad(NdotL, 0.5, 0.5); // map to 0 to 1 range
	float curva = (1.0/mad(curvature, 0.5 - 0.0625, 0.0625) - 2.0) / (16.0 - 2.0); // curvature is within [0, 1] remap to normalized r from 2 to 16
	float oneMinusCurva = 1.0 - curva;
	float3 curve0;
	{
		float3 rangeMin = float3(0.0, 0.3, 0.3);
		float3 rangeMax = float3(1.0, 0.7, 0.7);
		float3 offset = float3(0.0, 0.06, 0.06);
		float3 t = saturate( mad(NdotL, 1.0 / (rangeMax - rangeMin), (offset + rangeMin) / (rangeMin - rangeMax)  ) );
		float3 lowerLine = (t * t) * float3(0.65, 0.5, 0.9);
		lowerLine.r += 0.045;
		lowerLine.b *= t.b;
		float3 m = float3(1.75, 2.0, 1.97);
		float3 upperLine = mad(NdotL, m, float3(0.99, 0.99, 0.99) -m );
		upperLine = saturate(upperLine);
		float3 lerpMin = float3(0.0, 0.35, 0.35);
		float3 lerpMax = float3(1.0, 0.7 , 0.6 );
		float3 lerpT = saturate( mad(NdotL, 1.0/(lerpMax-lerpMin), lerpMin/ (lerpMin - lerpMax) ));
		curve0 = lerp(lowerLine, upperLine, lerpT * lerpT);
	}
	float3 curve1;
	{
		float3 m = float3(1.95, 2.0, 2.0);
		float3 upperLine = mad( NdotL, m, float3(0.99, 0.99, 1.0) - m);
		curve1 = saturate(upperLine);
	}
	float oneMinusCurva2 = oneMinusCurva * oneMinusCurva;
	float3 brdf = lerp(curve0, curve1, mad(oneMinusCurva2, -1.0 * oneMinusCurva2, 1.0) );

	return brdf;
}

float3 sss(
	in float2 texcoord,
	in float3 view_dir,
	in float3 view_normal,
	in float3 blurred_normal,
	in float3 view_light_dir,
	in float3 light_color,
	in float curvature,
	in float thickness,
	in float3 albedo,
	in float3 fresnel)
{
	float NdotL_blur = dot(blurred_normal, view_light_dir);
	float3 skin_dif = sample2D(ss_lut, float2(mad(NdotL_blur, 0.5f, 0.5f), curvature));// * 0.5 - 0.25;
	skin_dif.rgb = float3(lerp(skin_dif.b, skin_dif.r, ss_colour.r), lerp(skin_dif.g, skin_dif.r, ss_colour.g), lerp(skin_dif.b, skin_dif.r, ss_colour.b));
	skin_dif = skin_dif * 0.5 - 0.25;
    float normalSmoothFactor = saturate(1.0 - NdotL_blur);
    normalSmoothFactor *= normalSmoothFactor;
    float3 view_normalG = normalize(lerp(view_normal, blurred_normal, 0.3 + 0.7 * normalSmoothFactor));
    float3 view_normalB = normalize(lerp(view_normal, blurred_normal, normalSmoothFactor));
    float NoL_ShadeG = saturate(dot(view_normalG, view_light_dir));
    float NoL_ShadeB = saturate(dot(view_normalB, view_light_dir));
	float3 rgbNdotL = float3(saturate(NdotL_blur), NoL_ShadeG, NoL_ShadeB);
	skin_dif = saturate(skin_dif + rgbNdotL);

	float3 sss_H = normalize(view_light_dir + view_normal * ss_distortion);
	float sss_backlight = pow(saturate(dot(view_dir, -sss_H)), ss_power) * thickness;
	float3 translucence = sss_backlight * ss_colour;


	return saturate(skin_dif + translucence) * (albedo / PI) * light_color * (1 - fresnel);
}

float3 sss_and_sh(
	in float2 texcoord,
	in float3 view_dir,
	in float3 view_normal,
	in float3 blurred_normal,
	in float3 view_light_dir,
	in float3 light_color,
	in float3 parameters, //ao, thickness, curvatures
	in float4 sh_lighting_coefficients[10],
	in float3 albedo,
	in float3x3 tangent_frame,
	in float3 fresnel)
{
	float3 ONdif = sss(
						texcoord,
						view_dir,
						view_normal,
						blurred_normal,
						view_light_dir,
						light_color,
						parameters.z,
						parameters.y,
						albedo,
						fresnel);
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
	return ONdif + lightprobe_color * parameters.x * albedo;
}

void calc_material_pbr_sss_ps(
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
	float4 material_parameters;
	calc_material_analytic_specular_pbr_sss_ps(
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

	float3 blurred_normal = sample2Dlod(bump_map, transform_texcoord(texcoord, bump_map_xform), normal_blur_mip).xyz;
	blurred_normal.xy += sample2Dlod(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform), normal_blur_mip).xy * bump_detail_coefficient;
	blurred_normal.z = sqrt(saturate(1.0f + dot(blurred_normal.xy, -blurred_normal.xy)));
	blurred_normal = mul(blurred_normal, tangent_frame);

	float3 NdotV = saturate(dot(surface_normal, view_dir));
	float3 fRough = FresnelSchlickRoughness(effective_reflectance, material_parameters.y, NdotV);

	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	if (!no_dynamic_lights)
	{
		calc_simple_lights_pbr_sss(
				fragment_position_world,
				surface_normal,
				blurred_normal,
				view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
				view_dir,
				material_parameters.yzw,
				diffuse_reflectance,
				ss_colour,
				ss_distortion,
				ss_power,
				ss_lut,
				simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
				simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
	}

	float curvature = sample2D(ss_curvature_map, texcoord).g;
	diffuse_radiance = sss_and_sh(
					texcoord,
					view_dir,
					surface_normal,
					blurred_normal,
					analytical_light_dir,
					analytical_light_intensity,
					material_parameters.xzw,
					sh_lighting_coefficients,
					diffuse_reflectance,
					tangent_frame,
					fresnel_analytical);

	float3 cubemap_sh;
 
	calculate_area_specular_new_phong_3(
		view_reflect_dir_world,
		sh_lighting_coefficients,
		1.0f,
		1,
		cubemap_sh);
	cubemap_sh *= material_parameters.x;

	envmap_specular_reflectance_and_roughness= float4(EnvBRDFApprox(fRough, material_parameters.y, NdotV) * cubemap_sh, material_parameters.y);


	envmap_area_specular_only = 0.0f;




	/*float3 sss_H = normalize(analytical_light_dir + surface_normal * ss_distortion);
	float sss_backlight = pow(saturate(dot(view_dir, -sss_H)), ss_power) * sample2D(ss_thickness_map, texcoord).g;
	diffuse_radiance += sss_backlight * diffuse_reflectance * analytical_light_intensity * ss_colour * (1 - fresnel_analytical);*/


	//float ao_vert = 1 - ((1 - material_parameters.x) * (1 - prt_ravi_diff.x));
	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light); //* prt_ravi_diff.x;

	specular_radiance.xyz= (simple_light_specular_light + specular_analytical);// * prt_ravi_diff.z;//EnvBRDFApprox(fRough, rough, NdotV)
	
	specular_radiance.w= 0.0f;
	//diffuse_radiance = 0.0f;

	//diffuse_radiance = diffuse_reflectance;
	//specular_radiance.xyz = 0.00001f;
	//envmap_specular_reflectance_and_roughness= 0.0f;
}
	//Look into setting up the normal map here so you don't have Halo 3's weird Zbump bullshit.
#endif // _pbr_FX_
