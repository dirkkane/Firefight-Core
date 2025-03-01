#ifndef _SH_GLOSSY_FX_
#define _SH_GLOSSY_FX_

/*
sh_glossy.fx
Mon, Jul 25, 2005 5:01pm (haochen)
*/

//*****************************************************************************
// sh_rotate_0236
// DESC: Rotate SH coefficients (Lighting) into local frame
// Inputs:
//		
//		int irgb:					which color index, r, g, or b
//		float3 rotate_x:			x vector of the rotation matrix
//		float3 rotate_z:			z vector of the rotation matrix
//		float3 sh_0;				y[0].rgb, the DC term
//		float4 sh_312[3]:			y[3],	y[1],	-y[2] for r, g, b
//		float4 sh_457[3]:			-y[4],	y[5],	y[7]  for r, g, b
//		float4 sh_8866[3]:			-y[8],	y[8],	-y[6]*SQRT3,	y[6]*SQRT3 for r, g, b
//		
//		float4 quadratic_a:			float4(-SQRT3 * rotate_z.yzx * rotate_z.xyz, 0.0f)
//		float4 quadratic_b:			float4(-SQRT3 * 0.5*float4(rotate_z.xyz * rotate_z.xyz, 1.0f/3.0f);
//									Pass these in so we don't have to caclulate them again for r, g, b
//
//*****************************************************************************

float4 sh_rotate_0236(
	int irgb,
	float3 rotate_x;
	float3 rotate_z,
	float4 sh_0,
	float4 sh_312[3],
	float4 sh_457[3],
	float4 sh_8866[3],
	float4 quadratic_a,
	float4 quadratic_b)
{
    float4 result= float4(
			sh_0[irgb],
			-dot(rotate_z.xyz, sh_312[irgb].xyz),
			 dot(rotate_x.xyz, sh_312[irgb].xyz),
			 dot(quadratic_a.xyz, sh_457[irgb].xyz)+dot(quadratic_b.xyzw, sh_8866[irgb].xyzw));           
			 
	return result;      
}

//*****************************************************************************
// sh_rotate_78
//
// Inputs:
//
//    quadratic_a.xyz = rotate_x.xyz * rotate_z.yzx + rotate_x.yzx * rotate_z.xyz;
//    quadratic_b.xyz = rotate_x.xyz * rotate_z.xyz;
//****************************************************************************
float3 sh_rotate_78(	
	float4 quadratic_a,
	float4 quadratic_b,
	float4 sh_457[3],
	float4 sh_8866[3])
{
	float3 result= float3(
		dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyz, sh_8866[0].xyz),
		dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyz, sh_8866[1].xyz)
		dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyz, sh_8866[2].xyz));
	
	return result;
}

//*****************************************************************************
// sh_glossy_ct_3
//
// Constants:
//
//	ct_glossy_constant.x: view z shift;
//	ct_glossy_constant.y: roughness shift;
//	ct_glossy_constant.z: roughness;
//
//	sampler cc0236	:	the cook torrance pre-integrated textures
//	sampler dd0236	:
//	sampler c78d78	:
//
// Inputs:
//		
//
//****************************************************************************

#define A0_88         0.886226925f
#define A2_10         1.023326708f
#define A6_49         0.495415912f

float4 ct_glossy_constant;
sampler cc0236;
sampler dd0236;
sampler c78d78;

sh_glossy_ct_3(
	in float4 view_pos,
	in float3 view_normal,
	in float3 view_tangent,
	out float4 diffuse_color,
	out float4 specular_color,
	out float4 fresnel)
{

	const float3 sh_constant= float3(A0_88, A2_10, A6_49);
	
	//build the local frame
	float3 view_dir= normalize(-view_pos.xyz);
	float3 rotate_z= normalize(view_normal);
	float3 rotate_x= normalize(view_dir - dot(view_dir, rotate_z) * rotate_z);
	float3 rotate_y= normalize(cross(rotate_z, rotate_x));
	
	//local view
	float view_angle= dot(view_dir, rotate_z);
	float2 view_lookup;
    view_lookup= float2( dot(view_dir,rotate_x)+ct_glossy_constant.x, ct_glossy_constant.z+ct_glossy_constant.y);
   
	float4 cc_value;
	float4 dd_value;
	
    // bases: 0,2,3,6
    tex_value= tex2D( cc0236, view_lookup );
    schl_value= tex2D( dd0236, view_lookup );
    
    float4 quadratic_a, quadratic_b, sh_local;
    
    quadratic_a.xyz= -SQRT3 * rotate_z.yzx * rotate_z.xyz;
    quadratic_b= -SQRT3 * 0.5*float4(rotate_z.xyz * rotate_z.xyz, 1.0f/3.0f);
    
    sh_local= sh_rotate_0236(0, quadratic_a, quadratic_b); // channel - r
    diffuse_color.r= dot( sh_constant, sh_local.xyw );
    specular_color.r= dot( tex_value, sh_local );
	fresnel.r= dot( schl_value, sh_local );
	
    sh_local= sh_rotate_0236(1, quadratic_a, quadratic_b); // channel - g
    diffuse_color.g= dot( sh_constant, sh_local.xyw );
    specular_color.g= dot( tex_value, shLocal );
	fresnel.g= dot( schl_value, shLocal );
	
    sh_local= sh_rotate_0236(2, quadratic_a, quadratic_b); // channel - b
    diffuse_color.b= dot( sh_constant, sh_local.xyw );
    specular_color.b= dot( tex_value, sh_local );
	fresnel.b= dot( schl_value, sh_local );

	//bases: 7,8
    tex_value= tex2D( c78d78, view_lookup );
    // basis - 7
    quadratic_a.xyz= rotate_x.xyz * rotate_z.yzx + rotate_x.yzx * rotate_z.xyz;
    quadratic_b.xyz= rotate_x.xyz * rotate_z.xyz;
    sh_local.rgb= sh_rotate_78(quadratic_a, quadratic_b);
    specular_color.rgb+= tex_value.x*sh_local.rgb;
    fresnel.rgb+= tex_value.z*sh_local.rgb;
    // basis - 8
    quadratic_a.xyz= rotate_x.xyz * rotate_x.yzx - rotate_y.yzx * rotate_y.xyz;
    quadratic_b.xyz= 0.5f*(rotate_x.xyz * rotate_x.xyz - rotate_y.xyz * rotate_y.xyz);
    sh_local.rgb= sh_rotate_78(quadratic_a, quadratic_b);
    specular_color.rgb+= tex_value.y*sh_local.rgb;
    fresnel.rgb+= tex_value.w*sh_local.rgb;
    
}

#endif //ifndef _SH_GLOSSY_FX_