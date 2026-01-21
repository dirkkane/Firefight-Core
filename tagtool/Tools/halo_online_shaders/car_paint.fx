#ifndef _CAR_PAINT_FX_
#define _CAR_PAINT_FX_

//****************************************************************************
// Cook Torrance Material Model parameters
//****************************************************************************

PARAM_SAMPLER_2D(bump_detail_map0);
PARAM(float4, bump_detail_map0_xform);

PARAM(float, bump_detail_map0_blend_factor);

PARAM(float,	diffuse_coefficient0);						//how much to scale diffuse by
PARAM(float,	diffuse_coefficient1);						//how much to scale diffuse by
PARAM(float,	specular_coefficient0);						//how much to scale specular by
PARAM(float,	specular_coefficient1);						//how much to scale specular by
PARAM(float,	area_specular_contribution0);					//scale the area sh contribution
PARAM(float,	area_specular_contribution1);					//scale the area sh contribution
PARAM(float,	analytical_specular_contribution0);					//scale the analytical sh contribution
PARAM(float,	analytical_specular_contribution1);					//scale the analytical sh contribution
//float	environment_map_specular_contribution0;			//scale the environment map contribution
PARAM(float,	environment_map_specular_contribution1);			//scale the environment map contribution
PARAM(bool, use_material_texture0);
PARAM(bool, use_material_texture1);
PARAM(bool, order3_area_specular0);
PARAM(bool, order3_area_specular1);



PARAM(float3,	fresnel_color0);				//reflectance at normal incidence
PARAM(float3,	fresnel_color1);				//reflectance at normal incidence
PARAM(float3,	fresnel_color_environment1);
PARAM(float,	 fresnel_power0);
PARAM(float,	 fresnel_power1);
PARAM(float,	 roughness0);					//roughness
PARAM(float,	 roughness1);					//roughness
PARAM(float,	 albedo_blend0);				//how much to blend in the albedo color to fresnel f0
PARAM(float,	 albedo_blend1);				//how much to blend in the albedo color to fresnel f0
PARAM(float3,	specular_tint0);
PARAM(float3,	specular_tint1);

#ifndef LOW_SHADERS
PARAM(float,	 rim_fresnel_coefficient1);
PARAM(float3,	rim_fresnel_color1);
PARAM(float,	 rim_fresnel_power1);
PARAM(float,	 rim_fresnel_albedo_blend1);
#endif

PARAM_SAMPLER_2D(g_sampler_cc0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_dd0236);					//pre-integrated texture
PARAM_SAMPLER_2D(g_sampler_c78d78);					//pre-integrated texture

#define A0_88			0.886226925f
#define A2_10			1.023326708f
#define A6_49			0.495415912f

float get_specular_power(float _roughness)
{
	return 0.27291 * pow(_roughness, -2.1973);				// ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
}

float3 get_analytical_specular_multiplier_car_paint_ps(float3 specular_mask)
{
	float3 v = specular_mask * specular_coefficient0 * analytical_specular_contribution0 * specular_tint0;
		 v += specular_mask * specular_coefficient1 * analytical_specular_contribution1 * specular_tint1;
	return v;
}

float3 get_diffuse_multiplier_car_paint_ps()
{
	return diffuse_coefficient0 + diffuse_coefficient1;
}


//*****************************************************************************
// Analytical Cook-Torrance for point light source only
//*****************************************************************************


