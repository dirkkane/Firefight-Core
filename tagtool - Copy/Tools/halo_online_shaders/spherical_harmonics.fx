// some common shared routines for calculating sh lighting
//
// 

#define SQRT3 1.73205080756

// PRT C0 default = 1 / 2 sqrt(pi)
#define PRT_C0_DEFAULT (0.28209479177387814347403972578039)

//#define LIGHTPROBE_8BIT

//pack the constants into a form for calculating RAVI and area SH specular
void pack_constants(in float4 L0_L3[3], in float4 L4_L7[3], out float4 lighting_constants[10])
{
	lighting_constants[0]= float4(L0_L3[0][0], L0_L3[1][0], L0_L3[2][0], 0);
	
	lighting_constants[1]= float4(L0_L3[0][3], L0_L3[0][1], -L0_L3[0][2], 0); 
	lighting_constants[2]= float4(L0_L3[1][3], L0_L3[1][1], -L0_L3[1][2], 0); 
	lighting_constants[3]= float4(L0_L3[2][3], L0_L3[2][1], -L0_L3[2][2], 0); 
	
	lighting_constants[4]= float4(-L4_L7[0][0], L4_L7[0][1], L4_L7[0][3], 0); 
	lighting_constants[5]= float4(-L4_L7[1][0], L4_L7[1][1], L4_L7[1][3], 0); 
	lighting_constants[6]= float4(-L4_L7[2][0], L4_L7[2][1], L4_L7[2][3], 0); 
	
	lighting_constants[7]= float4(0, 0, -L4_L7[0][2]*1.73205080756f, L4_L7[0][2]*1.73205080756f); 
	lighting_constants[8]= float4(0, 0, -L4_L7[1][2]*1.73205080756f, L4_L7[1][2]*1.73205080756f); 
	lighting_constants[9]= float4(0, 0, -L4_L7[2][2]*1.73205080756f, L4_L7[2][2]*1.73205080756f); 
}

void pack_constants_linear(in float4 L0_L3[3], out float4 lighting_constants[4])
{
	lighting_constants[0]= float4(L0_L3[0][0], L0_L3[1][0], L0_L3[2][0], 0);
	lighting_constants[1]= float4(L0_L3[0][3], L0_L3[0][1], -L0_L3[0][2], 0); 
	lighting_constants[2]= float4(L0_L3[1][3], L0_L3[1][1], -L0_L3[1][2], 0); 
	lighting_constants[3]= float4(L0_L3[2][3], L0_L3[2][1], -L0_L3[2][2], 0); 
}

void pack_constants_texture_array(in float3 sh_coefficients[9], out float4 lighting_constants[10])
{
	lighting_constants[0]= float4(sh_coefficients[0], 0);
	
	lighting_constants[1]= float4(sh_coefficients[3].r, sh_coefficients[1].r, -sh_coefficients[2].r, 0); 
	lighting_constants[2]= float4(sh_coefficients[3].g, sh_coefficients[1].g, -sh_coefficients[2].g, 0); 
	lighting_constants[3]= float4(sh_coefficients[3].b, sh_coefficients[1].b, -sh_coefficients[2].b, 0); 
	
	lighting_constants[4]= float4(-sh_coefficients[4].r,sh_coefficients[5].r, sh_coefficients[7].r, 0); 
	lighting_constants[5]= float4(-sh_coefficients[4].g,sh_coefficients[5].g, sh_coefficients[7].g, 0); 
	lighting_constants[6]= float4(-sh_coefficients[4].b,sh_coefficients[5].b, sh_coefficients[7].b, 0); 
	
	lighting_constants[7]= float4(-sh_coefficients[8].r, sh_coefficients[8].r, -sh_coefficients[6].r*1.73205080756f, sh_coefficients[6].r*1.73205080756f); 
	lighting_constants[8]= float4(-sh_coefficients[8].g, sh_coefficients[8].g, -sh_coefficients[6].g*1.73205080756f, sh_coefficients[6].g*1.73205080756f); 
	lighting_constants[9]= float4(-sh_coefficients[8].b, sh_coefficients[8].b, -sh_coefficients[6].b*1.73205080756f, sh_coefficients[6].b*1.73205080756f); 
}

