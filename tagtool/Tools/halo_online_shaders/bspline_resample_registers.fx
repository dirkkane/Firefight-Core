#ifndef _BSPLINE_RESAMPLE_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _BSPLINE_RESAMPLE_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "bspline_resample_registers.h"

PIXEL_CONSTANT(float4, surface_sampler_xform, k_ps_bspline_resample_surface_sampler_xform);

#elif DX_VERSION == 11

CBUFFER_BEGIN(BSplineResamplePS)
	CBUFFER_CONST(BSplineResamplePS,	float4,		surface_sampler_xform,		k_ps_bspline_resample_surface_sampler_xform)
CBUFFER_END

#endif

#endif
