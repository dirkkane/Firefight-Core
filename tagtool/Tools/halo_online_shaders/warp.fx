

PARAM_SAMPLER_2D(warp_map);
PARAM(float4, warp_map_xform);
PARAM(float, warp_amount_x);
PARAM(float, warp_amount_y);


void calc_warp_from_texture_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	parallax_texcoord= texcoord + sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy * float2(warp_amount_x, warp_amount_y);
}