void pack_constants_texture_array_linear(in float3 sh_coefficients[4], out float4 lighting_constants[4])
{
	lighting_constants[0]= float4(sh_coefficients[0], 0);
	
	lighting_constants[1]= float4(sh_coefficients[3].r, sh_coefficients[1].r, -sh_coefficients[2].r, 0); 
	lighting_constants[2]= float4(sh_coefficients[3].g, sh_coefficients[1].g, -sh_coefficients[2].g, 0); 
	lighting_constants[3]= float4(sh_coefficients[3].b, sh_coefficients[1].b, -sh_coefficients[2].b, 0); 
	
}

float calculate_ambientness(float4 sh_lighting_coefficients[4], float3 dominant_light_intensity, float3 dominant_light_dir)
{
	float3 dir_eval= float3(-0.4886025f * dominant_light_dir.y, -0.4886025f * dominant_light_dir.z, -0.4886025 * dominant_light_dir.x);	
	float4 temp;
	temp.xyz= sh_lighting_coefficients[2].xyz - dir_eval.zxy * dominant_light_intensity.y;
	temp.w= sh_lighting_coefficients[0].y- 0.2820948f * dominant_light_intensity.y;
	float ambientness= dot(temp, temp)/(dot(sh_lighting_coefficients[2].xyz, sh_lighting_coefficients[2].xyz)+ sh_lighting_coefficients[0].y * sh_lighting_coefficients[0].y);
	return min(ambientness, 1.0f);
}

float3 ravi_order_0(float3 normal, float4 lighting_constants[10])
{
	float c4 = 0.886227f;
	
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb)/3.1415926535f;
	
	return lightprobe_color;
}

float3 ravi_order_2(float3 normal, float4 lighting_constants[10])
{
	//3, 1, 2, 0/6
	float3 x1;
	
//	float3 normal4.xyz= normalize(normal4.xyz);
	
	x1.r = dot( normal, lighting_constants[1].rgb);		// linear red
	x1.g = dot( normal, lighting_constants[2].rgb);		// linear green
	x1.b = dot( normal, lighting_constants[3].rgb);		// linear blue
	
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb + (-2.f*c2) * x1)/3.1415926535f;
	
//	float3 lightprobe_color = (c4 * lighting_constants[0] + (-2.f*c2) * x1)/3.1415926535f;

	return lightprobe_color;
}

float3 ravi_order_2_new(float3 normal, float4 lighting_constants[4])
{
	//3, 1, 2, 0/6
	float3 x1;
	
//	float3 normal4.xyz= normalize(normal4.xyz);
	
	x1.r = dot( normal, lighting_constants[1].rgb);		// linear red
	x1.g = dot( normal, lighting_constants[2].rgb);		// linear green
	x1.b = dot( normal, lighting_constants[3].rgb);		// linear blue
	
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb + (-2.f*c2) * x1)/3.1415926535f;
	
//	float3 lightprobe_color = (c4 * lighting_constants[0] + (-2.f*c2) * x1)/3.1415926535f;

	return lightprobe_color;
}

float3 ravi_order_2_with_dominant_light(float3 normal, float4 lighting_constants[4], float3 dominant_light_dir, float3 dominant_light_intensity)
{

	//subtract the dominant light from the SH coefficients
	float3 dir_eval= float3(-0.4886025f * dominant_light_dir.y, -0.4886025f * dominant_light_dir.z, -0.4886025 * dominant_light_dir.x);		
	lighting_constants[1].xyz -= dir_eval.zxy * dominant_light_intensity.x;
	lighting_constants[2].xyz -= dir_eval.zxy * dominant_light_intensity.y;
	lighting_constants[3].xyz -= dir_eval.zxy * dominant_light_intensity.z;
	lighting_constants[0].xyz-= 0.2820948f * dominant_light_intensity;
	
	float3 x1;	
	x1.r = dot( normal, lighting_constants[1].rgb);		// linear red
	x1.g = dot( normal, lighting_constants[2].rgb);		// linear green
	x1.b = dot( normal, lighting_constants[3].rgb);		// linear blue
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb + (-2.f*c2) * x1)/3.1415926535f;
	float3 dominant_lighting= max(dot( dominant_light_dir, normal), 0.0f) * dominant_light_intensity * 0.281f;
	return lightprobe_color + dominant_lighting;
}

float ravi_order_2_monochromatic(float3 normal, float4 SH_monochrome_3120)
{
	//3, 1, 2, 0/6
	float x1;
	
	x1 = dot( normal, SH_monochrome_3120.xyz );		// linear
	
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	
	float lightprobe_color = (c4 * SH_monochrome_3120.w + (-2.f*c2) * x1)/3.1415926535f;

	return lightprobe_color;
}

