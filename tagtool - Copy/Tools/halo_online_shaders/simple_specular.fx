#ifndef _SIMPLE_COOK_TORRANCE_FX_
#define _SIMPLE_COOK_TORRANCE_FX_

//****************************************************************************
// Simple Cook Torrance Material Model parameters
//****************************************************************************
/*
float	diffuse_coefficient;								//how much to scale diffuse by
float	specular_coefficient;								//how much to scale specular by
float3	fresnel_color;										//reflectance at normal incidence
float	roughness;											//roughness
float	area_specular_contribution;							//scale the area sh contribution
float	analytical_specular_contribution;					//scale the analytical sh contribution
float	environment_map_specular_contribution;				//scale the environment map contribution
float	albedo_blend;										//how much to blend in the albedo color to fresnel f0
float3	specular_tint;

float analytical_anti_shadow_control;

sampler material_texture;					//a texture that stores spatially varient parameters
float4	material_texture_transform;			//texture matrix

sampler g_sampler_cc0236;					//pre-integrated texture
sampler g_sampler_dd0236;					//pre-integrated texture
sampler g_sampler_c78d78;					//pre-integrated texture

#define A0_88         0.886226925f
#define A2_10         1.023326708f
#define A6_49         0.495415912f
*/
//*****************************************************************************
// Analytical Cook-Torrance for point light source only
//*****************************************************************************

void calculate_analytical_sct(
	in float3 view_dir,								// normalized fragment to camera, world space
	in float3 normal_dir,							// normalized fragment surface normal, world space
	in float3 light_dir,							// normalized fragment to light, world space
	in float3 light_color,							// light color
	in float3 fresnel_f0,							// fresnel part
	in float2 texcoord,
	in float ambientness,
	out float3 specular_color,
	out float3 fresnel)
{
    float n_dot_l = dot( normal_dir, light_dir );
    float n_dot_v = dot( normal_dir, view_dir );
    
    if( n_dot_l > 0 && n_dot_v > 0 )
	{
        // compute geom attenuation
        float3	half_vector = normalize( view_dir + light_dir );
        float	n_dot_h		= dot( normal_dir, half_vector );
        float	v_dot_h		= dot( view_dir, half_vector); 
        
        // VH may be negative by numerical errors, so we need saturate(VH)
        float  geometry_term = 2*n_dot_h* min(n_dot_v, n_dot_l) / saturate(v_dot_h); // G = saturate(G)
        
        //calculate fresnel term
		float3 f0= min(fresnel_f0, 0.999f);
		float3 sqrt_f0 = sqrt( f0 );
		float3 n = ( 1.f + sqrt_f0 ) / ( 1.0 - sqrt_f0 );
		float3 g = sqrt( n*n + v_dot_h*v_dot_h - 1.f );
		float3 gpc = g + v_dot_h;
		float3 gmc = g - v_dot_h;
		float3 r = (v_dot_h*gpc-1.f) / (v_dot_h*gmc+1.f);
		fresnel= ( 0.5f * ( (gmc*gmc) / (gpc*gpc) ) * ( 1.f + r*r ));
		
		//calculate the distribution term
//		float roughness= roughness * tex2D(material_texture, texcoord).a;
		float roughness= max(roughness, 0.05f);
		float m_squared= roughness*roughness;			
		float cosine_alpha_squared = n_dot_h * n_dot_h;
		float distribution;
		distribution= exp((cosine_alpha_squared-1)/(m_squared*cosine_alpha_squared))/(m_squared*cosine_alpha_squared*cosine_alpha_squared);
		
		//puting it all together
		float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control);
		specular_color= distribution * saturate(geometry_term) / (3.14159265 * n_dot_v) * fresnel * light_color * ambient_multiplier;
     }
     else
     {
		specular_color= 0.00001f;
		fresnel= fresnel_f0;
	 }
}

//*****************************************************************************
// cook-torrance for area light source in SH space
//*****************************************************************************


#define c_view_z_shift 0.5f/32.0f
#define	c_roughness_shift 0.0f

#define SWIZZLE xyzw

void sh_glossy_sct_3(
	in float3 view_dir,
	in float3 view_normal,
	in float4 sh_0,
	in float4 sh_312[3],
	in float4 sh_457[3],
	in float4 sh_8866[3],
	in float r_dot_l,
	out float3 specular_part,
	out float3 diffuse_part,
	out float3 schlick_part)
{

	//do I want to expose these parameters?
	//build the local frame
	float3 rotate_z= normalize(view_normal);
	float3 rotate_x= normalize(view_dir - dot(view_dir, rotate_z) * rotate_z);
	float3 rotate_y= normalize(cross(rotate_z, rotate_x));
	
	//local view
	float2 view_lookup;
	float roughness= max(roughness * roughness, 0.15f);
	
    view_lookup= float2( dot(view_dir,rotate_x)+c_view_z_shift, roughness + c_roughness_shift);
   
	float4 cc_value;
	float4 dd_value;
	
    // bases: 0,2,3,6
    float4 c_value;
    float4 d_value;
    
    c_value= tex2D( g_sampler_cc0236, view_lookup ).SWIZZLE;
    d_value= tex2D( g_sampler_dd0236, view_lookup ).SWIZZLE;
    
    float4 quadratic_a, quadratic_b, sh_local;
    
    //0,2,3,6 
//	quadratic_a.xyz = (rotate_x.yyx * rotate_x.xzz - 2.0 * rotate_z.yyx * rotate_z.xzz + rotate_y.yyx * rotate_y.xzz)/SQRT3;
//	quadratic_b= float4(0.5f * rotate_x.x * rotate_x.x +
//						rotate_z.y * rotate_z.y +
//						0.5f *  rotate_y.x * rotate_y.x,

//						rotate_z.x * rotate_z.x +
//						0.5f * rotate_x.y * rotate_x.y +
//						0.5f * rotate_y.y * rotate_y.y,

//						rotate_x.z * rotate_x.z / 2.0f -
//						rotate_z.z * rotate_z.z +
//						rotate_y.z * rotate_y.z / 2.0f,
						
//						0.0f)/SQRT3;
					
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
    diffuse_part.r = dot( float3(A0_88, A2_10, A6_49), sh_local.xyw );
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
				
    diffuse_part.g = dot( float3(A0_88, A2_10, A6_49), sh_local.xyw );
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
		
    diffuse_part.b = dot( float3(A0_88, A2_10, A6_49), sh_local.xyw );
    sh_local*= float4(1.0f, r_dot_l, r_dot_l, r_dot_l);
    specular_part.b= dot( c_value, sh_local );
	schlick_part.b= dot( d_value, sh_local );

    // basis - 7
    c_value= tex2D( g_sampler_c78d78, view_lookup ).SWIZZLE;
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
    diffuse_part= diffuse_part/3.1415926f;
                
}

