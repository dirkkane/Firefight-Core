

//
// WATERFALL
//

PARAM_SAMPLER_2D(waterfall_base_mask);
PARAM(float4, waterfall_base_mask_xform);
PARAM_SAMPLER_2D(waterfall_layer0);
PARAM(float4, waterfall_layer0_xform);
PARAM_SAMPLER_2D(waterfall_layer1);
PARAM(float4, waterfall_layer1_xform);
PARAM_SAMPLER_2D(waterfall_layer2);
PARAM(float4, waterfall_layer2_xform);

PARAM(float, transparency_frothy_weight);
PARAM(float, transparency_base_weight);
PARAM(float, transparency_bias);

void calc_albedo_waterfall_ps(
	in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc,
	in float3 view_dir,
	in float2 vPos)
{
	float4 base_mask=		sample2D(waterfall_base_mask,	transform_texcoord(texcoord,	waterfall_base_mask_xform));
	float4 layer0=			sample2D(waterfall_layer0,		transform_texcoord(texcoord,	waterfall_layer0_xform));
	float4 layer1=			sample2D(waterfall_layer1,		transform_texcoord(texcoord,	waterfall_layer1_xform));
	float4 layer2=			sample2D(waterfall_layer2,		transform_texcoord(texcoord,	waterfall_layer2_xform));

/*
	float4 layer01=			lerp(layer0, layer1, layer1.w);														// alpha blend layer 1 on top of layer 0
	float4 layer012=		lerp(layer01, layer2, layer2.w);													// alpha blend layer 2 on top of that
	albedo.rgb=				layer012.rgb * base_mask.rgb;														// multiply base color on top
	albedo.w=				base_mask.w * clamp(layer01.a - 0.3f);																		// transparency comes only from base mask
*/

	float4 frothy_color=		(layer0 * layer1 * layer2);
	float frothy_transparency=	layer1.a + layer0.a + layer2.a;

	albedo.rgb=		frothy_color.rgb * base_mask.rgb;
	albedo.a=		clamp(transparency_frothy_weight*frothy_transparency + transparency_base_weight*base_mask.a + transparency_bias, 0.0f, 1.0f);
	
	apply_pc_albedo_modifier(albedo, normal);
}


//

