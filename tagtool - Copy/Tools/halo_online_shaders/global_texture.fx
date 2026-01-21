#ifndef _GLOBAL_TEXTURE_FX_
#define _GLOBAL_TEXTURE_FX_

// Texture sampling and struct functions so that texture/sampler pairs can be treated the same for D3D9 and D3D11

#if DX_VERSION == 9

typedef sampler2D texture_sampler_2d;
typedef sampler3D texture_sampler_3d;
typedef samplerCUBE texture_sampler_cube;
typedef sampler2D texture_sampler_2d_array;

float4 sample2D(in texture_sampler_2d s, in float2 uv)
{
	return tex2D(s, uv);
}

float4 sample2Dlod(in texture_sampler_2d s, in float2 uv, in float lod)
{
	return tex2Dlod(s, float4(uv, 0, lod));
}

#ifdef xenon

float4 sample2Doffset(in texture_sampler_2d s, in float2 uv, in int2 offset)
{
	int offx = offset.x;
	int offy = offset.y;
	float4 v;
	asm
	{
		tfetch2D v, uv, s, OffsetX = offx, OffsetY = offy
	};
	return v;
}

#endif // xenon


float4 sample3D(in texture_sampler_3d s, in float3 uvw)
{
	return tex3D(s, uvw);
}

float4 sample3Dlod(in texture_sampler_3d s, in float3 uvw, in float lod)
{
	return tex3Dlod(s, float4(uvw, lod));
}

float4 sampleCUBE(in texture_sampler_cube s, in float3 v)
{
	return texCUBE(s, v);
}

float4 sampleCUBElod(in texture_sampler_cube s, in float3 v, in float lod)
{
	return texCUBElod(s, float4(v, lod));
}

#elif DX_VERSION == 11

struct texture_sampler_2d
{
	sampler s;
	texture2D t;
};

struct texture_sampler_comparison_2d 
{
	SamplerComparisonState s;
	texture2D t;
};

struct texture_sampler_3d
{
	sampler s;
	texture3D t;
};

struct texture_sampler_cube
{
	sampler s;
	TextureCube t;
};

struct texture_sampler_2d_array
{
	sampler s;
	Texture2DArray t;
};

float4 sample2D(in texture_sampler_2d s, in float2 uv)
{
	return s.t.Sample(s.s, uv);
}

float4 sampleCmp2D(in texture_sampler_comparison_2d s, in float2 uv, in float compareValue)
{
	return s.t.SampleCmp(s.s, uv, compareValue);
}

float4 sample2Dlod(in texture_sampler_2d s, in float2 uv, in float lod)
{
	return s.t.SampleLevel(s.s, uv, lod);
}

float4 sample2Doffset(in texture_sampler_2d s, in float2 uv, in int2 offset)
{
	return s.t.Sample(s.s, uv, offset);
}

float4 sampleCmp2Doffset(in texture_sampler_comparison_2d s, in float2 uv, in float compareValue, in int2 offset)
{
	return s.t.SampleCmp(s.s, uv, compareValue, offset);
}

float4 sample3D(in texture_sampler_3d s, in float3 uvw)
{
	return s.t.Sample(s.s, uvw);
}

float4 sample3Dlod(in texture_sampler_3d s, in float3 uvw, in float lod)
{
	return s.t.SampleLevel(s.s, uvw, lod);
}

float4 sampleCUBE(in texture_sampler_cube s, in float3 v)
{
	return s.t.Sample(s.s, v);
}

float4 sampleCUBElod(in texture_sampler_cube s, in float3 v, in float lod)
{
	return s.t.SampleLevel(s.s, v, lod);
}

// convert normalized 3d texture z coordinate to texture array coordinate
float4 convert_3d_texture_coord_to_array_texture(in texture_sampler_2d_array t, in float3 uvw)
{
	uint width, height, elements;
	t.t.GetDimensions(width, height, elements);
	uvw.z = (frac(uvw.z) * elements);
	float next_z = (uvw.z >= (elements - 1)) ? 0 : (uvw.z + 1);
	return float4(uvw, next_z);
}

#endif

#endif
