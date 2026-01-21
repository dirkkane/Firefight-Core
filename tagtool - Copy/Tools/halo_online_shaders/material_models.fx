#include "utilities.fx"
#include "spherical_harmonics.fx"
#include "simple_lights.fx"


// enumerate all material models
#define MATERIAL_TYPE(material) MATERIAL_TYPE_##material
#define MATERIAL_TYPE_diffuse_only 0
#define MATERIAL_TYPE_cook_torrance 1
#define MATERIAL_TYPE_two_lobe_phong 2
#define MATERIAL_TYPE_foliage 3
#define MATERIAL_TYPE_none 4
#define MATERIAL_TYPE_glass 5
#define MATERIAL_TYPE_organism 6
#define MATERIAL_TYPE_single_lobe_phong 7
#define MATERIAL_TYPE_cook_torrance_custom_cube 8
#define MATERIAL_TYPE_cook_torrance_pbr_maps 9
#define MATERIAL_TYPE_cook_torrance_two_color_spec_tint 10
#define MATERIAL_TYPE_car_paint 11
#define MATERIAL_TYPE_two_lobe_phong_tint_map 12
#define MATERIAL_TYPE_hair 13
#define MATERIAL_TYPE_custom_specular 14
#define MATERIAL_TYPE_cook_torrance_reach 15
#define MATERIAL_TYPE_two_lobe_phong_reach 16


// all material models must define these 4 functions
#define CALC_MATERIAL(material) calc_material_##material##_ps
#define CALC_MATERIAL_SPECULAR_PARAMETERS(material) calc_material_specular_parameters_##material##_ps
#define CALC_MATERIAL_ANALYTIC_SPECULAR(material) calc_material_analytic_specular_##material##_ps

#define GET_MATERIAL_SPECULAR_POWER(material) get_material_##material##_specular_power
#define GET_MATERIAL_ANALYTICAL_SPECULAR_MULTIPLIER(material) get_analytical_specular_multiplier_##material##_ps
#define GET_MATERIAL_DIFFUSE_MULTIPLIER(material) get_diffuse_multiplier_##material##_ps

/*

Material model parameters:

// local directions
	in float3 view_dir,							// direction towards camera
	in float3 surface_normal,					// surface normal, calculated by calc_bump_ps	
	in float3 view_reflect_dir,					// view_dir reflected about surface_normal

// incident lighting
	in float4 sh_lighting_coefficients[10],		// describes incident area light in spherical harmonics
	in float3 analytical_light_dir,				// analytical light direction
	in float3 analytical_light_intensity,		// analytical light intensity

// material properties	
	in float3 diffuse_reflectance,				// diffuse reflectance, calculated by calc_diffuse_ps
	in float3  specular_mask,					// specular mask (multiplies specular albedo)
	in float2 texcoord,							// texture coordinates (if needed for looking up material property textures)

// output environment map parameters
	out float4 envmap_specular_reflectance_and_roughness,		// apparent specular reflectance, including metallic/plastic effects, fresnel, specular mask, etc.   roughness in w channel
	out float3 envmap_area_specular_only,						// pristine area specular result (not scaled or added with analytical) - for use by envmap
	
// output light
	out float3 specular_radiance,				// the specularly reflected light as calculated by the material model
	inout float3 diffuse_radiance)				// the diffusely reflected light as calculated by the material model

*/

//parameters common to all material models
PARAM(float,	diffuse_coefficient);						//how much to scale diffuse by
PARAM(float,	specular_coefficient);						//how much to scale specular by
PARAM(float,	area_specular_contribution);					//scale the area sh contribution
PARAM(float,	analytical_specular_contribution);					//scale the analytical sh contribution
PARAM(float,	environment_map_specular_contribution);			//scale the environment map contribution
PARAM_SAMPLER_2D(material_texture);					//a texture that stores spatially varient parameters
PARAM(float4,	material_texture_xform);				//texture matrix
PARAM(bool, use_material_texture);
PARAM(bool, order3_area_specular);
PARAM(bool, no_dynamic_lights);


//*****************************************************************************
// diffuse only
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_diffuse_only
#include "diffuse_only.fx"
#endif

//*****************************************************************************
// cook torrance
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance reach
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_reach
#include "cook_torrance_reach.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with custom cube texture
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_custom_cube
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with custom scrolling cube mask texture
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_scrolling_cube_mask
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with custom scrolling cube texture
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_scrolling_cube
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with custom rim fresnel texture
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_rim_fresnel
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with albedo tint
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_from_albedo
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with "pbr" maps
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_pbr_maps
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// cook torrance with blended two colors specular tint
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_cook_torrance_two_color_spec_tint
#include "cook_torrance.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// two lobe phong model
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_two_lobe_phong
#include "two_lobe_phong.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// two lobe phong reach model
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_two_lobe_phong_reach
#include "two_lobe_phong_reach.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// foliage
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_foliage
#include "foliage_material.fx"
#endif

//*****************************************************************************
// organism
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_organism
#include "organism_material.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// none
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_none
#include "material_model_none.fx"
#endif

//*****************************************************************************
// glass
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_glass
#include "glass_material.fx"
#define BLEND_FRESNEL 1.0
#define NO_ALPHA_TO_COVERAGE
#endif

#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_single_lobe_phong
#include "single_lobe_phong.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// car paint
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_car_paint
#include "car_paint.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// two lobe phong model with specular tint colors got from special texture
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_two_lobe_phong_tint_map
#include "two_lobe_phong.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// hair
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_hair
#include "hair_material.fx"
#define NO_ALPHA_TO_COVERAGE
#endif

//*****************************************************************************
// custom specular
//*****************************************************************************
#if MATERIAL_TYPE(material_type) == MATERIAL_TYPE_custom_specular
#include "custom_specular.fx"
#define NO_ALPHA_TO_COVERAGE
#endif
