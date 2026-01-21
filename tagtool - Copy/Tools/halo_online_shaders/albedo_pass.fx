


struct albedo_pixel
{
	float4 albedo_specmask : SV_Target0;		// albedo color (RGB) + specular mask (A)
	float4 normal : SV_Target1;					// normal (XYZ)
#if defined(pc) && (DX_VERSION == 9)
	float4 pos_w : SV_Target2;
	//#ifdef APPLY_FIXES
	//float4 geo_normal : SV_Target3; 			// geometry normal (XYZ)
	//#endif
#endif	
};


#if defined(pc) && (DX_VERSION == 9)

float3 d3dSRGBGamma(float3 Clinear)
{
	return (Clinear <= .0031308f) ? (12.92f * Clinear) : (1.055f * pow(Clinear, 1.f/2.4f) ) - 0.055f;
}

#endif

albedo_pixel convert_to_albedo_target(in float4 albedo, in float3 normal, in float pos_w, in float3 geo_normal)
{
	albedo_pixel result;
#if defined(pc) && (DX_VERSION == 9)
	result.albedo_specmask.xyz= d3dSRGBGamma(albedo.xyz);
	result.albedo_specmask.w=   albedo.w;
#else
	result.albedo_specmask= albedo;
#endif
	result.normal.xyz= normal * 0.5f + 0.5f;		// bias and offset to all positive
	result.normal.w= albedo.w;

#if defined(pc) && (DX_VERSION == 9)
	result.pos_w = pos_w;
	//#ifdef APPLY_FIXES
	//result.geo_normal.xyz = geo_normal * 0.5f + 0.5f;
	//result.geo_normal.w = albedo.w;
	//#endif
#endif	
	
	return result;
}

albedo_pixel convert_to_albedo_target_no_srgb(in float4 albedo, in float3 normal, in float pos_w, in float3 geo_normal)
{
	albedo_pixel result;

	result.albedo_specmask= albedo;

	result.normal.xyz= normal * 0.5f + 0.5f;		// bias and offset to all positive
	result.normal.w= albedo.w;

#if defined(pc) && (DX_VERSION == 9)
	result.pos_w = pos_w;
	//#ifdef APPLY_FIXES
	//result.geo_normal.xyz = geo_normal * 0.5f + 0.5f;
	//result.geo_normal.w = albedo.w;
	//#endif
#endif	
	
	return result;
}


