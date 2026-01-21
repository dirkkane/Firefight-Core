#ifndef _GLOBAL_LOCALSAMPLER_FX_
#define _GLOBAL_LOCALSAMPLER_FX_

// Macros used to define local samplers in explicit shaders

#if DX_VERSION == 9

#define LOCAL_SAMPLER_2D(_name, _slot) sampler2D _name : register(s##_slot)
#define LOCAL_SAMPLER_3D(_name, _slot) sampler3D _name : register(s##_slot)
#define LOCAL_SAMPLER_CUBE(_name, _slot) samplerCUBE _name : register(s##_slot)

#elif DX_VERSION == 11

#define DECLARE_LOCAL_SAMPLER(_name, _slot, _texture_type, _struct_type)	\
	_texture_type<float4> LocalTexture_##_name : register(t##_slot);		\
	sampler LocalSampler_##_name : register(s##_slot);						\
	static _struct_type _name = { LocalSampler_##_name, LocalTexture_##_name }
	
#define LOCAL_SAMPLER_2D(_name, _slot) DECLARE_LOCAL_SAMPLER(_name, _slot, texture2D, texture_sampler_2d)
#define LOCAL_SAMPLER_COMPARISON_2D(_name, _slot) DECLARE_LOCAL_SAMPLER(_name, _slot, texture2D, texture_comparison_sampler_2d) 
#define LOCAL_SAMPLER_3D(_name, _slot) DECLARE_LOCAL_SAMPLER(_name, _slot, texture3D, texture_sampler_3d)
#define LOCAL_SAMPLER_CUBE(_name, _slot) DECLARE_LOCAL_SAMPLER(_name, _slot, TextureCube, texture_sampler_cube)

#endif

#endif
