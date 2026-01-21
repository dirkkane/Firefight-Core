#ifndef _HLSL_CONSTANT_ONESHOT_H_
#define _HLSL_CONSTANT_ONESHOT_H_

enum
{
	k_maximum_node_count= 70,
};

#if DX_VERSION == 9

//NOTE: if you modify any of this, than you need to modify hlsl_constant_oneshot.fx 

//vertex shader constants
enum 
{
	k_position_compression_scale= k_last_view_constant,
	k_position_compression_offset,
	k_uv_compression_scale_offset,
	k_node_per_vertex_count= 230,
	k_node_start= 16, 
	k_alpha_test_shader_lighting_constant= 229,
};
COMPILE_TIME_ASSERT(k_node_start%4== 0);

//pixel shader constants
enum 
{
	//k_ps_probe_r_scale= 11,
	//k_ps_probe_g_scale= 12,
	//k_ps_probe_b_scale= 13,
	k_ps_dominant_light_direction= 11,
	k_ps_constant_shadow_alpha= 11,					// overlaps with k_ps_dominant_light_direction, but they aren't used at the same time
	k_ps_dominant_light_intensity= 13,

	// Active camo constants
	k_ps_active_camo_factor= 212,
	k_ps_distort_bounds= 213,

	k_ps_shadow_map_pixel_size= 214,

	// booleans
	k_ps_bool_dynamic_light_shadowing= 13,
	k_ps_bool_is_normal_basemap= 14,
};

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\hlsl_constant_oneshot.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

//these constants are loaded at the same place as the ravi constants

struct s_rasterizer_compression 
{
	real_vector4d position_scale;
	real_vector4d position_offset;
	real_vector4d uv_scale_offset;
};
#endif //_HLSL_CONSTANT_ONESHOT_H_
