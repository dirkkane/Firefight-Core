#line 2 "source\rasterizer\hlsl\copy_surface.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "shield_meter_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

//float4 gradient_min_color; // get from HUD cuscolor2
//float4 gradient_max_color; // get from HUD cuscolor3
//float4 flash_color; // get from hud cuscolor1
//float flash_extension; // get from HUD input1
//float flash_leading_edge_position; // get form HUD input2
//float global_alpha; // get from HUD globalfade

float4 default_ps(screen_output IN) : SV_Target
{
	float4 background_color= {0.0, 0, 0, 0};
	float meter_brightness= 0.5;
	float4 r0;
	float4 t0= sample2D(source_sampler, IN.texcoord);
	float flash_extension= misc_parameters.x;
	float flash_leading_edge_position= misc_parameters.y;
	float global_alpha= misc_parameters.z;

	//---
	//C0= $gradient_min_color
	//C0a= $flash_leading_edge_position
	//C1= $gradient_max_color
	//C1a= 255
	//R0a= OUT_SCALE_BY_4(C1a*T0b + C1a*T0b)
	//R0= OUT_SCALE_BY_4(C0a + NEGATE(T0))
	r0.a= 4.0*(t0.b + t0.b);
	r0.rgb= 4.0*(flash_leading_edge_position - t0.b);

	//---
	//C0= $gradient_min_color
	//C0a= $flash_leading_edge_position
	//C1= $gradient_max_color
	//R0a= EXPAND_NEGATE(R0b)
	//R0= INVERT(R0a)*C0 + R0a*C1
	r0.rgb= (1.0 - r0.a)*gradient_min_color + r0.a*gradient_max_color;
	r0.a= 1.0 - 2.0*max(0,r0.b);

	//---
	//C0= $gradient_min_color
	//C0a= $flash_leading_edge_position
	//C1= $flash_color
	//C1a= $flash_extension
	//R0a= T0b + HALF_BIAS_NEGATE(C1a)
	//R0= R0 + R0a*C1
	r0.rgb= r0.rgb + r0.a*flash_color;
	r0.a= t0.b + (0.5 - flash_extension);

	//---
	//C0= $background_color
	//C0a= 255
	//C1a= $meter_brightness
	//R0a= C1a mux C0a
	//R0= R0 mux C0
	// note: if the mux bit (r0.a, MSB) is set, we choose CD, otherwise AB
	float mux_test= r0.a>0.5 ? 1.0 : 0.0;
	r0.a= mux_test*1.0 + (1.0 - mux_test)*meter_brightness;
	r0.rgb= mux_test*background_color + (1.0-mux_test)*r0.rgb;
	
	//---
	//C0a= $global_alpha
	//R0a= INVERT(R0a)*C0a
	//R0= R0*C0a
	r0.a= (1.0 - r0.a)*global_alpha;
	r0.rgb= r0.rgb*global_alpha;
	
	//---
	//R0a= INVERT(R0a)
	r0.a= 1.0f - r0.a;

	//---
	//SRCCOLOR= R0*T0a
	//SRCALPHA= R0a	
	float result_alpha= t0.a*scale.w;
	return float4(r0.r*t0.a, r0.g*t0.a, r0.b*t0.a, result_alpha);
}
