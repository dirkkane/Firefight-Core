#ifndef _TOON_FX_
#define _TOON_FX_

#define PI 3.14159265358979323846264338327950f
#define _epsilon 0.00001f
/*
single_lobe_phong.fx
Mon, Feb 19, 2007 5:41pm (haochen)
*/

PARAM(float3,	fresnel_color);				//reflectance at normal incidence
PARAM(float,	roughness);					//roughness
PARAM(float,	roughness_minimum);
PARAM(float,	albedo_blend);				//how much to blend in the albedo color to fresnel f0
PARAM(float3,	specular_tint);
PARAM(float,	specular_shadowing_amount);

PARAM_SAMPLER_2D(g_sampler_cc0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_dd0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_c78d78);					//pre-integrated texture

#define A0_88			0.886226925f
#define A2_10			1.023326708f
#define A6_49			0.495415912f
//*****************************************************************************
// Analytical Diffuse-Only for point light source only
//*****************************************************************************


float get_material_toon_specular_power(float power_or_roughness)
{
	return 1.0f;
}

float3 get_analytical_specular_multiplier_toon_ps(float specular_mask)
{
	return 0.0f;
}

float3 get_diffuse_multiplier_toon_ps()
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
	x0= sh_lighting_coefficients[0].r * p_0;
	
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

void area_specular_order_2_with_dominant_light(
	in float3 reflection_dir,
	in float3 view,
	in float3 dominant_light_dir,
	in float3 dominant_light_intensity,
	in float4 sh_lighting_coefficients[4],
	in float roughness,
	in float3 tint,
	out float3 s0)
{

	//subtract the dominant light from the SH coefficients
	/*float3 dir_eval= float3(-0.4886025f * dominant_light_dir.y, -0.4886025f * dominant_light_dir.z, -0.4886025 * dominant_light_dir.x);		
	sh_lighting_coefficients[1].xyz -= dir_eval.zxy * dominant_light_intensity.x;
	sh_lighting_coefficients[2].xyz -= dir_eval.zxy * dominant_light_intensity.y;
	sh_lighting_coefficients[3].xyz -= dir_eval.zxy * dominant_light_intensity.z;
	sh_lighting_coefficients[0].xyz-= 0.2820948f * dominant_light_intensity;*/

	float roughness_sq= roughness * roughness;
	
	float c_dc=		0.282095f;
	float c_linear=	-(0.5128945834f + (-0.1407369526f) * roughness + (-0.2660066620e-2f) * roughness_sq) * 0.60f;

	float p_0= 0.4231425f;									// 0.886227f			0.282095f * 1.5f;
	float p_1= -0.3805236f;									// 0.511664f * -2		exp(-0.5f * power_invert) * (-0.488602f);
	float p_2= -0.4018891f;									// 0.429043f * -2		exp(-2.0f * power_invert) * (-1.092448f);
	float p_3= -0.2009446f;									// 0.429043f * -1

	float3 x0, x1, x2, x3;
	
	//constant
	x0= sh_lighting_coefficients[0].rgb;
	
	// linear
	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].xyz);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].xyz);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].xyz);
	
	s0= (max(x0 * c_dc + x1 * c_linear,  0.0f) / PI) * tint;
		
}

float3 sh_order_0(
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
	float4 lighting_constants[4] = {
		sh_lighting_coefficients[0],
		sh_lighting_coefficients[1],
		sh_lighting_coefficients[2],
		sh_lighting_coefficients[3]};
	float c4 = 0.886227f;
	
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb) / PI;
	sh = lightprobe_color;
	return lightprobe_color;
}

void calc_material_analytic_specular_toon_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vert_n_dot_l,
	in float3x3 tangent_frame, 								// = {tangent, binormal, normal};
	in float4 misc,
	out float4 material_parameters,							// only when use_material_texture is defined
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{
	material_parameters= float4(specular_coefficient, albedo_blend, 1.0, max(roughness, 0.05f));
	if (use_material_texture)
	{	
		//over ride shader supplied values with what's from the texture
		material_parameters= sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));
		material_parameters.w = max(saturate(roughness_minimum + roughness * material_parameters.w), 0.05f);
		specular_albedo_color= lerp((float3)0.04f, diffuse_albedo_color, material_parameters.y);
	}
	else
	{
		specular_albedo_color= lerp(specular_tint, diffuse_albedo_color, material_parameters.y);
	}
	float3 H = normalize(light_dir + view_dir);
	float NdotH = saturate(dot(normal_dir, H));
	float NdotL = saturate(dot(normal_dir, light_dir));
	float NdotV = saturate(dot(normal_dir, view_dir));
	float VdotH = saturate(dot(view_dir, H));
	
	float NdotL_stepped = smoothstep(0, 0.01f, NdotL);
	

	specular_albedo_color= lerp(specular_tint, diffuse_albedo_color, material_parameters.y);
	float3 specular_glancing_color = lerp(1, fresnel_color, material_parameters.y);//lerp(max(1 - material_parameters.w, specular_tint), fresnel_color, material_parameters.y);
	specular_fresnel_color= specular_albedo_color + (specular_glancing_color - specular_albedo_color) * pow(1 - VdotH, 5.0f);

	//To-do: 
	//Try colour-banding Blinn first and then feed that into smoothstep with the second param as something like glossiness. Could make for a nicer falloff.
	float blinn_power = max(2/pow(max(material_parameters.w, 0.06),4)-2, 0.00001);
	float blinn_power_sharp = max(2/pow(max(material_parameters.w - (0.6 * material_parameters.w * material_parameters.w), 0.06),4)-2, 0.00001);
	float blinn_normalize = ((blinn_power + 2) / 8); //Used for Blinn-Phong PBR to preserve energy on glossier materials. We aren't going for PBR but this still helps the highlight look good.
	float blinn_phong = blinn_normalize * pow(NdotH, blinn_power);
	float blinn_phong_sharp = blinn_normalize * pow(NdotH, blinn_power_sharp);

	float sharp_highlight = smoothstep(0.005f, 0.01f, saturate(blinn_phong_sharp))  * (1 - smoothstep(0.2, 0.8, material_parameters.w));
	float widest_highlight = min(blinn_phong, 0.175f) * smoothstep(0.2, 0.8, material_parameters.w) * (1 - sharp_highlight);
	float scale_factor = max(8 * material_parameters.w, 1);
	float toon_blinn = sharp_highlight + widest_highlight;

	analytic_specular_radiance= toon_blinn * specular_fresnel_color * NdotL * light_irradiance;
	//specular_fresnel_color= specular_albedo_color + (specular_glancing_color - specular_albedo_color) * pow(1 - NdotV, 5.0f);
}

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

