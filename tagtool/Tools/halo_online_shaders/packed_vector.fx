#ifndef _PACKED_VECTOR_FX_
#define _PACKED_VECTOR_FX_

#if DX_VERSION == 11

float2 UnpackHalf2(in uint input)
{
	return float2(f16tof32(input), f16tof32(input>>16));
}

float4 UnpackHalf4(in uint2 input)
{
	return float4(UnpackHalf2(input.x), UnpackHalf2(input.y));
}

float2 UnpackUShort2N(in uint input)
{
	return float2(input&0xffff, input>>16) / 65535.0;
}

float4 UnpackUShort4N(in uint2 input)
{
	return float4(UnpackUShort2N(input.x), UnpackUShort2N(input.y));
}

float4 UnpackARGB8(in uint input)
{
	return float4(
		(input >> 16) & 0xff,
		(input >> 8) & 0xff,
		input & 0xff,
		(input >> 24) & 0xff) / 255.0;
}

int SignExtend(int x, int bits)
{
	return (x << (32-bits)) >> (32-bits);
}

float3 UnpackDec3N(in uint input)
{
	return float3(
		SignExtend(input, 10),
		SignExtend(input >> 10, 10),
		SignExtend(input >> 20, 10)) / 511.0;
}

float3 UnpackDHEN3N(in uint input)
{
	return float3(
		SignExtend(input, 10) / 511.0,
		SignExtend(input >> 10, 11) / 1023.0,
		SignExtend(input >> 21, 11) / 1023.0);
}

float3 UnpackUHEND3N(in uint input)
{
	return float3(
		(input & 0x7ff) / 2047.0,
		((input >> 11) & 0x7ff) / 2047.0,
		((input >> 22) & 0x3ff) / 1023.0);
}

float4 UnpackSByte4(in uint input)
{
	return float4(
		SignExtend(input, 8),
		SignExtend(input >> 8, 8),
		SignExtend(input >> 16, 8),
		SignExtend(input >> 24, 8));
}

uint PackHalf2(in float2 input)
{
	return f32tof16(input.x)|(f32tof16(input.y)<<16);
}

uint2 PackHalf4(in float4 input)
{
	return uint2(PackHalf2(input.xy), PackHalf2(input.zw));
}

uint PackUShort2N(in float2 input)
{
	input = saturate(input);
	return ((uint)(input.x * 65535.0)) |
		((uint)(input.y * 65535.0) << 16);
}

uint2 PackUShort4N(in float4 input)
{
	return uint2(PackUShort2N(input.xy), PackUShort2N(input.zw));
}

uint PackARGB8(in float4 input)
{
	input = saturate(input);
	return ((uint)(input.b * 255.0)) |
		((uint)(input.g * 255.0) << 8) |
		((uint)(input.r * 255.0) << 16) |
		((uint)(input.a * 255.0) << 24);
}

uint PackDec3N(in float3 input)
{
	input = clamp(input, -1.0, 1.0);
	return ((int)(input.x * 511) & 0x3ff) |
		(((int)(input.y * 511) & 0x3ff) << 10) |
		(((int)(input.z * 511) & 0x3ff) << 20);
}

uint PackSByte4(in float4 input)
{
	input = clamp(input, -128.0, 127.0);
	return (((int)input.x) & 0xff) |
		((((int)input.y) & 0xff) << 8) |
		((((int)input.z) & 0xff) << 16) |
		((((int)input.w) & 0xff) << 24);
}

#endif

#endif

