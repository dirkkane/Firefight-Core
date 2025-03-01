#include "global.fx"
#include "hlsl_vertex_types.fx"

//@generate screen

struct s_interpolators
{
	float4 position	:SV_Position;
	float2 texcoord	:TEXCOORD0;
	float4 color	:COLOR0;
};

#ifdef VERTEX_SHADER

s_interpolators default_vs(vertex_type IN)
{
	s_interpolators OUT;
	OUT.position= float4(IN.position, 0, 1);
	OUT.texcoord= IN.texcoord;
	OUT.color= IN.color;
	return OUT;
}

#endif

float4 default_ps(s_interpolators IN) : SV_Target
{
	float i = IN.texcoord.y - 0.5;
	float4 result= float4(i, 0, 0, 1);
	clip(IN.texcoord.x - 0.5);
	return result;
}
