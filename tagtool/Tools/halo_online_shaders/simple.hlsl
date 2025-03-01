#line 2 "source\rasterizer\hlsl\simple.hlsl"

#include "global.fx"
#include "deform.fx"
#include "utilities.fx"
#include "clip_plane.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

//@generate world
//@generate rigid
//@generate skinned

LOCAL_SAMPLER_2D(base_map, 0);
LOCAL_SAMPLER_2D(radiance_map, 1);

///constant to do order 2 SH convolution

//PIXEL_CONSTANT(float4, p_ravi_cAr, c1);
//PIXEL_CONSTANT(float4, p_ravi_cAg, c2);
//PIXEL_CONSTANT(float4, p_ravi_cAb, c3);
//PIXEL_CONSTANT(float4, p_ravi_cBr, c4);
//PIXEL_CONSTANT(float4, p_ravi_cBg, c5);
//PIXEL_CONSTANT(float4, p_ravi_cBb, c6);
//PIXEL_CONSTANT(float4, p_ravi_cC, c7);

struct s_simple_world_vertex 
{
    float4 position		:SV_Position;
#if DX_VERSION == 11
	float clip_distance :SV_ClipDistance;
#endif	
    float2 texcoord		:TEXCOORD0;
};

void calc_albedo_ps(
	float2 uv, 
	out float4 albedo)
{
	albedo= sample2D(base_map, uv);
	albedo.xyz*= albedo.xyz;	// square so they don't desaturate
};

float3 calc_static_lightmap_ps(
	float2 uv)
{
	float3 color;
	color= sample2D(radiance_map, uv);
	color*= 0.08;
	return color;
}

// vertex fragment entry points
void albedo_vs(
	vertex_type IN, 
	out s_simple_world_vertex OUT)
{
	float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(IN, local_to_world_transform);
	}
	    
	if (always_true)
	{
		OUT.texcoord = IN.texcoord;
		OUT.position= mul(float4(IN.position, 1.0f), View_Projection);
		OUT.position.w= 1.0f;
	}
	else
	{
		OUT.texcoord= IN.texcoord;
		OUT.position= float4(0,0,0,0);
	}
	
#if DX_VERSION == 11
	OUT.clip_distance = dot(OUT.position, v_clip_plane);
#endif	
}

void static_per_pixel_vs(
	vertex_type IN, 
	s_lightmap_per_pixel IN_LIGHTMAP, 
	out s_simple_world_vertex OUT, 
	out s_lightmap_per_pixel OUT_LIGHTMAP)
{
	float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(IN, local_to_world_transform);
	}
	    
	if (always_true)
	{
		OUT.texcoord = IN.texcoord;
		OUT_LIGHTMAP.texcoord= IN_LIGHTMAP.texcoord;
		OUT.position= mul(float4(IN.position, 1.0f), View_Projection);
		OUT.position.w= 1.0f;
	}
	else
	{
		OUT_LIGHTMAP.texcoord= IN_LIGHTMAP.texcoord;
		
		OUT.texcoord= IN.texcoord;
		OUT.position= float4(0,0,0,0);
	}	

#if DX_VERSION == 11
	OUT.clip_distance = dot(OUT.position, v_clip_plane);
#endif	
}

// pixel fragment entry points

accum_pixel albedo_ps(
	s_simple_world_vertex IN) : SV_Target
{
    float4 color;
	calc_albedo_ps(IN.texcoord, color);    

	return convert_to_render_target(color, false, false);
}

void static_default_vs(in vertex_type vertex, out s_simple_world_vertex OUT)
{
	float4 local_to_world_transform[3];
	if (always_true)
	{
	    deform(vertex, local_to_world_transform);
	}

	if (always_true)
	{
		OUT.texcoord = vertex.texcoord;
		OUT.position= mul(float4(vertex.position, 1.0f), View_Projection);
	}
	else
	{
		OUT.texcoord= vertex.texcoord;
		OUT.position= float4(0,0,0,0);
	}	

#if DX_VERSION == 11
	OUT.clip_distance = dot(OUT.position, v_clip_plane);
#endif	
}

