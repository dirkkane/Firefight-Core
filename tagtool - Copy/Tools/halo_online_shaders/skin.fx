#ifndef __GLASS_FX_H__
#define __GLASS_FX_H__
#pragma once
/*
GLASS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
1/16/2007 1:08:55 PM (haochen)
	glass render method
*/

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"
#include "render_target.fx"
#include "blend.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"
#include "shadow_generate.fx"
#include "clip_plane.fx"
#include "dynamic_light_clip.fx"

void albedo_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0)
{
	float4 local_to_world_transform[3];
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	// normal, tangent and binormal are all in world space
	texcoord= vertex.texcoord;
	
	CALC_CLIP(position);
}

float4 albedo_ps(
	SCREEN_POSITION_INPUT(screen_position),
	CLIP_INPUT
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float3 fragment_to_camera_world : TEXCOORD4) : SV_Target0
{
	float4 albedo= float4(1.0f, 1.0f, 1.0f, 0.0f);
	return albedo;
}

void static_per_pixel_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD3,
	out float3 binormal : TEXCOORD4,
	out float3 tangent : TEXCOORD5,
	out float2 lightmap_texcoord : TEXCOORD6,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	normal= vertex.normal;
	texcoord= vertex.texcoord;
	lightmap_texcoord= lightmap.texcoord;
	tangent= vertex.tangent;
	binormal= vertex.binormal;

	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	CALC_CLIP(position);
}

accum_pixel static_per_pixel_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
	in float2 texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD3,
	in float3 binormal : TEXCOORD4,
	in float3 tangent : TEXCOORD5,
	in float2 lightmap_texcoord : TEXCOORD6,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1
	) : SV_Target
{
	float4 out_color= float4(1.0f, 1.0f, 1.0f, 1.0f);		
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false);
}

void dynamic_light_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
#if DX_VERSION == 11
	out s_dynamic_light_clip_distance clip_distance,
#endif	
	out float2 texcoord : TEXCOORD0,
	out float3 normal : TEXCOORD1,
	out float3 binormal : TEXCOORD2,
	out float3 tangent : TEXCOORD3,
	out float4 fragment_position_shadow : TEXCOORD5)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	normal= vertex.normal;
	texcoord= vertex.texcoord;
	tangent= vertex.tangent;
	binormal= vertex.binormal;

	fragment_position_shadow= mul(float4(vertex.position, 1.0f), Shadow_Projection);
	
#if DX_VERSION == 11
	clip_distance = calc_dynamic_light_clip_distance(position);
#endif
}

accum_pixel dynamic_light_ps(
	SCREEN_POSITION_INPUT(fragment_position),
#if DX_VERSION == 11
	in s_dynamic_light_clip_distance clip_distance,
#endif	
	in float2 original_texcoord : TEXCOORD0,
	in float3 normal : TEXCOORD1,
	in float3 binormal : TEXCOORD2,
	in float3 tangent : TEXCOORD3,
	in float4 fragment_position_shadow : TEXCOORD5)
{
	float4 out_color= float4(1.0f, 1.0f, 1.0f, 1.0f);		
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false);
}

void static_prt_ambient_vs(
	in vertex_type vertex,
	CLIP_OUTPUT
	out float4 position : SV_Position)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	CALC_CLIP(position);
}

void static_prt_linear_vs(
	in vertex_type vertex,
	CLIP_OUTPUT
	out float4 position : SV_Position)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	CALC_CLIP(position);
}

void static_prt_quadratic_vs(
	in vertex_type vertex,
	CLIP_OUTPUT
	out float4 position : SV_Position)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	CALC_CLIP(position);
}

accum_pixel static_prt_ps(
	CLIP_INPUT
	SCREEN_POSITION_INPUT(fragment_position))	
{
	float4 out_color= float4(1.0f, 1.0f, 1.0f, 1.0f);
	return convert_to_render_target(out_color, true, true);
}


void static_sh_vs(
	in vertex_type vertex,
	CLIP_OUTPUT
	out float4 position : SV_Position)
{
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	CALC_CLIP(position);
}

accum_pixel static_sh_ps(
	CLIP_INPUT
	SCREEN_POSITION_INPUT(fragment_position))
{
	float4 out_color= float4(1.0f, 1.0f, 1.0f, 1.0f);
	return convert_to_render_target(out_color, true, true);
}

#endif //__GLASS_FX_H__