#ifdef SHADER_30
void calc_material_model_cook_torrance_ps(
	in float3 v_view_dir,
	in float3 fragment_to_camera_world,
	in float3 v_view_normal,
	in float3 view_reflect_dir_world,
	in float4 sh_lighting_coefficients[10],
	in float3 v_view_light_dir,
	in float3 light_color,
	in float3 albedo_color,
	in float  specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float3 specular_color,
	out float3 diffuse_color)
{

	//calculate the analytical sh	    
    float3 specular_analytical;
    float3 specular_sh_glossy;
    float3 fresnel_analytical;
    float3 fresnel_area_sh;
    
    float3 view_dir= normalize(v_view_dir);
    float3 view_normal= normalize(v_view_normal);
    float3 view_light_dir= normalize(v_view_light_dir);
        
    float3 effective_reflectance= albedo_color * albedo_blend + fresnel_color * (1-albedo_blend);	
    
	//calculate the ambientness using the green channel only
	float4 diff_sh_lighting_coefficients;
	diff_sh_lighting_coefficients.w= sh_lighting_coefficients[0].g - light_color.g * 0.28209479f;
	diff_sh_lighting_coefficients.xyz= sh_lighting_coefficients[2].xyz- light_color.g * (-view_light_dir.xyz) * 0.488603f;
	float diff_energy= dot(diff_sh_lighting_coefficients, diff_sh_lighting_coefficients);
	//the following ugly line of code is only because a bug in the xenon shader compiler.
	float orig_energy=sh_lighting_coefficients[2].x * sh_lighting_coefficients[2].x + sh_lighting_coefficients[2].y * sh_lighting_coefficients[2].y + sh_lighting_coefficients[2].z * sh_lighting_coefficients[2].z + sh_lighting_coefficients[0].g * sh_lighting_coefficients[0].g;
//	float orig_energy= dot(lighting_constants[2].xyz, lighting_constants[2].xyz) + lighting_constants[0].g * lighting_constants[0].g;
	float ambientness= diff_energy/orig_energy;

   calculate_analytical_ct(
		view_dir,				
		view_normal,
		view_light_dir,
		light_color,
		effective_reflectance, //fresnel_color,
		texcoord,
		ambientness,
		specular_analytical,
		fresnel_analytical);
		
	float3 specular_part;
	float3 diffuse_part;
	float3 schlick_part;
	
	//apply some windowing here
	float4 sh_0= sh_lighting_coefficients[0];
	float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
	float4 sh_457[3]= {sh_lighting_coefficients[4], sh_lighting_coefficients[5], sh_lighting_coefficients[6]};
	float4 sh_8866[3]= {sh_lighting_coefficients[7], sh_lighting_coefficients[8], sh_lighting_coefficients[9]};
	
	float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;

	//calculate the area sh
	sh_glossy_ct_3(
		view_dir,
		view_normal,
		sh_0,
		sh_312,
		sh_457,
		sh_8866,
		r_dot_l,
		specular_part,
		diffuse_part,
		schlick_part);
		
	float3 sh_glossy= specular_part * effective_reflectance + (1 - effective_reflectance) * schlick_part;
	
	envmap_area_specular_only= sh_glossy * prt_ravi_diff.z * specular_tint;
	
	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
	calc_simple_lights_analytical(
		fragment_position_world,
		v_view_normal,
		view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
		0.0f,
		simple_light_diffuse_light,
		simple_light_specular_light);
	
	//scaling and masking
	specular_color= specular_mask * specular_coefficient * specular_tint * (
		(simple_light_specular_light * effective_reflectance + specular_analytical) * analytical_specular_contribution +
		max(sh_glossy, 0.0f) * area_specular_contribution);
	
	envmap_specular_reflectance_and_roughness.xyz=	environment_map_specular_contribution * specular_mask * specular_coefficient;
	envmap_specular_reflectance_and_roughness.w=	roughness;			// TODO: replace with whatever you use for roughness
	
//	diffuse_part= ravi_order_3(view_normal, lighting_constants);
	diffuse_color= (simple_light_diffuse_light + max(diffuse_part + prt_ravi_diff.x, 0.0f)) * diffuse_coefficient;
	specular_color*= prt_ravi_diff.z;
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
	in float  specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float3 specular_color,
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