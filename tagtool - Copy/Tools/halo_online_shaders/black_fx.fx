#ifdef disable_register_reorder
// magic pragma given to us by the DX10 team
// to disable the register reordering pass that was
// causing a lot of pain on the PC side of the compiler
// with this pragma we get a massive speedup on compile times
// on the PC side
#pragma ruledisable 0x0a0c0101
#endif // #ifdef disable_register_reorder

#include "global.fx"
#include "hlsl_constant_mapping.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"

#include "albedo.fx"
#include "parallax.fx"
#include "bump_mapping.fx"
#include "self_illumination.fx"
#include "specular_mask.fx"
#include "material_models.fx"
#include "environment_mapping.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"
#include "albedo_pass.fx"
#include "blend.fx"
#include "clip_plane.fx"
#include "stipple.fx"


#define calc_specular_mask_ps
#define calc_material_material_type_ps
#define calc_environment_map_envmap_type_ps
#define prt_quadratic

#ifndef APPLY_OVERLAYS
#define APPLY_OVERLAYS(color, texcoord, view_dot_normal)
#endif // APPLY_OVERLAYS

PARAM_SAMPLER_2D(radiance_map);

PARAM_SAMPLER_2D(dynamic_light_gel_texture);
//float4 dynamic_light_gel_texture_xform;		// no way to extern this, so I replace it with p_dynamic_light_gel_xform which is aliased on p_lighting_constant_4


float3 get_constant_analytical_light_dir_vs()
{
 	return -normalize(v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz);		// ###ctchou $PERF : pass this in as a constant
}


void get_albedo_and_normal(out float3 bump_normal, out float4 albedo, in float2 texcoord, in float3x3 tangent_frame, in float3 fragment_to_camera_world, in float2 fragment_position)
{
	bump_normal= 0;
	albedo= 0;
}

void albedo_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);
	
	float3 extinction;
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	CALC_CLIP(position);
}

albedo_pixel albedo_ps(
	SCREEN_POSITION_INPUT(fragment_position),
	CLIP_INPUT
	in float3 inscatter : COLOR1)
{
    float3 color= inscatter * BLEND_FOG_INSCATTER_SCALE * g_exposure.rrr;
	return convert_to_albedo_target(
		float4(color, 0), 
		float4(0, 0, 0, 0),
		0, 
		float3(0, 0, 0));
}

#if DX_VERSION == 11

void stipple_vs(
	in vertex_type vertex,
	out float4 position : SV_Position,
	CLIP_OUTPUT
	uniform float dummy = 0)
{
	float4 local_to_world_transform[3];
		
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, position);

	CALC_CLIP(position);
}

float4 stipple_ps(
	SCREEN_POSITION_INPUT(screen_position),
	CLIP_INPUT
	uniform float dummy = 0) : SV_Target
{
	stipple_test(screen_position);
	return 0;
}

#endif
