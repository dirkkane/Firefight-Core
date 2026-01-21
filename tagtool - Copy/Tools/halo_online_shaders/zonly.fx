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

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"
#include "albedo_pass.fx"

void z_only_vs(
	in vertex_type vertex,
	out float4 position : POSITION)
{
   float4 local_to_world_transform[3];

   position = float4(0, 0, 0, 1);
   always_local_to_view(vertex, local_to_world_transform, position, true);
}

albedo_pixel z_only_ps()
{
	float3 bump_normal = float3(0, 0, 0);
	float4 albedo = float4(0, 0, 0, 1);
	
	return convert_to_albedo_target(albedo, bump_normal, 0.f, float3(0, 0, 0));
}