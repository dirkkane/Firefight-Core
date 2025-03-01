#line 2 "source\rasterizer\hlsl\stencil_stipple.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "stencil_stipple_registers.fx"
//@generate screen

struct screen_output
{
	float4 HPosition	:SV_Position;
};

screen_output default_vs(vertex_type IN)
{
    screen_output OUT;

    OUT.HPosition.xy= IN.position;
    OUT.HPosition.zw= 0.5f;

    return OUT;
}

#ifdef durango

uint4 default_ps(SCREEN_POSITION_INPUT(position)) : SV_Target0
{
	uint2 ipos = uint2(position.xy);

	uint result = 0;
	result |= (ipos.y & 2) >> 1;
	result |= ((ipos.x ^ ipos.y) & 2);
	result |= (ipos.y & 1) << 2;
	result |= ((ipos.x ^ ipos.y) & 1) << 3;

	return result;
}

#else

float4 default_ps(SCREEN_POSITION_INPUT(position)) : SV_Target
{
    // calculate which block we are in, modulo 2
    float2 block_position= floor(fmod(position / block_size, 2.0f));
    float bit;

    if (odd_bits)
    {
		// odd bits are (X xor Y)
		bit= abs(block_position.x - block_position.y);
	}
	else
	{
		// even bits are just the Y block position
		bit= block_position.y;
	}

    // clip pixel if bit is less than 0.5
    clip(bit - 0.5f);

    return(float4(0.f, 0.f, 0.f, 0.f));
}

#endif