void calc_material_toon_ps(
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
	float4 material_parameters;
	float3 fresnel = 0.0f, effective_reflectance = 0.0f, analytical_specular = 0.0f;

	float NdotL_stepped = saturate(dot(surface_normal, analytical_light_dir));
	NdotL_stepped = smoothstep(0, 0.04f, NdotL_stepped);
	float3 indirect = ravi_order_0(surface_normal, sh_lighting_coefficients);

	calc_material_analytic_specular_toon_ps(
		view_dir,
		surface_normal,
		view_reflect_dir_world,
		analytical_light_dir,
		analytical_light_intensity,
		diffuse_reflectance,
		texcoord,
		prt_ravi_diff.w,
		tangent_frame,
		misc,
		material_parameters,
		fresnel,
		effective_reflectance,
		analytical_specular);
	float3 specular_glancing_color = lerp(max(1 - material_parameters.w, specular_tint), fresnel_color, material_parameters.y);

	diffuse_radiance = (1 / PI) * (1 - fresnel) * NdotL_stepped * analytical_light_intensity;
	fresnel= effective_reflectance + (specular_glancing_color - effective_reflectance) * pow(1 - saturate(dot(surface_normal, view_dir)), 5.0f);
	diffuse_radiance += indirect * (1 - fresnel);

	//if (area_specular_contribution > 0.0f)
	//{
	float3 area_specular;
	float4 sh_coeffs[4] =
	{
		sh_lighting_coefficients[0],
		sh_lighting_coefficients[1],
		sh_lighting_coefficients[2],
		sh_lighting_coefficients[3]
	};
	/*area_specular_order_2_with_dominant_light(
	view_reflect_dir_world,
	view_dir,
	analytical_light_dir,
	analytical_light_intensity,
	sh_coeffs,
	material_parameters.w,
	EnvBRDFApprox(fresnel, material_parameters.w, saturate(dot(surface_normal, view_dir))),
	area_specular);*/
	calculate_area_specular_new_phong_2(
	view_reflect_dir_world,
	sh_coeffs,
	material_parameters.w,
	area_specular);

	area_specular /= PI;
	area_specular *= EnvBRDFApprox(fresnel, material_parameters.w, saturate(dot(surface_normal, view_dir)));
	//}
	
	//area_specular *= 0.35;
	//area_specular *= lerp(1.0f, 0.5f, NdotL_stepped);
	
	float simple_light_dot_sum;
	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	
	if (!no_dynamic_lights)
	{
			calc_toon_lights_analytical(
			fragment_position_world,
			surface_normal,
			view_dir,							// view direction = fragment to camera,   reflected around fragment normal
			material_parameters.w,
			effective_reflectance,
			specular_glancing_color,
			simple_light_dot_sum,
			simple_light_diffuse_light,						// diffusely reflected light (not including diffuse surface color)
			simple_light_specular_light);
	}
	else
	{
		simple_light_diffuse_light= 0.0f;
		simple_light_specular_light= 0.0f;
		simple_light_dot_sum= 0.0f;
	}
		
	area_specular *= lerp(specular_mask * (1 - specular_shadowing_amount), 1, saturate(NdotL_stepped + simple_light_dot_sum));

	float diffuse_adjusted= diffuse_coefficient /* material_parameters.z*/;
	float outlines = 1.0f;
	if (use_material_texture)
	{
		outlines = material_parameters.z;
		diffuse_adjusted= (1.0f - material_parameters.r) * outlines;
	}
	diffuse_radiance= (diffuse_radiance + simple_light_diffuse_light) * diffuse_adjusted;

	specular_radiance.xyz= (area_specular * area_specular_contribution + analytical_specular * analytical_specular_contribution + simple_light_specular_light * fresnel) * specular_coefficient * outlines;
	specular_radiance.w= 0.0f;

	envmap_specular_reflectance_and_roughness= float4((area_specular * environment_map_specular_contribution * outlines * material_parameters.x), material_parameters.w);
	envmap_area_specular_only= prt_ravi_diff.z;
	
}


#endif // _single_lobe_phong_FX_
