#line 2 "source\rasterizer\hlsl\lens_flare.hlsl"

#define POSTPROCESS_COLOR
#define POSTPROCESS_USE_CUSTOM_VERTEX_SHADER

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "lens_flare_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

#define CENTER		center_rotation.xy
#define ROTATION	center_rotation.z

#define FLARE_ORIGIN origin_and_offset_bounds.xy
#define OFFSET_MIN origin_and_offset_bounds.z
#define OFFSET_MAX origin_and_offset_bounds.w

void default_vs(
	vertex_type IN,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0)
{
	float sin_theta;
	float cos_theta;
	sincos(ROTATION, sin_theta, cos_theta);

	float2 scaledPosition = IN.position.xy * flare_scale.xy;
	position.x = dot(float2( cos_theta, sin_theta), scaledPosition);
	position.y = dot(float2(-sin_theta, cos_theta), scaledPosition);
	position.xy *= flare_scale.zw;
	position.xy = position.x * transformed_axes.xy + position.y * transformed_axes.zw;

	float2 centerOffset = CENTER;
	
	[branch]
	if (OFFSET_MIN > 0 || OFFSET_MAX > 0)
	{
		float2 offsetFromFlare = centerOffset - FLARE_ORIGIN;
		float offsetLength = length(offsetFromFlare);
		offsetFromFlare *= clamp(offsetLength, OFFSET_MIN, OFFSET_MAX) / offsetLength;
		centerOffset = FLARE_ORIGIN + offsetFromFlare;
	}
	
	position.xy += centerOffset;

//	if (mirrorReflectionAcrossFlare)
//	{
//		position.xy += 2.0 * (FLARE_ORIGIN - position.xy);
//	}

	position.zw=	1.0f;
	texcoord=		IN.texcoord;
}

//void default_vs(
//	vertex_type IN,
//	out float4 position : POSITION,
//	out float2 texcoord : TEXCOORD0)
//{
//	float sin_theta= sin(center_rotation.z);
//	float cos_theta= cos(center_rotation.z);
//
//	position.y= dot(float2(cos_theta, -sin_theta),	IN.position.xy);
//	position.x= dot(float2(sin_theta, cos_theta),	IN.position.xy);
//	position.xy= position.xy * flare_scale.xy * flare_scale.z + center_rotation.xy;
//
//	position.zw=	1.0f;
//	texcoord=		IN.texcoord;
//}


float4 default_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float2 texcoord : TEXCOORD0) : SV_Target
{
	//return float4(1.0f, 0.0f, 0.0f, 1.0f);

 	float4 color= sample2D(source_sampler, texcoord);
	float color_to_nth = pow(color.g, modulation_factor.y); // gamma-enhanced monochrome channel to generate 'hot' white centers in new flares
	float4 outColor = (color_to_nth * modulation_factor.x) + (color * tint_color); // color tinted external areas for cool exterior

 	float brightness = tint_color.a * ILLUM_EXPOSURE * scale.r * modulation_factor.z;
 	return outColor * brightness;
}
