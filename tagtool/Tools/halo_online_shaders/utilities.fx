#ifndef _UTILITIES_FX_
#define _UTILITIES_FX_

#ifdef PIXEL_SHADER
#define VS_POS_OUTPUT VPOS
#endif
#ifdef VERTEX_SHADER
#define VS_POS_OUTPUT SV_Position
#endif

// fast is the speed optimized data type, when you don't need full float precision		-- stupid thing doesn't work with gamma correction though...

//#ifdef pc
//#define fast4 half4
//#define fast3 half3
//#define fast2 half2
//#define fast half
//#else // XENON
#define fast4 float4
#define fast3 float3
#define fast2 float2
#define fast float
//#endif


#ifndef pc
	#define TFETCH_3D(OUT, TEX_COORD, SAMPLER, OFFSET, SCALE) asm{ tfetch3D OUT, TEX_COORD, SAMPLER, OffsetZ = OFFSET };
#elif DX_VERSION == 11
	#define TFETCH_3D(OUT, TEX_COORD, SAMPLER, OFFSET, SCALE) OUT = SAMPLER.t.Sample(SAMPLER.s, TEX_COORD.xyz + float3(0, 0, int(OFFSET)));
#elif DX_VERSION == 9
	#define TFETCH_3D(OUT, TEX_COORD, SAMPLER, OFFSET, SCALE) OUT = sample3D(SAMPLER, float3(TEX_COORD.x, TEX_COORD.y, TEX_COORD.z + (OFFSET - 0.)/SCALE));
#endif //pc

// reach
#define raised_analytical_light_maximum 1.0f
#define raised_analytical_light_minimum 0.1f

// RGBE functions
/*
fast4 RGB_to_RGBE(in fast3 rgb)
{
	fast4 rgbe;
	fast maximum= max(max(rgb.r, rgb.g), rgb.b);
#ifdef pc
	maximum= max(maximum, 0.000000001f);			// ###ctchou $TODO this in a hack to get nVidia cards to work (for some reason they often return negative zero) - remove this in Xenon builds through a #define
#endif
	fast exponent;
	fast mantissa= frexp(maximum, exponent);		// note this is an expensive function
	rgbe.rgb= rgb.rgb * (mantissa / maximum);
	rgbe.a= (exponent + 128) / 255.0f;
	return rgbe;
}

fast3 RGBE_to_RGB(in fast4 rgbe)
{
	return rgbe.rgb * ldexp(1.0, rgbe.a * 255.0f - 128);
}
*/

float4 convert_to_bloom_buffer(in float3 rgb)
{
	return float4(rgb, 1.0f); //RGB_to_RGBE(rgb);
}

float3 convert_from_bloom_buffer(in float4 rgba)
{
	return rgba.rgb; //RGBE_to_RGB(rgba);
}

float color_to_intensity(in float3 rgb)
{
	return dot(rgb, float3( 0.299f, 0.587f, 0.114f ));
}

// Convert from XYZ to RGB
float3 convert_xyz_to_rgb(float3 xyz)
{
	float3x3 mat_XYZ_to_rgb = {float3(3.240479f, -1.537150f, -0.498535f), float3(-0.969256f, 1.875991f, 0.041556f), float3(0.055648f, -0.204043f, 1.057311f)};
	float3 rgb= mul(xyz, mat_XYZ_to_rgb);
	return rgb;	
}
	
// Convert from rgb to xyy
float3 convert_rgb_to_xyz(float3 rgb)
{
	float3x3 mat_rgb_to_XYZ = {float3(0.412424f, 0.357579f, 0.180464f), float3(0.212656f, 0.715158f, 0.0721856f), float3(0.0193324f,  0.119193f , 0.950444f)};
	float3 xyz= mul(rgb, mat_rgb_to_XYZ);
	return xyz;
}

// Convert from XYZ to RGB
float3 convert_xyy_to_rgb(float3 xyy)
{
	float3 xyz;
	xyz.x= xyy.x * (xyy.y / xyy.z);
	xyz.y= xyy.y;
	xyz.z= (1.0f - xyy.x - xyy.z)* (xyy.y/xyy.z);
	float3 rgb= convert_xyz_to_rgb(xyz);
	return rgb;	
}
	
// Convert from rgb to xyy
float3 convert_rgb_to_xyy(float3 rgb)
{
	float3 xyz= convert_rgb_to_xyz(rgb);
	float3 xyy;
	//to xyy
	xyy.x= xyz.x/(xyz.x + xyz.y + xyz.z);
	xyy.y= xyz.y;
	xyy.z= xyz.y/(xyz.x + xyz.y + xyz.z);
	return xyy;
}


// Specialized routine for smoothly fading out particles.  Maps
//		[0, black_point] to 0
//		[black_point, mid_point] to [0, mid_point] linearly
//		[mid_point, 1] to [mid_point, 1] by identity
// where mid_point is halfway between black_point and 1
//
//		|                   **
//		|                 **
//		|               **
//		|             **
//		|            *
//		|           *
//		|          *
//		|         *
//		|        *
//		|       *
//		|*******_____________
//      0      bp    mp      1
float apply_black_point(float black_point, float alpha)
{
	float mid_point= (black_point+1.0f)/2.0f;
	return mid_point*saturate((alpha-black_point)/(mid_point-black_point)) 
		+ saturate(alpha-mid_point);	// faster than a branch
}

// safe normalize function that returns 0 for zero length vectors (360 normalize does this by default)
float3 safe_normalize(in float3 v)
{
#ifdef XENON
	return normalize(v);
#else
	float l = dot(v,v);
	if (l > 0)
	{
		return v * rsqrt(l);
	} else
	{
		return 0;
	}
#endif
}

// safe sqrt function that returns 0 for inputs that are <= 0
float safe_sqrt(in float x)
{
#ifdef XENON
	return sqrt(x);
#else
	return (x <= 0) ? 0 : sqrt(x);
#endif
}

float2 safe_sqrt(in float2 x)
{
#ifdef XENON
	return sqrt(x);
#else
	return (x <= 0) ? 0 : sqrt(x);
#endif
}

float3 safe_sqrt(in float3 x)
{
#ifdef XENON
	return sqrt(x);
#else
	return (x <= 0) ? 0 : sqrt(x);
#endif
}

float4 safe_sqrt(in float4 x)
{
#ifdef XENON
	return sqrt(x);
#else
	return (x <= 0) ? 0 : sqrt(x);
#endif
}

// safe pow function that always returns 1 when y is 0
#if DX_VERSION == 11
float safe_pow(float x, float y)
{
	if (y == 0)
	{
		return 1;
	} else
	{
		return pow(x, y);
	}
}
#else
float safe_pow(float x, float y)
{
	return pow(x, y);
}
#endif

#endif //ifndef _UTILITIES_FX_