//calculating area SH specular for order 3.
float3 ravi_order_3(float3 normal, float4 lighting_constants[10])
{
	//3, 1, 2, 0/6
	float3 x1, x2, x3;
	
//	float3 normal4.xyz= normalize(normal4.xyz);
	
	x1.r = dot( normal, lighting_constants[1].rgb);		// linear red
	x1.g = dot( normal, lighting_constants[2].rgb);		// linear green
	x1.b = dot( normal, lighting_constants[3].rgb);		// linear blue
	
	float3 a = normal.xyz*normal.yzx;
	
	x2.r = dot( a.xyz, lighting_constants[4].rgb);		// quadratic red 1
	x2.g = dot( a.xyz, lighting_constants[5].rgb);		// quadratic green 1
	x2.b = dot( a.xyz, lighting_constants[6].rgb);		// quadratic blue 1
	
	float4 b = float4( normal.xyz*normal.xyz, 1.f/3.f );

	x3.r = dot( b.xyzw, lighting_constants[7].rgba);	// quadratic red 2
	x3.g = dot( b.xyzw, lighting_constants[8].rgba);	// quadratic green 2
	x3.b = dot( b.xyzw, lighting_constants[9].rgba);	// quadratic blue 2
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	
	float3 lightprobe_color = (c4 * lighting_constants[0].rgb + (-2.f*c2) * x1 + (-2.f*c1)*x2 - c1 * x3)/3.1415926535f;
	
//	float3 lightprobe_color = (c4 * lighting_constants[0] + (-2.f*c2) * x1)/3.1415926535f;

	return lightprobe_color;
}

//calculating area SH specular for order 3.
float ravi_order_3_monochromatic(
		float3 normal, 
		float4 SH_monochrome_3120,
		float4 SH_monochrome_457,
		float4 SH_monochrome_8866)
{
	//3, 1, 2, 0/6
	float x1, x2, x3;
	
//	float3 normal4.xyz= normalize(normal4.xyz);
	
	x1 = dot( normal, SH_monochrome_3120.xyz );		// linear
	
	float3 a = normal.xyz*normal.yzx;
	
	x2 = dot( a.xyz, SH_monochrome_457.xyz );		// quadratic 1
	
	float4 b = float4( normal.xyz*normal.xyz, 1.f/3.f );

	x3 = dot( b.xyzw, SH_monochrome_8866.xyzw );	// quadratic 2
	
	float c1 = 0.429043f;
	float c2 = 0.511664f;
	float c4 = 0.886227f;
	
	float lightprobe_color = (c4 * SH_monochrome_3120.w + (-2.f*c2) * x1 + (-2.f*c1)*x2 - c1 * x3)/3.1415926535f;
	
//	float3 lightprobe_color = (c4 * lighting_constants[0] + (-2.f*c2) * x1)/3.1415926535f;

	return lightprobe_color;
}


//we seperate out these quadratic so we only need to evaluate them once for r, g, b
void sh_inverse_rotate_0123_monochrome(
	float4 inverse_transform[3],
	float4 sh_3120,
	out float4 result_0123)
{
//	result_0123.x=  sh_3120.w;
//	result_0123.y=  dot(rotate_y, sh_3120.xyz);			// rotate_y == float3(inverse_transform[0].y, inverse_transform[1].y, inverse_transform[2].y)
//	result_0123.z= -dot(rotate_z, sh_3120.xyz);			// rotate_z == float3(inverse_transform[0].z, inverse_transform[1].z, inverse_transform[2].z);
//	result_0123.w=  dot(rotate_x, sh_3120.xyz);			// rotate_x == float3(inverse_transform[0].x, inverse_transform[1].x, inverse_transform[2].x);

	result_0123.x= sh_3120.w;
	result_0123.yzw  = sh_3120.x * inverse_transform[0].yzx;
	result_0123.yzw += sh_3120.y * inverse_transform[1].yzx;
	result_0123.yzw += sh_3120.z * inverse_transform[2].yzx;
	result_0123.z = -result_0123.z;
}


