#ifndef _CBUFFER_FX_
#define _CBUFFER_FX_

#if DX_VERSION == 9

#define EMIT_TYPE_4(_type) _type##4
#define EMIT_TYPE_3(_type) _type##3
#define EMIT_TYPE_2(_type) _type##2
#define EMIT_TYPE_1(_type) _type
#define EMIT_TYPE(_type,_dim) EMIT_TYPE_##_dim(_type)
#define PADDED(_type,_dim,_name) EMIT_TYPE(_type,_dim) _name;
#define PADDED_ARRAY(_type,_dim,_name,_array_dim) EMIT_TYPE(_type,_dim) _name _array_dim;

#elif DX_VERSION == 11
	
#define CBUFFER_BEGIN(_name) cbuffer _name {
#define CBUFFER_BEGIN_FIXED(_name, _slot) cbuffer _name : register(b##_slot) {
#define CBUFFER_END };
#define CBUFFER_CONST(_buffer, _type, _hlsl_name, _c_name) _type _hlsl_name;
#define CBUFFER_CONST_ARRAY(_buffer, _type, _hlsl_name, _dim, _cname) _type _hlsl_name _dim;
#define SHADER_CONST_ALIAS(_buffer, _type, _hlsl_name, _hlsl_def, _c_name, _c_def, _c_offset) static _type _hlsl_name = _hlsl_def;

#define _TEXTURETYPE_2D texture2D<float4>
#define _TEXTURETYPE_2D_ARRAY Texture2DArray<float4>
#define _TEXTURETYPE_3D texture3D<float4>
#define _TEXTURETYPE_CUBE TextureCube<float4>
#define _TEXTUREANDSAMPLERTYPE_2D texture_sampler_2d
#define _TEXTUREANDSAMPLERTYPE_2D_ARRAY texture_sampler_2d_array
#define _TEXTUREANDSAMPLERTYPE_3D texture_sampler_3d
#define _TEXTUREANDSAMPLERTYPE_CUBE texture_sampler_cube
#define _SAMPLER(_name, _slot) sampler _name : register(s##_slot);
#define _TEXTURE(_type, _name, _slot) _TEXTURETYPE##_type _name : register(t##_slot);
#define _TEXTURE_AND_SAMPLER(_type, _name, _slot)										\
	_SAMPLER(GlobalSampler_##_name, _slot)												\
	_TEXTURE(_type, GlobalTexture_##_name, _slot)										\
	static _TEXTUREANDSAMPLERTYPE##_type _name={ GlobalSampler_##_name, GlobalTexture_##_name };
#define _TEXTURE_USING_SAMPLER(_type, _name, _slot, _sampler)							\
	_TEXTURE(_type, GlobalTexture_##_name, _slot)												\
	static _TEXTUREANDSAMPLERTYPE##_type _name={ _sampler, GlobalTexture_##_name };

#define VERTEX_TEXTURE_AND_SAMPLER(_type, _hlsl_name, _c_name, _slot) _TEXTURE_AND_SAMPLER(_type, _hlsl_name, _slot)
#define VERTEX_SAMPLER(_hlsl_name, _c_name, _slot) _SAMPLER(_hlsl_name, _slot)
#define VERTEX_TEXTURE(_type, _hlsl_name, _c_name, _slot) _TEXTURE(_type, _hlsl_name, _slot)
#define VERTEX_TEXTURE_USING_SAMPLER(_type, _hlsl_name, _c_name, _slot, _sampler) _TEXTURE_USING_SAMPLER(_type, _hlsl_name, _slot, _sampler)

#define PIXEL_TEXTURE_AND_SAMPLER(_type, _hlsl_name, _c_name, _slot) _TEXTURE_AND_SAMPLER(_type, _hlsl_name, _slot)
#define PIXEL_SAMPLER(_hlsl_name, _c_name, _slot) _SAMPLER(_hlsl_name, _slot)
#define PIXEL_TEXTURE(_type, _hlsl_name, _c_name, _slot) _TEXTURE(_type, _hlsl_name, _slot)
#define PIXEL_TEXTURE_USING_SAMPLER(_type, _hlsl_name, _c_name, _slot, _sampler) _TEXTURE_USING_SAMPLER(_type, _hlsl_name, _slot, _sampler)

#define COMPUTE_TEXTURE_AND_SAMPLER(_type, _hlsl_name, _c_name, _slot) _TEXTURE_AND_SAMPLER(_type, _hlsl_name, _slot)
#define COMPUTE_SAMPLER(_hlsl_name, _c_name, _slot) _SAMPLER(_hlsl_name, _slot)
#define COMPUTE_TEXTURE(_type, _hlsl_name, _c_name, _slot) _TEXTURE(_type, _hlsl_name, _slot)
#define COMPUTE_TEXTURE_USING_SAMPLER(_type, _hlsl_name, _c_name, _slot, _sampler) _TEXTURE_USING_SAMPLER(_type, _hlsl_name, _slot, _sampler)

#define EMIT_PAD_ELEMENT_1(_type,_name) _type##3 _name##_pad;
#define EMIT_PAD_ELEMENT_2(_type,_name) _type##2 _name##_pad;
#define EMIT_PAD_ELEMENT_3(_type,_name) _type##1 _name##_pad;
#define EMIT_PAD_ELEMENT_4(_type,_name)
#define EMIT_PAD_ELEMENT(_type,_dim,_name) EMIT_PAD_ELEMENT_##_dim(_type,_name)
#define PADDED(_type,_dim,_name) _type##_dim _name; EMIT_PAD_ELEMENT(_type,_dim,_name)
#define PADDED_ARRAY(_type,_dim,_name,_array_dim) _type##_dim _name _array_dim;

#define STRUCTURED_BUFFER(_name, _c_name, _type, _slot) StructuredBuffer<_type> _name : register(t##_slot);
#define RW_STRUCTURED_BUFFER(_name, _c_name, _type, _slot) RWStructuredBuffer<_type> _name : register(u##_slot);
#define BYTE_ADDRESS_BUFFER(_name, _c_name, _slot) ByteAddressBuffer _name : register(t##_slot);

#endif
	
#endif