accum_pixel static_default_ps(
	in s_simple_world_vertex fragment) : SV_Target
{
	float4 albedo;
	calc_albedo_ps(fragment.texcoord, albedo);

//      RGBW format
	float4 out_color= albedo;
	out_color *= g_exposure.rrra;

	return convert_to_render_target(out_color, false, false);
}

accum_pixel static_per_pixel_ps(
	s_simple_world_vertex IN, 
	s_lightmap_per_pixel LIGHTMAP) : SV_Target
{
    float4 out_color;
	calc_albedo_ps(IN.texcoord, out_color);    

	//multiply in the light map
	out_color.rgb*= calc_static_lightmap_ps(LIGHTMAP.texcoord);
	out_color *= g_exposure.rrra;

	return convert_to_render_target(out_color, false, false); //sqrt(color);
}


struct VS_INPUT_RAVI
{
	vertex_type base_vertex;
};

struct VS_OUTPUT_RAVI
{
	float4 pos		: SV_Position;
#if DX_VERSION == 11
	float clip_distance : SV_ClipDistance;
#endif	
	float3 normal	: TEXCOORD0;
	float2 uv0		: TEXCOORD1;
	float3 tangent		: TEXCOORD3;
	float3 binormal 	: TEXCOORD4;
};

VS_OUTPUT_RAVI static_sh_vs(VS_INPUT_RAVI input)
{
	float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(input.base_vertex, local_to_world_transform);
	}

	VS_OUTPUT_RAVI output;

	if (always_true)
	{
		//output to pixel shader

 		output.pos= mul(float4(input.base_vertex.position, 1.0f), View_Projection);
		output.normal= input.base_vertex.normal;
		output.uv0= input.base_vertex.texcoord;
		output.tangent= input.base_vertex.tangent;
		output.binormal= input.base_vertex.binormal;		
	}
	else
	{
 		output.pos= mul(float4(input.base_vertex.position, 1.0f), View_Projection);
		output.normal= input.base_vertex.normal;
		output.uv0= input.base_vertex.texcoord;
		output.tangent= input.base_vertex.tangent;
		output.binormal= input.base_vertex.binormal;		
	}
	
#if DX_VERSION == 11
	output.clip_distance = dot(output.pos, v_clip_plane);
#endif	

	return output;	
}


accum_pixel static_sh_ps(VS_OUTPUT_RAVI input) : SV_Target
{
	//compute the per pixel ravi 
	float3x3 tangent_frame = {input.tangent, input.binormal, input.normal};
	float4 normal4;
	normal4.xyz = input.normal;
	normal4.w= 1.0f;

   	float3 x1, x2, x3;
    
    // Linear + constant polynomial terms
   	x1.r = dot(p_lighting_constant_0, normal4);
    x1.g = dot(p_lighting_constant_1, normal4);
    x1.b = dot(p_lighting_constant_2, normal4);
    
    	// 4 of the quadratic polynomials
    float4 vB = normal4.xyzz * normal4.yzzx;   
    x2.r = dot(p_lighting_constant_3, vB);
    x2.g = dot(p_lighting_constant_4, vB);
    x2.b = dot(p_lighting_constant_5, vB);
   
    	// Final quadratic polynomial
   	float vC = normal4.x*normal4.x - normal4.y*normal4.y;
	x3 = p_lighting_constant_6.rgb * vC;

	float3 ravi_color= (x1 + x2 + x3);		

	//add the light probe color and (lightmap-lightprobe) diff
	//and multiply albedo

	float4 albedo;
	calc_albedo_ps(input.uv0, albedo);

	float4 out_color;
	out_color.rgb= (ravi_color*0.1f) * albedo.xyz * g_exposure.rrr;
	out_color.rgb= max(out_color.rgb, float3(0.0f, 0.0f, 0.0f));
	out_color.w= 0.f;

    return convert_to_render_target(out_color, false, false);

}
	     		