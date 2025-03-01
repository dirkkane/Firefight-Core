#include "clip_plane.fx"

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
void active_camo_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float4 texcoord : TEXCOORD1,
	out float4 perturb : TEXCOORD0)
{
	perturb.x= dot(vertex.normal, Camera_Left);
   	perturb.y= dot(vertex.normal, Camera_Up);
   	
   	// Spherical texture projection 
   	perturb.z= atan2((vertex.position.x - 0.5f) * Position_Compression_Scale.x, (vertex.position.y - 0.5f) * Position_Compression_Scale.y);
   	float aspect= Position_Compression_Scale.z / length(Position_Compression_Scale.xy);
   	perturb.w= acos(vertex.position.z - 0.5f) * aspect;
   	
	float4 local_to_world_transform[3];
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);

   	texcoord.xy= vertex.texcoord;
   	texcoord.z= 0.0f;
   	texcoord.w= length(vertex.position - Camera_Position);
	
	CALC_CLIP(position);
}

PARAM_SAMPLER_2D(active_camo_distortion_texture);

accum_pixel active_camo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	CLIP_INPUT
	in float4 texcoord : TEXCOORD1,
	in float4 perturb : TEXCOORD0) : SV_Target
{
	float2 uv= float2((screen_position.x + 0.5f) / texture_size.x, (screen_position.y + 0.5f) / texture_size.y);
	
	// ###kuttas $TODO: expose these "magic" constants to artists for direct control via the tag
	float2 uvdelta;
	
	uvdelta= k_ps_active_camo_factor.yz * perturb.xy * 0.25f * float2(1.0f/16.0f, 1.0f/9.0f);
	//uvdelta+= sample2D(active_camo_distortion_texture, perturb.zw * float2(4.0f, 4.0f)).xy * float2(0.1f, 0.1f);
	
	// Perspective correction so we don't distort too much in the distance
	// (and clamp the amount we distort in the foreground too)
	uv.xy+= uvdelta / max(0.5f, texcoord.w);
	
	// ###kuttas: matt lee's awesome hack for tiling breaks this because the render bounds are no longer separate
	//uv.xy= clamp(uv.xy, k_ps_distort_bounds.xy, k_ps_distort_bounds.zw);
	
	// HDR texture is currently not used
	//float4 hdr_color= sample2D(scene_hdr_texture, uv.xy);
	
	float4 ldr_color= sample2D(scene_ldr_texture, uv.xy);
	float3 true_scene_color= ldr_color.rgb;
	float4 result= float4(true_scene_color, k_ps_active_camo_factor.x);
	float4 ssr = 0.0f;

	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(result, false, false
#ifdef SSR_ENABLE
		, ssr
#endif
	);
}
