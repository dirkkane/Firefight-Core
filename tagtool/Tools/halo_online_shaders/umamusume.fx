#ifndef _UMAMUSUME_FX_
#define _UMAMUSUME_FX_

/*
pbr.fx
Sat, March 15, 2025 1:36pm (oli :D)
*/
#define PI 3.14159265358979323846264338327950f
#define _epsilon 0.00001f

//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************
/*
PARAM(float4, 	front_colour);
PARAM(float, 	front_power);
PARAM(float4, 	mid_colour);
PARAM(float, 	mid_power);
PARAM(float4, 	rim_colour);
PARAM(float, 	rim_power);
*/

PARAM_SAMPLER_2D(uma_shaded_map);
PARAM_SAMPLER_2D(uma_base_map);

PARAM(int, uma_material_mode);

PARAM(int, eye_select);
PARAM(float, eye_highlight_0);
PARAM(float, eye_highlight_1);
//PARAM_SAMPLER_2D(control_map);


//*****************************************************************************
// cook-torrance for area light source in SH space
//*****************************************************************************

float get_material_umamusume_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_umamusume_ps(float specular_mask)
{
	return 0.0f;
}

float3 get_diffuse_multiplier_umamusume_ps()
{
	return 1.0f;
}

float3 toon_dif_and_sh(
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
{/*
	//float3 ONdif = ((albedo / PI) * (1 - fresnel)) * smoothstep(0, 0.07, saturate(dot(view_normal, view_light_dir))) * light_color;
	//Crackhead attempt at redoing spherical harmonics
	float3 dir_eval= float3(-0.4886025f * view_light_dir.y, -0.4886025f * view_light_dir.z, -0.4886025 * view_light_dir.x);*/
	float4 lighting_constants[4] = {
		sh_lighting_coefficients[0],
		sh_lighting_coefficients[1],
		sh_lighting_coefficients[2],
		sh_lighting_coefficients[3]};
/*
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
	sh = lightprobe_color;*/
	float c4 = 0.886227f;
	
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb)/3.1415926535f;
	sh = lightprobe_color;
	return lightprobe_color;
}

void calc_material_analytic_specular_umamusume_ps(
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
	//material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));
	//float4 shaded_texture = sample2D(uma_shaded_map, transform_texcoord(texcoord, material_texture_xform));
	//float4 base_texture = sample2D(uma_base_map, transform_texcoord(texcoord, material_texture_xform));
	
	//float4 control_texture = sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));
	//Should probably make different material models for each of these conditions to avoid dumb if statements

	//misc = saturate(sample2D(material_masks, transform_texcoord(texcoord, material_texture_xform)));
	specular_albedo_color = 0;
//fresnel_ct(f0, VdotH_fullrange);
	//F = f0 + (f1 - f0) * fresnel_blend;
	specular_fresnel_color = 0;
    float3 H    = normalize(light_dir + view_dir);
    float NdotL = clamp(dot(normal_dir, light_dir), 0.0001, 1.0);
	float halfLambert = 0.5 * dot(normal_dir, light_dir) + 0.5;
	float NdotV = saturate(dot(normal_dir, view_dir));
	float facing = dot(normal_dir, view_dir);
    float LdotH = clamp(dot(light_dir, H), 0.0001, 1.0);
	float VdotH_fullrange = saturate(dot(view_dir, H));
	float VdotH = clamp(VdotH_fullrange, 0.0001, 1.0);
    float NdotH = clamp(dot(normal_dir, H), 0.0001, 1.0);
    float min_dot = min(NdotL, NdotV);

	float3 final = 0;
	//float3 uma_dif = diffuse_albedo_color / PI
    if (uma_material_mode == 0)
    {
        material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));
		float4 shaded_texture = sample2D(uma_shaded_map, transform_texcoord(texcoord, material_texture_xform));
		float4 base_texture = sample2D(uma_base_map, transform_texcoord(texcoord, material_texture_xform));
		material_parameters.w = base_texture.g;
		float shadowLerp = saturate(1 + ((base_texture.r * 2 * halfLambert - 0.2) * 100));
		float3 shadedDiff = lerp(shaded_texture.rgb, diffuse_albedo_color, shadowLerp) * light_irradiance;

		float specularMult = 1 + saturate(base_texture.g * 50 * (facing - 0.6));

		float rimLerp = (1 - saturate(facing * 10)) * material_parameters.b;
		float3 rimColor = diffuse_albedo_color * 10;

		final= shadedDiff * specularMult * lerp((float3)1.0, rimColor, rimLerp);
    }
    else if (uma_material_mode == 1)
    {
        material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));
		float4 shaded_texture = sample2D(uma_shaded_map, transform_texcoord(texcoord, material_texture_xform));
		float4 base_texture = sample2D(uma_base_map, transform_texcoord(texcoord, material_texture_xform));
		material_parameters.w = 0;
		float3 shadedDiff = lerp(shaded_texture.rgb, diffuse_albedo_color, base_texture.r) * light_irradiance;
		float rimLerp = (1 - saturate(facing * 8)) * material_parameters.b;
		float3 rimColor = diffuse_albedo_color * 10;
		
		final= shadedDiff * lerp((float3)1.0, rimColor, rimLerp);
    }
    else if (uma_material_mode == 2)
    {
        float2 eye_uv = float2(texcoord.x * 0.25 + (eye_select * 0.25), texcoord.y);
		material_parameters= saturate(sample2D(material_texture, transform_texcoord(eye_uv, material_texture_xform)));
		material_parameters.w = 0;

		float2 altUv = float2(texcoord.x, texcoord.y * 2);
		float4 shaded_texture = sample2D(uma_shaded_map, transform_texcoord(altUv, material_texture_xform));
		float4 base_texture = sample2D(uma_base_map, transform_texcoord(altUv, material_texture_xform));
		
		float hl00 = shaded_texture.r * (eye_highlight_0 >= shaded_texture.r);
        float hl01 = base_texture.r * (eye_highlight_1 >= base_texture.r);
		float3 shadedDiff = lerp(shaded_texture.rgb, diffuse_albedo_color, base_texture.r) * light_irradiance;
		
		final= (diffuse_albedo_color + hl00 + hl01) * light_irradiance;
    }
    else 
    {
        material_parameters= saturate(sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform)));
		float4 shaded_texture = sample2D(uma_shaded_map, transform_texcoord(texcoord, material_texture_xform));
		float4 base_texture = sample2D(uma_base_map, transform_texcoord(texcoord, material_texture_xform));
		material_parameters.w = base_texture.g;
		float shadowLerp = saturate(1 + ((base_texture.r * 2 * halfLambert - 0.2) * 100));
		float3 shadedDiff = lerp(shaded_texture.rgb, diffuse_albedo_color, shadowLerp) * light_irradiance;

		float specularMult = 1 + saturate(base_texture.g * 50 * (facing - 0.6));

		float rimLerp = (1 - saturate(facing * 10)) * material_parameters.b;
		float3 rimColor = diffuse_albedo_color * 10;

		final= shadedDiff * specularMult * lerp((float3)1.0, rimColor, rimLerp);
    }

	analytic_specular_radiance = final;
}

