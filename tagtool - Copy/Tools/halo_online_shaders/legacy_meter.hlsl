#line 2 "source\rasterizer\hlsl\copy_surface.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "legacy_meter_registers.fx"
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
	float4 meter_gradient_min= {0.5, 0.5, 0.5, 1.0};
	float4 meter_gradient_max= {1.0, 1.0, 1.0, 1.0};
	float4 meter_empty_color= {0.0, 0.0, 0.0, 0.0};
	float meter_amount= pow(meter_amount_constant.x, 2.2);

	float4 r0;
	float4 t0= sample2D(source_sampler, IN.texcoord);

	// T0:
	// red channel has meter
	// green channel masks meter
	// 
	//---
	// store mask (green) into T2
	//C0= {0, 255, 0}
	//T2= C0.T0
	//R1a= T0b
	float mask_amount= t0.g;

	//---
	// prepare the meter
	//C0a= $meter_amount
	//R0a= C0a - HALF_BIAS(T0b) // minus .5
	float mux_value= meter_amount - (t0.b - 0.5);
	
	//---
	// compute the 'on' color
	//C0= $meter_gradient_min
	//C1= $meter_gradient_max
	//R0= C1*R1a + C0*INVERT(R1a)
	float4 on_color= mask_amount*meter_gradient_max + (1.0 - mask_amount)*meter_gradient_min;
	
	//---
	//C0= $meter_empty_color
	//C1= {255, 255, 255}
	//C0a= 0
	//C1a= 255
	//T1= C0 mux R0 // mux always looks at R0a
	//T1a= C0a mux C1a
	float3 t1= mux_value>0.5 ? on_color : meter_empty_color;
	float t1a= mux_value>0.5 ? 1.0 : 0.0;
	
	//---
	//T0a= T0a + T1a*T2b
	float result_alpha= t0.a + mask_amount*t1a;
	
	result_alpha= scale.w*result_alpha;

	//---
	//---
	return float4(t1.x, t1.y, t1.z, result_alpha);
	
}
