
#define APPLY_OVERLAYS(color, texcoord, view_dot_normal) { color= calc_overlay_ps(color, texcoord); color= calc_edge_fade_ps(color, view_dot_normal); }


float3 calc_overlay_none_ps(float3 color, float2 texcoord)
{
	return color;
}


PARAM_SAMPLER_2D(overlay_map);
PARAM(float4, overlay_map_xform);
PARAM(float4, overlay_tint);
PARAM(float, overlay_intensity);

float3 calc_overlay_additive_ps(float3 color, float2 texcoord)
{
	return color + (overlay_tint.rgb * overlay_intensity) * sample2D(overlay_map, transform_texcoord(texcoord, overlay_map_xform)).rgb;
}


PARAM_SAMPLER_2D(overlay_detail_map);
PARAM(float4, overlay_detail_map_xform);


float3 calc_overlay_additive_detail_ps(float3 color, float2 texcoord)
{
	float4 overlay=			sample2D(overlay_map,   transform_texcoord(texcoord, overlay_map_xform));
	float4 overlay_detail=	sample2D(overlay_detail_map, transform_texcoord(texcoord, overlay_detail_map_xform));

	float3 overlay_color=	overlay.rgb * overlay_detail.rgb * DETAIL_MULTIPLIER * overlay_tint.rgb * overlay_intensity;

	return color + overlay_color;
}


float3 calc_overlay_multiply_ps(float3 color, float2 texcoord)
{
	float4 overlay=			sample2D(overlay_map,   transform_texcoord(texcoord, overlay_map_xform));
	float3 overlay_color=	overlay.rgb * overlay_tint.rgb * overlay_intensity;

	return color * overlay_color;
}

PARAM_SAMPLER_2D(overlay_multiply_map);
PARAM(float4, overlay_multiply_map_xform);

float3 calc_overlay_multiply_and_additive_detail_ps(float3 color, float2 texcoord)
{
	float4 overlay=			sample2D(overlay_multiply_map,   transform_texcoord(texcoord, overlay_multiply_map_xform));
	float3 overlay_color=	overlay.rgb;

	return calc_overlay_additive_detail_ps(color * overlay_color, texcoord);
}







float3 calc_edge_fade_none_ps(float3 color, float view_dot_normal)
{
	return color;
}

PARAM(float3, edge_fade_center_tint);
PARAM(float3, edge_fade_edge_tint);
PARAM(float, edge_fade_power);

float3 calc_edge_fade_simple_ps(float3 color, float view_dot_normal)
{
#ifdef APPLY_FIXES
	float fade_alpha= pow(abs(view_dot_normal), edge_fade_power);
#else
    float fade_alpha = pow(view_dot_normal, edge_fade_power);
#endif
	return color * lerp(edge_fade_edge_tint, edge_fade_center_tint, fade_alpha);
}
