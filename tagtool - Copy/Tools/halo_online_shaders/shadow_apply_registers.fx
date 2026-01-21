#ifndef _SHADOW_APPLY_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SHADOW_APPLY_REGISTERS_FX_
#endif

#define k_maximum_occlusion_sphere_count			20
#define k_occlusion_sphere_stride					2

#if DX_VERSION == 9

#include "shadow_apply_registers.h"

PIXEL_CONSTANT(float4x4, view_inverse_matrix, k_ps_shadow_apply_view_inverse_matrix);
PIXEL_CONSTANT(float4, occlusion_spheres[k_maximum_occlusion_sphere_count * k_occlusion_sphere_stride], k_ps_shadow_apply_occlusion_spheres); 
PIXEL_CONSTANT(int, occlusion_spheres_count, k_ps_shadow_apply_occlusion_spheres_count);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShadowApplyPS)
	CBUFFER_CONST(ShadowApplyPS,		float4x4,		view_inverse_matrix,																k_ps_shadow_apply_view_inverse_matrix)
	CBUFFER_CONST_ARRAY(ShadowApplyPS,	float4,			occlusion_spheres, [k_maximum_occlusion_sphere_count * k_occlusion_sphere_stride],	k_ps_shadow_apply_occlusion_spheres)
	CBUFFER_CONST(ShadowApplyPS,		int,			occlusion_spheres_count,															k_ps_shadow_apply_occlusion_spheres_count)
CBUFFER_END

#endif

#endif
