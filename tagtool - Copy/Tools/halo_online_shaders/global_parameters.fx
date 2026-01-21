#ifndef _PARAMETERS_FX_
#define _PARAMETERS_FX_

#if DX_VERSION == 9

// Exposed parameters

#define PARAM(_type, _name) extern _type _name
#define PARAM_STRUCT(_type, _name) extern _type _name
#define PARAM_ARRAY(_type, _name, _dim) extern _type _name _dim
#define PARAM_SAMPLER_2D(_name) extern sampler2D _name
#define PARAM_SAMPLER_3D(_name) extern sampler3D _name
#define PARAM_SAMPLER_CUBE(_name) extern samplerCUBE _name
#define PARAM_SAMPLER_2D_ARRAY(_name) extern sampler _name

// Global constants

#ifdef VERTEX_SHADER
	#define VERTEX_CONSTANT(type, name, register_index)   type name : register(register_index);
	#define PIXEL_CONSTANT(type, name, register_index)   type name;
	#define VERTEX_SAMPLER_CONSTANT(name, register_index) sampler2D name : register(register_index);
#else
	#define VERTEX_CONSTANT(type, name, register_index)   type name;
	#define PIXEL_CONSTANT(type, name, register_index)   type name : register(register_index);
	#define VERTEX_SAMPLER_CONSTANT(name, register_index)
#endif
#define BOOL_CONSTANT(name, register_index)   bool name : register(b##register_index);
#define INT_CONSTANT(name, register_index) int name : register(i##register_index);
#define SAMPLER_CONSTANT(name, register_index)	sampler name : register(s##register_index);
#define CONSTANT_NAME(n) c##n
#define BOOL_CONSTANT_NAME(n) b##n
#define INT_CONSTANT_NAME(n) i##n

#elif DX_VERSION == 11

#ifdef PARAM_ALLOC_PREPROCESS

	#define PARAM(_type, _name) ___PARAM___(_type _name)
	#define PARAM_ARRAY(_type, _name, _dim) ___PARAM___(_type _name _dim)
	#define PARAM_STRUCT(_type, _name) ___PARAM___(_type _name)
	#define PARAM_SAMPLER_2D(_name) ___SAMPLER___(2D _name)
	#define PARAM_SAMPLER_COMPARISON_2D(_name) ___SAMPLER___(COMPARISON_2D _name)
	#define PARAM_SAMPLER_3D(_name) ___SAMPLER___(3D _name)
	#define PARAM_SAMPLER_CUBE(_name) ___SAMPLER___(CUBE _name)
	#define PARAM_SAMPLER_2D_ARRAY(_name) ___SAMPLER___(2D_ARRAY _name)

#elif defined(PARAM_ALLOC_FIRST_PASS)

	#define PARAM_STORAGE_float float4
	#define PARAM_STORAGE_float2 float4
	#define PARAM_STORAGE_float3 float4
	#define PARAM_STORAGE_float4 float4
	#define PARAM_STORAGE_int int4
	#define PARAM_STORAGE_bool bool

	#define PARAM(_type, _name) _type UserParameter_##_name; static _type _name = UserParameter_##_name
	#define PARAM_ARRAY(_type, _name, _dim) _type UserParameter_##_name _dim; static _type _name _dim = UserParameter_##_name
	#define PARAM_STRUCT(_type, _name) _type UserParameter_##_name; static _type _name = UserParameter_##_name

	#ifndef TEMP_SAMPLER_DECLARED
		#define TEMP_SAMPLER_DECLARED
		sampler TempSampler__;
		#define TEMP_SAMPLER_COMPARISON_DECLARED
		SamplerComparisonState TempSamplerComparison__;
	#endif
	
	#define DECLARE_PARAM_SAMPLER(_name, _texture_type, _struct_type)								\
		_texture_type<float4> UserParameterTexture_##_name;											\
		static const _struct_type _name = { TempSampler__, UserParameterTexture_##_name }
	#define DECLARE_PARAM_SAMPLER_COMPARISON(_name, _texture_type, _struct_type)								\
		_texture_type<float4> UserParameterTexture_##_name;											\
		static const _struct_type _name = { TempSamplerComparison__, UserParameterTexture_##_name }

	#define PARAM_SAMPLER_2D(_name) DECLARE_PARAM_SAMPLER(_name, texture2D, texture_sampler_2d)
	#define PARAM_SAMPLER_COMPARISON_2D(_name) DECLARE_PARAM_SAMPLER_COMPARISON(_name, texture2D, texture_sampler_comparison_2d)
	#define PARAM_SAMPLER_3D(_name)	DECLARE_PARAM_SAMPLER(_name, texture3D, texture_sampler_3d)
	#define PARAM_SAMPLER_CUBE(_name) DECLARE_PARAM_SAMPLER(_name, TextureCube, texture_sampler_cube)
	#define PARAM_SAMPLER_2D_ARRAY(_name) DECLARE_PARAM_SAMPLER(_name, Texture2DArray, texture_sampler_2d_array)

#else

	#define PARAM(_type, _name) static _type _name = ___##_name
	#define PARAM_ARRAY(_type, _name, _dim) static _type _name _dim = ___##_name
	#define PARAM_STRUCT(_type, _name) static _type _name = ___##_name
	#define PARAM_SAMPLER_2D(_name)
	#define PARAM_SAMPLER_COMPARISON_2D(_name) 
	#define PARAM_SAMPLER_3D(_name)
	#define PARAM_SAMPLER_CUBE(_name)
	#define PARAM_SAMPLER_2D_ARRAY(_name)
	
#endif
	
#endif

#endif