void sh_rotate_0123_RGB(
	float3 rotate_x,			// world_to_local
	float3 rotate_y,
	float3 rotate_z,
	float4 sh_0,
	float4 sh_312[3],
	out float4 result_0123_r,
	out float4 result_0123_g,
	out float4 result_0123_b)
{
	result_0123_r= float4(
		sh_0.x,
		dot(rotate_y, sh_312[0].xyz),
        -dot(rotate_z, sh_312[0].xyz),
        dot(rotate_x, sh_312[0].xyz));
        
	result_0123_g= float4(
		sh_0.y,
		dot(rotate_y, sh_312[1].xyz),
        -dot(rotate_z, sh_312[1].xyz),
        dot(rotate_x, sh_312[1].xyz));

	result_0123_b= float4(
		sh_0.z,
		dot(rotate_y, sh_312[2].xyz),
        -dot(rotate_z, sh_312[2].xyz),
        dot(rotate_x, sh_312[2].xyz));

}
	
	
void sh_inverse_rotate_45678_monochrome(
	float4 inverse_transform[3],
	float4 sh_457,
	float4 sh_8866,
	out float4 result_4567,
	out float result_8)
{
	// this is just easier in transposed space, so transpose it
	float3	rotate_x	=	float3(inverse_transform[0].x, inverse_transform[1].x, inverse_transform[2].x);
	float3	rotate_y	=	float3(inverse_transform[0].y, inverse_transform[1].y, inverse_transform[2].y);
	float3	rotate_z	=	float3(inverse_transform[0].z, inverse_transform[1].z, inverse_transform[2].z);
	
	//	sh_457[0]	=	light_constant_4	(red)
	//	sh_8866[0]	=	light_constant_7	(red)
	
	// for 4
	
			//	quadratic_a= D3DXVECTOR3(rotation_x. x * rotation_y.y + rotation_x. y * rotation_y.x,
			//							 rotation_x. y * rotation_y.z + rotation_x. z * rotation_y.y,
			//							 rotation_x. z * rotation_y.x + rotation_x. x * rotation_y.z);

			//	quadratic_b= D3DXVECTOR3(rotation_x. x * rotation_y.x, 
			//							 rotation_x. y * rotation_y.y,
			//							 rotation_x. z * rotation_y.z);

			//	out_r[4]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
			//	out_g[4]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
			//	out_b[4]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	float4 quadratic_a, quadratic_b;
	quadratic_a.xyz = rotate_x.xyz * rotate_y.yzx + rotate_x.yzx * rotate_y.xyz;
	quadratic_b.xyz = rotate_x.xyz * rotate_y.xyz;
    result_4567.x= -dot(quadratic_a.xyz, sh_457.xyz) - dot(quadratic_b.xyz, sh_8866.xyz);

	//for 5
	
		//	quadratic_a= D3DXVECTOR3(rotation_y. x * rotation_z.y + rotation_y. y * rotation_z.x,
		//							 rotation_y. y * rotation_z.z + rotation_y. z * rotation_z.y,
		//							 rotation_y. z * rotation_z.x + rotation_y. x * rotation_z.z);

		//	quadratic_b= D3DXVECTOR3(rotation_y. x * rotation_z.x, 
		//							 rotation_y. y * rotation_z.y,
		//							 rotation_y. z * rotation_z.z);

		//	out_r[5]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
		//	out_g[5]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
		//	out_b[5]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_y.xyz * rotate_z.yzx + rotate_y.yzx * rotate_z.xyz;
	quadratic_b.xyz = rotate_y.xyz * rotate_z.xyz;
	result_4567.y= dot(quadratic_a.xyz, sh_457.xyz) + dot(quadratic_b.xyz, sh_8866.xyz);

	//for 6
	
		//	quadratic_a= D3DXVECTOR3( rotation_x.y * rotation_x.x - 2.0f * rotation_z.y * rotation_z.x + rotation_y.y * rotation_y.x,
		//							  rotation_x.y * rotation_x.z - 2.0f * rotation_z.y * rotation_z.z + rotation_y.y * rotation_y.z,
		//							  rotation_x.x * rotation_x.z - 2.0f * rotation_z.x * rotation_z.z + rotation_y.x * rotation_y.z)/sqrt3;

		//	quadratic_b= D3DXVECTOR3(
		//		(0.5f * rotation_x.x * rotation_x.x +
		//		        rotation_z.y * rotation_z.y +
		//		0.5f *  rotation_y.x * rotation_y.x),

		//		(      rotation_z.x * rotation_z.x +
		//		0.5f * rotation_x.y * rotation_x.y +
		//		0.5f * rotation_y.y * rotation_y.y),

		//		rotation_x.z * rotation_x.z / 2.0f -
		//		rotation_z.z * rotation_z.z +
		//		rotation_y.z * rotation_y.z / 2.0f)/sqrt3;

		//	out_r[6]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
		//	out_g[6]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
		//	out_b[6]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

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

	quadratic_a.xyz = rotate_z.yzx * rotate_z.xyz * (-SQRT3);
	quadratic_b.xyzw= float4(rotate_z.xyz * rotate_z.xyz, 1.0f/3.0f) * 0.5f * (-SQRT3);
    result_4567.z = dot(quadratic_a.xyz, sh_457.xyz) + dot(quadratic_b.xyzw, sh_8866.xyzw);
    
	//for 7
//	quadratic_a= D3DXVECTOR3(rotation_x. x * rotation_z.y + rotation_x. y * rotation_z.x,
//							 rotation_x. y * rotation_z.z + rotation_x. z * rotation_z.y,
//							 rotation_x. z * rotation_z.x + rotation_x. x * rotation_z.z);

//	quadratic_b= D3DXVECTOR3(rotation_x. x * rotation_z.x, 
//							 rotation_x. y * rotation_z.y,
//							 rotation_x. z * rotation_z.z);

//	out_r[7]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[7]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[7]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_x.xyz * rotate_z.yzx + rotate_x.yzx * rotate_z.xyz;
	quadratic_b.xyz = rotate_x.xyz * rotate_z.xyz;
	result_4567.w= dot(quadratic_a.xyz, sh_457.xyz) + dot(quadratic_b.xyz, sh_8866.xyz);

	//for 8
//	quadratic_a= D3DXVECTOR3(rotation_x.x * rotation_x.y - rotation_y.y * rotation_y.x,
//		rotation_x.y * rotation_x.z - rotation_y.z * rotation_y.y,
//		rotation_x.z * rotation_x.x - rotation_y.x * rotation_y.z);

//	quadratic_b= D3DXVECTOR3(rotation_x. x * rotation_x.x - rotation_y. x * rotation_y.x,
//		rotation_x. y * rotation_x.y - rotation_y. y * rotation_y.y,
//		rotation_x. z * rotation_x.z - rotation_y. z * rotation_y.z ) * 0.5f;

//	out_r[8]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[8]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[8]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_x.xyz * rotate_x.yzx - rotate_y.yzx * rotate_y.xyz;
	quadratic_b.xyz = 0.5f*(rotate_x.xyz * rotate_x.xyz - rotate_y.xyz * rotate_y.xyz);
	result_8= -dot(quadratic_a.xyz, sh_457.xyz) - dot(quadratic_b.xyz, sh_8866.xyz);
}

	
void sh_rotate_45678_RGB(
	float3 rotate_x,
	float3 rotate_y,
	float3 rotate_z,
	float4 sh_457[3],
	float4 sh_8866[3],
	out float4 result_4567_r,
	out float4 result_4567_g,
	out float4 result_4567_b,
	out float3 result_8rgb)
{
	float4 quadratic_a, quadratic_b;
	
	//for 4
	
//	D3DXVECTOR3 quadratic_a, quadratic_b;
//	quadratic_a= D3DXVECTOR3(rotation_x. x * rotation_y.y + rotation_x. y * rotation_y.x,
//							 rotation_x. y * rotation_y.z + rotation_x. z * rotation_y.y,
//							 rotation_x. z * rotation_y.x + rotation_x. x * rotation_y.z);

//	quadratic_b= D3DXVECTOR3(rotation_x. x * rotation_y.x, 
//							 rotation_x. y * rotation_y.y,
//							 rotation_x. z * rotation_y.z);

//	out_r[4]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[4]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[4]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_x.xyz * rotate_y.yzx + rotate_x.yzx * rotate_y.xyz;
	quadratic_b.xyz = rotate_x.xyz * rotate_y.xyz;                      
    result_4567_r.x= -dot(quadratic_a.xyz, sh_457[0].xyz) - dot(quadratic_b.xyz, sh_8866[0].xyz);
    result_4567_g.x= -dot(quadratic_a.xyz, sh_457[1].xyz) - dot(quadratic_b.xyz, sh_8866[1].xyz);
    result_4567_b.x= -dot(quadratic_a.xyz, sh_457[2].xyz) - dot(quadratic_b.xyz, sh_8866[2].xyz);

	//for 5
	
//	quadratic_a= D3DXVECTOR3(rotation_y. x * rotation_z.y + rotation_y. y * rotation_z.x,
//							 rotation_y. y * rotation_z.z + rotation_y. z * rotation_z.y,
//							 rotation_y. z * rotation_z.x + rotation_y. x * rotation_z.z);

//	quadratic_b= D3DXVECTOR3(rotation_y. x * rotation_z.x, 
//							 rotation_y. y * rotation_z.y,
//							 rotation_y. z * rotation_z.z);

//	out_r[5]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[5]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[5]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_y.xyz * rotate_z.yzx + rotate_y.yzx * rotate_z.xyz;
	quadratic_b.xyz = rotate_y.xyz * rotate_z.xyz;
	result_4567_r.y= dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyz, sh_8866[0].xyz);
	result_4567_g.y= dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyz, sh_8866[1].xyz);
	result_4567_b.y= dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyz, sh_8866[2].xyz);

	//for 6
	
