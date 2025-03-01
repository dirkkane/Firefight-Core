#include "entry.fx"

PARAM_SAMPLER_2D(alpha_test_map);
PARAM(float4, alpha_test_map_xform);

void calc_alpha_test_off_ps(
	in float2 texcoord,
	out float output_alpha)
{
	output_alpha = 1.0;
}




void calc_alpha_test_on_ps(
	in float2 texcoord,
	out float output_alpha)
{
	float4 base= sample2D(alpha_test_map, transform_texcoord(texcoord, alpha_test_map_xform));
	float alpha= base.a;
	output_alpha= alpha;

#if ENTRY_POINT(entry_point) == ENTRY_POINT_shadow_generate

	clip(alpha-0.5f);			// always on for shadow

#else
    if(base.r == 1.0 && base.g == 0.0 && base.b == 1.0 && base.a > 0.72 && base.a < 0.73) { discard; }
	
	#ifdef APPLY_FIXES
		clip(alpha-0.5f); // always on
	#else
		#ifdef NO_ALPHA_TO_COVERAGE
			clip(alpha-0.5f);
		#endif
	#endif

//#ifdef NO_ALPHA_TO_COVERAGE
//	clip(alpha-0.5f);			// have to clip pixels ourselves
//#elif (DX_VERSION == 11)
//	
//	// we don't use alpha to coverage in D3D11, so we need to clip when alpha to coverage would have been enabled on Xenon
//	// - this does the same test that is done in c_render_method_shader::postprocess_shader
//	
//	#define IS_NOT_ATOC_MATERIAL(material) IS_NOT_ATOC_MATERIAL_##material
//	#define IS_NOT_ATOC_MATERIAL_cook_torrance 1
//	#define IS_NOT_ATOC_MATERIAL_two_lobe_phong 1
//	#define IS_NOT_ATOC_MATERIAL_default_skin 1
//	#define IS_NOT_ATOC_MATERIAL_glass 1
//	#define IS_NOT_ATOC_MATERIAL_organism 1
//	
//	#if IS_NOT_ATOC_MATERIAL(material_type)	!= 1
//		clip(alpha-0.5f);
//	#endif
//#endif

#endif
}

void calc_alpha_test_from_albedo_ps(
	in float2 texcoord,
	out float output_alpha)
{
    output_alpha = 1.0;
}

// Post albedo

void calc_alpha_test_off_ps(
	in float2 texcoord,
	inout float output_alpha,
    in float albedo_alpha)
{
}

void calc_alpha_test_on_ps(
	in float2 texcoord,
	inout float output_alpha,
    in float albedo_alpha)
{
    calc_alpha_test_on_ps(texcoord, output_alpha);
}

void calc_alpha_test_from_albedo_ps(
	in float2 texcoord,
	inout float output_alpha,
    in float albedo_alpha)
{
    clip(albedo_alpha - 0.5f);
    output_alpha = albedo_alpha;
}