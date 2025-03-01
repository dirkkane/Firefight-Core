#line 1 "source\rasterizer\hlsl\final_composite.hlsl"


//@generate screen

//#define CALC_BLEND calc_blend_weapon_zoom
float3 calc_blend_weapon_zoom(in float2 texcoord, in float4 combined, in float4 bloom);


#include "final_composite_base.hlsl"


float3 calc_blend_weapon_zoom(in float2 texcoord, in float4 combined, in float4 bloom)
{
	float3 blend= combined * bloom.a + bloom.rgb;
	//float2 blur_grade_texcoord= (texcoord.xy - player_window_constants.xy) / player_window_constants.zw;
	//const float blur_grade= sample2D(blur_grade_sampler, blur_grade_texcoord).b;
	//[branch]
	//if (blur_grade > 0.01f)
	//{
	//	//float3 blur_color= bloom.rgb * (intensity.z * intensity.x * bloom.a + intensity.y);
	//	float3 blur_color= bloom.rgb * (intensity.z * bloom.a + 1);
	//	blend= lerp(blend, blur_color, blur_grade);
	//	blend= lerp(blend, bloom.rgb * intensity.z, blur_grade);				
	//}
	return blend;
}
