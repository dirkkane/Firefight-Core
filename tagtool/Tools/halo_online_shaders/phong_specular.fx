#ifndef _PHONG_SPECULAR_H_
#define _PHONG_SPECULAR_H_

#include "spherical_harmonics.fx"

float analytical_Phong_specular(in float3 L,in float3 R,float fPower)
{
	float fRDotL=saturate(dot(R,L));

	return pow(saturate(fRDotL),fPower)*(1+fPower);
}

float analytical_Phong_specular(in float3 L,in float3 N,in float3 V,float fPower)
{
	float3 R=-reflect(V,N);

	return analytical_Phong_specular(L,R,fPower);
}

void vmf_phong_specular_linear(in float3 vReflect,in float4 Y[4],float fRoughness,in float3 specular_color_tint,out float3 radiance)
{
    // Thanks MS compiler, I have to do this to avoid compiler crash.
	float2 brdf_zonal=sample1D(g_sample_vmf_1d,fRoughness*1.000001);

	float3 dominant_lighting;
    {
	    float2 dominant_coord=float2(dot(Y[0].xyz, vReflect)*0.5+0.5,convertBandwidth2TextureCoord(Y[1].w));

	    float2 dominant_band=sample2D(g_sample_vmf_phong_specular,dominant_coord).rg;

	    dominant_lighting=(sh_dc_square+dot(dominant_band,brdf_zonal))*Y[1].xyz;
	}

	float3 fill_lighting;
	{
	    float2 fill_coord=float2(dot(Y[2].xyz, vReflect)*0.5+0.5,convertBandwidth2TextureCoord(Y[3].w));

	    float2 fill_band=sample2D(g_sample_vmf_phong_specular,fill_coord).rg;

	    fill_lighting=(sh_dc_square+dot(fill_band,brdf_zonal))*Y[3].xyz;
	}


	float3 color = fill_lighting+dominant_lighting;

	radiance=max(0,color)*specular_color_tint;
}


void vmf_phong_specular_linear(in float3 vSurfNormal_in,in float3 vViewDir,in float4 Y[4],float fRoughness,in float3 specular_color,out float3 radiance)
{
	float3 vReflect=-reflect(vViewDir,vSurfNormal_in);
	vmf_phong_specular_linear(vReflect,Y,fRoughness,specular_color,radiance);
}



#endif //_PHONG_SPECULAR_H_