//	quadratic_a= D3DXVECTOR3( rotation_x.y * rotation_x.x - 2.0f * rotation_z.y * rotation_z.x + rotation_y.y * rotation_y.x,
//							  rotation_x.y * rotation_x.z - 2.0f * rotation_z.y * rotation_z.z + rotation_y.y * rotation_y.z,
//							  rotation_x.x * rotation_x.z - 2.0f * rotation_z.x * rotation_z.z + rotation_y.x * rotation_y.z)/sqrt3;

//	quadratic_b= D3DXVECTOR3(
//		(0.5f * rotation_x.x * rotation_x.x +
//		        rotation_z.y * rotation_z.y +
//		0.5f *  rotation_y.x * rotation_y.x),

//		(      rotation_z.x * rotation_z.x +
//		0.5f * rotation_x.y * rotation_x.y +
//		0.5f * rotation_y.y * rotation_y.y),

//		rotation_x.z * rotation_x.z / 2.0f -
//		rotation_z.z * rotation_z.z +
//		rotation_y.z * rotation_y.z / 2.0f)/sqrt3;

//	out_r[6]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[6]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[6]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

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

    result_4567_r.z = dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyzw, sh_8866[0].xyzw);
    result_4567_g.z = dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyzw, sh_8866[1].xyzw);
    result_4567_b.z = dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyzw, sh_8866[2].xyzw);
    
	//for 7
