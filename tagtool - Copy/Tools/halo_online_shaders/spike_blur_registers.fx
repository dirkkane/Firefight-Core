#ifndef _SPIKE_BLUR_REGISTERS_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _SPIKE_BLUR_REGISTERS_FX_
#endif

#if DX_VERSION == 9

#include "spike_blur_registers.h"

PIXEL_CONSTANT(float2, source_pixel_size,	k_ps_spike_blur_source_pixel_size);	// texcoord size of a single pixel (1 / (width-1), 1/(height-1))
PIXEL_CONSTANT(float4, offset_delta,		k_ps_spike_blur_offset_delta);		// float offset_x, float offset_y (should be a multiple of source_pixel_size.y), float delta_x
PIXEL_CONSTANT(float3, initial_color,		k_ps_spike_blur_initial_color);		// initial RGB scales (at offset_x,offset_y)
PIXEL_CONSTANT(float3, delta_color,			k_ps_spike_blur_delta_color);		// scale for RGB per sample (multiplies previous color at each delta_x offset)

#elif DX_VERSION == 11

CBUFFER_BEGIN(SpikeBlurPS)
	CBUFFER_CONST(SpikeBlurPS,		float2,		source_pixel_size,		k_ps_spike_blur_source_pixel_size)
	CBUFFER_CONST(SpikeBlurPS,		float2,		source_pixel_size_pad,	k_ps_spike_blur_source_pixel_size_pad)
	CBUFFER_CONST(SpikeBlurPS,		float4,		offset_delta,			k_ps_spike_blur_offset_delta)
	CBUFFER_CONST(SpikeBlurPS,		float3,		initial_color,			k_ps_spike_blur_initial_color)
	CBUFFER_CONST(SpikeBlurPS,		float,		initial_color_pad,		k_ps_spike_blur_initial_color_pad)
	CBUFFER_CONST(SpikeBlurPS,		float3,		delta_color,			k_ps_spike_blur_delta_color)
	CBUFFER_CONST(SpikeBlurPS,		float,		delta_color_pad,		k_ps_spike_blur_delta_color_pad)
CBUFFER_END

#endif

#endif