void _calc_material_analytic_specular_car_paint(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
	in  float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance,				 // return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
	in float3 _fresnel_color)
{
	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + _fresnel_color * (1-spatially_varying_material_parameters.g);

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


float3x3 compute_tangent_frame(float3 normal)
{
	float3x3 basis;

	static float3 up = { 0.0f, 0.0f, 1.0f };
	static float3 forward = { 1.0f, 0.0f, 0.0f };
	float3 product = cross(normal, up);
	if (all(product == float3(0, 0, 0))) {
		product = cross(normal, forward);
	}
	basis[0] = normalize(product);
	basis[1] = normalize(cross(basis[0], normal));
	basis[2] = normal;

	return basis;
}


void calc_material_analytic_specular_two_layer(
	in float3 view_dir,										// fragment to camera, in world space
	inout float3 normal_dir0,									// bumped fragment surface normal, in world space
	in float3 normal_dir1,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
    in float3 surface_normal,
	out float4 spatially_varying_material_parameters0,
	out float3 specular_fresnel_color0,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color0,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance0,					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
	out float4 spatially_varying_material_parameters1,
	out float3 specular_fresnel_color1,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color1,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance1,				// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
	out float3 specular_albedo_color_env1)
{
	float3 detail_normal = sample_bumpmap(bump_detail_map0, transform_texcoord(texcoord, bump_detail_map0_xform));
	detail_normal = mul(detail_normal, compute_tangent_frame(surface_normal));
	normal_dir0 = normalize(lerp(normal_dir0, detail_normal, bump_detail_map0_blend_factor) );

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: albedo blend
	// b: environment contribution
	// a: roughless
	float4 mat_tex = sample2D(material_texture, transform_texcoord(texcoord, material_texture_xform));

	/// layer0
	spatially_varying_material_parameters0= float4(specular_coefficient0, albedo_blend0, 0.0f, roughness0);
	if (use_material_texture0)
	{
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters0 *= mat_tex;
	}

	_calc_material_analytic_specular_car_paint(
		view_dir,										// fragment to camera, in world space
		normal_dir0,									// bumped fragment surface normal, in world space
		view_reflect_dir,								// view_dir reflected about surface normal, in world space
		light_dir,									// fragment to light, in world space
		light_irradiance,								// light intensity at fragment; i.e. light_color
		diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
		texcoord,
		vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
		spatially_varying_material_parameters0,
		specular_fresnel_color0,						// fresnel(specular_albedo_color)
		specular_albedo_color0,						// specular reflectance at normal incidence
		analytic_specular_radiance0,				// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
		fresnel_color0);

	/// layer1
	spatially_varying_material_parameters1 = float4(specular_coefficient1, albedo_blend1, environment_map_specular_contribution1, roughness1);
	if (use_material_texture1)
	{
		//over ride shader supplied values with what's from the texture
		spatially_varying_material_parameters1 *= mat_tex;
	}

	_calc_material_analytic_specular_car_paint(
		view_dir,										// fragment to camera, in world space
		normal_dir1,									// bumped fragment surface normal, in world space
		view_reflect_dir,								// view_dir reflected about surface normal, in world space
		light_dir,									// fragment to light, in world space
		light_irradiance,								// light intensity at fragment; i.e. light_color
		diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
		texcoord,
		vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
		spatially_varying_material_parameters1,
		specular_fresnel_color1,						// fresnel(specular_albedo_color)
		specular_albedo_color1,						// specular reflectance at normal incidence
		analytic_specular_radiance1,				// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
		fresnel_color1);

	specular_albedo_color_env1 = diffuse_albedo_color * spatially_varying_material_parameters1.g + fresnel_color_environment1 * (1-spatially_varying_material_parameters1.g);
}


void calc_material_analytic_specular_car_paint_ps(
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

	/// layer0
	float3 normal_dir0 = normal_dir;
	float4 spatially_varying_material_parameters0;
	float3 specular_fresnel_color0;
	float3 specular_albedo_color0;
	float3 analytic_specular_radiance0;
	/// layer1
	float3 normal_dir1 = normal_dir;
	float4 spatially_varying_material_parameters1;
	float3 specular_fresnel_color1;
	float3 specular_albedo_color1;
	float3 analytic_specular_radiance1;
	float3 specular_albedo_color_env1;

	calc_material_analytic_specular_two_layer(
		view_dir,										// fragment to camera, in world space
		normal_dir0,									// bumped fragment surface normal, in world space
		normal_dir1,									// bumped fragment surface normal, in world space
		view_reflect_dir,								// view_dir reflected about surface normal, in world space
		light_dir,									// fragment to light, in world space
		light_irradiance,								// light intensity at fragment; i.e. light_color
		diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
		texcoord,
		vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
        surface_normal,
		spatially_varying_material_parameters0,
		specular_fresnel_color0,						// fresnel(specular_albedo_color)
		specular_albedo_color0,						// specular reflectance at normal incidence
		analytic_specular_radiance0,
		spatially_varying_material_parameters1,
		specular_fresnel_color1,						// fresnel(specular_albedo_color)
		specular_albedo_color1,						// specular reflectance at normal incidence
		analytic_specular_radiance1,				// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
		specular_albedo_color_env1);

	specular_fresnel_color = specular_fresnel_color0 + specular_fresnel_color1;
	specular_albedo_color = specular_albedo_color0 + specular_albedo_color1;
	analytic_specular_radiance = analytic_specular_radiance0 + analytic_specular_radiance1;
	spatially_varying_material_parameters = spatially_varying_material_parameters0 + spatially_varying_material_parameters1;
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
	in float _fresnel_power,
	out float3 specular_part,
	out float3 schlick_part)
{
	//build the local frame
	float3 rotate_x= normalize(view_dir - dot(view_dir, rotate_z) * rotate_z);		// view vector projected onto tangent plane
	float3 rotate_y= cross(rotate_z, rotate_x);										// third one, 90 degrees  :)

	//local view
	float t_roughness= max(roughness, 0.05f);
	float2 view_lookup= float2( pow(dot(view_dir,rotate_x), _fresnel_power) + c_view_z_shift, t_roughness + c_roughness_shift);

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
	in float _fresnel_power,
	out float3 specular_part,
	out float3 schlick_part)
{
	//build the local frame
	float3 rotate_x= normalize(view_dir - dot(view_dir, rotate_z) * rotate_z);		// view vector projected onto tangent plane
	float3 rotate_y= cross(rotate_z, rotate_x);										// third one, 90 degrees  :)

	//local view
	float t_roughness= max(roughness, 0.05f);
	float2 view_lookup= float2( pow(dot(view_dir,rotate_x), _fresnel_power) + c_view_z_shift, t_roughness + c_roughness_shift);

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

void calc_material_car_paint_ps(
	in float3 view_dir,						// normalized
	in float3 fragment_to_camera_world,
	in float3 _view_normal,					// normalized
	in float3 view_reflect_dir_world,		// normalized
#ifndef LOW_PER_VERTEX_SHADERS
	in float4 sh_lighting_coefficients[10],	//NEW LIGHTMAP: changing to linear
#endif
	in float3 view_light_dir,				// normalized
	in float3 light_color,
	in float3 albedo_color,
	in float3 specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
    in float3x3 tangent_frame,
	in float4 misc,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	inout float3 diffuse_radiance)
{
	float3 view_normal0 = _view_normal;
	float4 spatially_varying_material_parameters0;
	float3 fresnel_analytical0;			// fresnel_specular_albedo
	float3 effective_reflectance0;		// specular_albedo (no fresnel)
	float3 specular_analytical0;			// specular radiance

	float3 view_normal1 = _view_normal;
	float4 spatially_varying_material_parameters1;
	float3 fresnel_analytical1;			// fresnel_specular_albedo
	float3 effective_reflectance1;		// specular_albedo (no fresnel)
	float3 specular_analytical1;			// specular radiance
	float3 specular_albedo_color_env1;

	calc_material_analytic_specular_two_layer(
		view_dir,
		view_normal0,
		view_normal1,
		view_reflect_dir_world,
		view_light_dir,
		light_color,
		albedo_color,
		texcoord,
		prt_ravi_diff.w,
        tangent_frame[2],
		spatially_varying_material_parameters0,
		fresnel_analytical0,
		effective_reflectance0,
		specular_analytical0,
		spatially_varying_material_parameters1,
		fresnel_analytical1,
		effective_reflectance1,
		specular_analytical1,
		specular_albedo_color_env1);


	float3 simple_light_diffuse_light0;
	float3 simple_light_specular_light0;
	float3 simple_light_diffuse_light1;
	float3 simple_light_specular_light1;

#ifndef LOW_SHADERS
	if (!no_dynamic_lights)
	{
		float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;

		///layer0
		calc_simple_lights_analytical(
			fragment_position_world,
			view_normal0,
			view_reflect_dir_world,											// view direction = fragment to camera,	reflected around fragment normal
		 get_specular_power(spatially_varying_material_parameters0.a), // roughness
			simple_light_diffuse_light0,
			simple_light_specular_light0);

		///layer1
		calc_simple_lights_analytical(
			fragment_position_world,
			view_normal1,
			view_reflect_dir_world,											// view direction = fragment to camera,	reflected around fragment normal
		 get_specular_power(spatially_varying_material_parameters1.a),
			simple_light_diffuse_light1,
			simple_light_specular_light1);
	}
	else
#endif
	{
		simple_light_diffuse_light0 = 0.0f;
		simple_light_specular_light0= 0.0f;
		simple_light_diffuse_light1 = 0.0f;
		simple_light_specular_light1= 0.0f;
	}

	// calculate area specular
	float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;

	//calculate the area sh
	float3 specular_part0 = 0.0f;
	float3 schlick_part0  = 0.0f;
	float3 specular_part1 = 0.0f;
	float3 schlick_part1  = 0.0f;
#ifndef LOW_SHADERS
	float3 rim_specular_part1 = 0.0f;
	float3 rim_schlick_part1  = 0.0f;
#endif

#ifndef LOW_SHADERS
	if (order3_area_specular0) {
		float4 sh_0= sh_lighting_coefficients[0];
		float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		float4 sh_457[3]= {sh_lighting_coefficients[4], sh_lighting_coefficients[5], sh_lighting_coefficients[6]};
		float4 sh_8866[3]= {sh_lighting_coefficients[7], sh_lighting_coefficients[8], sh_lighting_coefficients[9]};
		sh_glossy_ct_3(
			view_dir,
			view_normal0,
			sh_0,
			sh_312,
			sh_457,
			sh_8866,	//NEW_LIGHTMAP: changing to linear
			spatially_varying_material_parameters0.a,
			r_dot_l,
		 fresnel_power0,
			specular_part0,
			schlick_part0);
	} else
#endif
	{
#ifndef LOW_PER_VERTEX_SHADERS
		float4 sh_0= sh_lighting_coefficients[0];
		float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};

		sh_glossy_ct_2(
			view_dir,
			view_normal0,
			sh_0,
			sh_312,
			spatially_varying_material_parameters0.a,
			r_dot_l,
		 fresnel_power0,
			specular_part0,
			schlick_part0);
#endif
	}

#ifndef LOW_SHADERS
	if (order3_area_specular1) {
		float4 sh_0= sh_lighting_coefficients[0];
		float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
		float4 sh_457[3]= {sh_lighting_coefficients[4], sh_lighting_coefficients[5], sh_lighting_coefficients[6]};
		float4 sh_8866[3]= {sh_lighting_coefficients[7], sh_lighting_coefficients[8], sh_lighting_coefficients[9]};

		sh_glossy_ct_3(
			view_dir,
			view_normal1,
			sh_0,
			sh_312,
			sh_457,
			sh_8866,	//NEW_LIGHTMAP: changing to linear
			spatially_varying_material_parameters1.a,
			r_dot_l,
		 fresnel_power1,
			specular_part1,
			schlick_part1);

		 if (rim_fresnel_coefficient1 > 0.0f) {
			sh_glossy_ct_3(
				view_dir,
				view_normal1,
				sh_0,
				sh_312,
				sh_457,
				sh_8866,	//NEW_LIGHTMAP: changing to linear
				spatially_varying_material_parameters1.a,
				r_dot_l,
				rim_fresnel_power1,
				rim_specular_part1,
				rim_schlick_part1);
		 }
	} else
#endif
	{
	#ifndef LOW_PER_VERTEX_SHADERS
		float4 sh_0= sh_lighting_coefficients[0];
		float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};

		sh_glossy_ct_2(
			view_dir,
			view_normal1,
			sh_0,
			sh_312,
			spatially_varying_material_parameters1.a,
			r_dot_l,
			fresnel_power1,
			specular_part1,
			schlick_part1);
	#endif

	#ifndef LOW_SHADERS
		 if (rim_fresnel_coefficient1 > 0.0f) {
			sh_glossy_ct_2(
				view_dir,
				view_normal1,
				sh_0,
				sh_312,
				spatially_varying_material_parameters1.a,
				r_dot_l,
				rim_fresnel_power1,
				rim_specular_part1,
				rim_schlick_part1);
		 }
	#endif
	}

	float3 sh_glossy0 = specular_part0 * effective_reflectance0 + (1 - effective_reflectance0) * schlick_part0;
	float3 sh_glossy1 = specular_part1 * effective_reflectance1 + (1 - effective_reflectance1) * schlick_part1;
#ifndef LOW_PER_VERTEX_SHADERS
	float3 sh_glossy_env1 = specular_part1 * specular_albedo_color_env1 + (1 - specular_albedo_color_env1) * schlick_part1;
#else
	float3 sh_glossy_env1 = diffuse_radiance * 0.5f;
#endif

	envmap_specular_reflectance_and_roughness.w= spatially_varying_material_parameters1.a;
	envmap_area_specular_only= sh_glossy_env1 * prt_ravi_diff.z * specular_tint1;

	//scaling and masking
	specular_color.xyz = specular_mask * spatially_varying_material_parameters0.r * specular_tint0 * (
		(simple_light_specular_light0 * effective_reflectance0 + specular_analytical0) * analytical_specular_contribution0 +
		max(sh_glossy0, 0.0f) * area_specular_contribution0);

	specular_color.xyz+= specular_mask * spatially_varying_material_parameters1.r * specular_tint1 * (
		(simple_light_specular_light1 * effective_reflectance1 + specular_analytical1) * analytical_specular_contribution1 +
		max(sh_glossy1, 0.0f) * area_specular_contribution1);

	// rim fresnel
#ifndef LOW_SHADERS
	specular_color.xyz += specular_mask * spatially_varying_material_parameters1.r *
	  rim_fresnel_coefficient1 * lerp(rim_fresnel_color1, albedo_color, rim_fresnel_albedo_blend1) * rim_schlick_part1;
#endif

	specular_color.w= 0.0f;

	envmap_specular_reflectance_and_roughness.xyz=	spatially_varying_material_parameters1.b * specular_mask * spatially_varying_material_parameters1.r;		// ###ctchou $TODO this ain't right

	float diffuse_adjusted0 = diffuse_coefficient0;
	//if (use_material_texture0) {
	//	diffuse_adjusted0 *= max(1.0f - spatially_varying_material_parameters0.r, 0.0f);
	//}
	float diffuse_adjusted1 = diffuse_coefficient1;
	//if (use_material_texture1) {
	//	diffuse_adjusted1 *= max(1.0f - spatially_varying_material_parameters1.r, 0.0f);
	//}

	float diff_rad = diffuse_radiance * prt_ravi_diff.x;
	diffuse_radiance = (simple_light_diffuse_light0 + diff_rad) * diffuse_adjusted0;
	diffuse_radiance+= (simple_light_diffuse_light1 + diff_rad) * diffuse_adjusted1;

	specular_color*= prt_ravi_diff.z;
}


#endif //ifndef _SH_GLOSSY_FX_