//	quadratic_a= D3DXVECTOR3(rotation_x. x * rotation_z.y + rotation_x. y * rotation_z.x,
//							 rotation_x. y * rotation_z.z + rotation_x. z * rotation_z.y,
//							 rotation_x. z * rotation_z.x + rotation_x. x * rotation_z.z);

//	quadratic_b= D3DXVECTOR3(rotation_x. x * rotation_z.x, 
//							 rotation_x. y * rotation_z.y,
//							 rotation_x. z * rotation_z.z);

//	out_r[7]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[7]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[7]= D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) + D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_x.xyz * rotate_z.yzx + rotate_x.yzx * rotate_z.xyz;
	quadratic_b.xyz = rotate_x.xyz * rotate_z.xyz;
	result_4567_r.w= dot(quadratic_a.xyz, sh_457[0].xyz) + dot(quadratic_b.xyz, sh_8866[0].xyz);
	result_4567_g.w= dot(quadratic_a.xyz, sh_457[1].xyz) + dot(quadratic_b.xyz, sh_8866[1].xyz);
	result_4567_b.w= dot(quadratic_a.xyz, sh_457[2].xyz) + dot(quadratic_b.xyz, sh_8866[2].xyz);

	//for 8
//	quadratic_a= D3DXVECTOR3(rotation_x.x * rotation_x.y - rotation_y.y * rotation_y.x,
//		rotation_x.y * rotation_x.z - rotation_y.z * rotation_y.y,
//		rotation_x.z * rotation_x.x - rotation_y.x * rotation_y.z);

//	quadratic_b= D3DXVECTOR3(rotation_x. x * rotation_x.x - rotation_y. x * rotation_y.x,
//		rotation_x. y * rotation_x.y - rotation_y. y * rotation_y.y,
//		rotation_x. z * rotation_x.z - rotation_y. z * rotation_y.z ) * 0.5f;