PARAM(float, roughness);
PARAM(float3, specular_tint);

float specular_power_from_roughness()
{
#if DX_VERSION == 11
	if (roughness == 0)
	{
		return 0;
	}
#endif	

	return 0.27291 * pow(roughness, -2.1973);
}

void calc_material_umamusume_ps(
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
	in float3x3 tangent_frame,				// = {tangent, binormal, normal};
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
	float3 albedo = diffuse_reflectance;

	float3 sh;
	float3 sh_lcol = toon_dif_and_sh(
							view_dir,
							surface_normal,
							analytical_light_dir,
							analytical_light_intensity,
							0,
							sh_lighting_coefficients,
							albedo,
							tangent_frame,
							0,
							sh);
	float3 dyn_spec = 0;
	float3 dyn_diff = 0;


	calc_material_analytic_specular_umamusume_ps(
		view_dir,
		surface_normal,
		view_reflect_dir_world,
		analytical_light_dir,
		sh_lcol,
		diffuse_reflectance,
		texcoord,
		prt_ravi_diff.w,
		tangent_frame,
		float4(specular_mask,0,0,0),
		spatially_varying_material_parameters,
		fresnel_analytical,
		effective_reflectance,
		specular_analytical);

	calc_simple_lights_uma(
		fragment_position_world,
		surface_normal,
		view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
        view_dir,
		spatially_varying_material_parameters.w,
        albedo,
		dyn_diff,						// diffusely reflected light (not including diffuse surface color)
		dyn_spec);

	envmap_specular_reflectance_and_roughness=  0.0f;//float4(EnvBRDFApprox(fRough, rough, NdotV) * (max(sh.x, sh.y), sh.z) * /*prt_ravi_diff.z */ spatially_varying_material_parameters.x, rough);
	envmap_area_specular_only = 0.0f;
	/*if(clear_coat)
	{
		envmap_area_specular_only.y = cc_roughness;
	}*/
	//float ao_vert = 1 - ((1 - spatially_varying_material_parameters.x) * (1 - prt_ravi_diff.x));
	diffuse_radiance= 0.0; //* prt_ravi_diff.x;
		
	specular_radiance.xyz=  specular_analytical + dyn_diff + dyn_spec;// * prt_ravi_diff.z;//EnvBRDFApprox(fRough, rough, NdotV)
	
	specular_radiance.w= 0.0f;
	//diffuse_radiance = 0.0f;

	//diffuse_radiance = diffuse_reflectance;
	//specular_radiance.xyz = 0.00001f;
	//envmap_specular_reflectance_and_roughness= 0.0f;
}
	//Look into setting up the normal map here so you don't have Halo 3's weird Zbump bullshit.
#endif // _UMAMUSUME_FX_