
PARAM_SAMPLER_2D(multiply_map);
PARAM(float4, multiply_map_xform);

void calc_alpha_test_multiply_map_ps(
	in float2 texcoord,
	out float output_alpha)
{

	float4 alpha_test_layer=	sample2D(alpha_test_map,	transform_texcoord(texcoord,	alpha_test_map_xform));
	float4 multiply_layer=		sample2D(multiply_map,		transform_texcoord(texcoord,	multiply_map_xform));

	float alpha=		alpha_test_layer.a * multiply_layer.a;

	output_alpha= alpha;
	// float alpha= sample2D(alpha_test_map, transform_texcoord(texcoord, alpha_test_map_xform)).a;
	clip(alpha-0.5f);
}
