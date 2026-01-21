// hack so we can reuse the same shadow entry points that the shader render method definition uses by defining one of it's category options

void calc_bumpmap_ps(
	in float2 texcoord,
	out float3 bump)
{
	bump= float3(0.0f, 0.0f, 1.0f);
}

void calc_alpha_test_ps(
	in float2 texcoord,
	out float output_alpha)
{
	output_alpha = 1.0f;
}

#include "shadow_generate.fx"