//	out_r[8]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[4]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[7]);
//	out_g[8]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[5]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[8]);
//	out_b[8]= -D3DXVec3Dot(&quadratic_a, (D3DXVECTOR3*)&sh_packed[6]) - D3DXVec3Dot(&quadratic_b, (D3DXVECTOR3*)&sh_packed[9]);

	quadratic_a.xyz = rotate_x.xyz * rotate_x.yzx - rotate_y.yzx * rotate_y.xyz;
	quadratic_b.xyz = 0.5f*(rotate_x.xyz * rotate_x.xyz - rotate_y.xyz * rotate_y.xyz);
	result_8rgb.r= -dot(quadratic_a.xyz, sh_457[0].xyz) - dot(quadratic_b.xyz, sh_8866[0].xyz);
	result_8rgb.g= -dot(quadratic_a.xyz, sh_457[1].xyz) - dot(quadratic_b.xyz, sh_8866[1].xyz);
	result_8rgb.b= -dot(quadratic_a.xyz, sh_457[2].xyz) - dot(quadratic_b.xyz, sh_8866[2].xyz);
		
}

void calculate_analytical_specular_new_phong_3(
	in float3 dominant_light_dir,
	in float3 dominant_light_intensity,
	in float3 reflect_dir,
	in float roughness,
	out float3 s0)
{
	float roughness_sq= roughness * roughness;
	float cos_theta= max(dot(dominant_light_dir, reflect_dir), 0.0f);
	float cos_theta_sq= cos_theta * cos_theta;
	float tan_theta_sq= (1.0f - cos_theta_sq)/cos_theta_sq;
	//float tan_theta_sq_over_roughness_sq = (roughness_sq != 0) ? (-tan_theta_sq / roughness_sq) : 0;
	s0= (3.1415926f * roughness_sq * cos_theta * cos_theta_sq) * exp(-(tan_theta_sq)/roughness_sq) * dominant_light_intensity;
}

void calculate_area_specular_new_phong_3(
	in float3 reflection_dir,
	in float4 sh_lighting_coefficients[10],
	in float roughness,
	in bool order3,
	out float3 s0)
{
	float roughness_sq= roughness * roughness;
	
	float c_dc=		0.282095f;
	float c_linear=	-(0.5128945834f + (-0.1407369526f) * roughness + (-0.2660066620e-2f) * roughness_sq) * 0.60f;
	float c_quradratic=	-(0.7212524717f + (-0.5541015389f) * roughness + (0.7960539966e-1f ) * roughness_sq) * 0.5f;
	
	float3 x0, x1, x2, x3;

	x0= sh_lighting_coefficients[0].rgb;

	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].rgb);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].rgb);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].rgb);
	
	if (order3)
	{
	
		float3 quadratic_a= (reflection_dir.xyz)*(reflection_dir.yzx);
		x2.x= dot(quadratic_a, sh_lighting_coefficients[4].rgb);
		x2.y= dot(quadratic_a, sh_lighting_coefficients[5].rgb);
		x2.z= dot(quadratic_a, sh_lighting_coefficients[6].rgb);

		float4 quadratic_b = float4( reflection_dir.xyz*reflection_dir.xyz, 1.f/3.f );
		
		x3.x= dot(quadratic_b, sh_lighting_coefficients[7]);
		x3.y= dot(quadratic_b, sh_lighting_coefficients[8]);
		x3.z= dot(quadratic_b, sh_lighting_coefficients[9]);
		
		s0= max(x0 * c_dc + x1 * c_linear + x2 * c_quradratic + x3 * c_quradratic, 0.0f);
		
	}
	else
	{
		s0= max(x0 * c_dc + x1 * c_linear, 0.0f);
	}
		
}

void calculate_area_specular_new_phong_2(
	in float3 reflection_dir,
	in float4 sh_lighting_coefficients[4],
	in float roughness,
	out float3 s0)
{
	float roughness_sq= roughness * roughness;
	
	float c_dc=		0.282095f;
	float c_linear=	-(0.5128945834f + (-0.1407369526f) * roughness + (-0.2660066620e-2f) * roughness_sq) * 0.60f;
	
	float3 x0, x1, x2, x3;

	x0= sh_lighting_coefficients[0].rgb;

	x1.r=  dot(reflection_dir, sh_lighting_coefficients[1].rgb);
	x1.g=  dot(reflection_dir, sh_lighting_coefficients[2].rgb);
	x1.b=  dot(reflection_dir, sh_lighting_coefficients[3].rgb);
	
	
	s0= max(x0 * c_dc + x1 * c_linear,  0.0f);
		
}