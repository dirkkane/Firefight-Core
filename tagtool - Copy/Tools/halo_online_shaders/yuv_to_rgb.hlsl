#line 2 "source\rasterizer\hlsl\yuv_to_rgb.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "postprocess.fx"
#include "yuv_to_rgb_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(tex0, 0);
LOCAL_SAMPLER_2D(tex1, 1);
LOCAL_SAMPLER_2D(tex2, 2);
LOCAL_SAMPLER_2D(tex3, 3);

float4 default_ps(screen_output IN) : SV_Target
{                               
	float4 c;                   
	float4 p;                   
	c.x = sample2D( tex0, IN.texcoord ).x;
	c.y = sample2D( tex1, IN.texcoord ).x;
	c.z = sample2D( tex2, IN.texcoord ).x;
	c.w = consts.x;
	p.w = sample2D( tex3, IN.texcoord ).x;
	p.x = dot( tor, c );
	p.y = dot( tog, c );
	p.z = dot( tob, c );
	p.w*= consts.w;
	return p;
}
