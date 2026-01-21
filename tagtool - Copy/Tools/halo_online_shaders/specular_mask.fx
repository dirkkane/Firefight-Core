void calc_specular_mask_no_specular_mask_ps(
	in float2 texcoord,
	in float in_specular_mask,
	out float3 specular_mask)
{
	specular_mask= 1.0f;
}

void calc_specular_mask_from_diffuse_ps(
	in float2 texcoord,
	in float in_specular_mask,
	out float3 specular_mask)
{
	specular_mask= in_specular_mask;
}

PARAM_SAMPLER_2D(specular_mask_texture);
PARAM(float4, specular_mask_texture_xform);

void calc_specular_mask_texture_ps(
	in float2 texcoord,
	in float in_specular_mask,
	out float3 specular_mask)
{
	float4 material= sample2D(specular_mask_texture, texcoord*specular_mask_texture_xform.xy + specular_mask_texture_xform.zw);
	specular_mask= material.a;
}

void calc_specular_mask_color_texture_ps(
	in float2 texcoord,
	in float in_specular_mask,
	out float3 specular_mask)
{
	specular_mask = sample2D(specular_mask_texture, texcoord*specular_mask_texture_xform.xy + specular_mask_texture_xform.zw).rgb;
}

void calc_specular_mask_mult_texture_ps(
	in float2 texcoord,
	in float in_specular_mask,
	out float3 specular_mask)
{
	float4 material= tex2D(specular_mask_texture, texcoord*specular_mask_texture_xform.xy + specular_mask_texture_xform.zw);
	specular_mask= in_specular_mask*material.a;
}