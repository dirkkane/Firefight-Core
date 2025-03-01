#ifndef _DEBUG_MODES_FX_
#define _DEBUG_MODES_FX_

/*
debug_modes.fx
Dec, 11, 2005 5:41pm (hao)
*/

//mode 0:	lightmap uv
//mode 1:	lightmap resolution
//mode 2:	vertex normal
//mode 3:	bump normal
//mode 4:	tangent
//mode 5:	bi-normal
//mode 6:	ambient occlusion only
//mode 7:	linear only
//mode 8:	texture coord

float _frac(float src)
{
	return src- floor(src);
}

float4 display_debug_modes(
	in float2 lightmap_texcoord,
	in float3 normal,
	in float2 texcoord,
	in float3 tangent,
	in float3 binormal,
	in float3 bump_normal,
	in float3 ambient_only,
	in float3 linear_only,
	in float3 quadratic)
{   	
	float4 out_color;
	
	//render lightmap uv
	if (p_render_debug_mode.x< 1.0f)
	{
		out_color= float4(lightmap_texcoord, 0.0f, 0.0f);
	}
	//render lightmap resolution
	else if (p_render_debug_mode.x< 2.0f)
	{
		float2 temp= floor(lightmap_texcoord * 1024.0f);
		if (_frac(temp.x/2.0f)== 0.0f)
		{
			if (_frac(temp.y/2.0f)== 0.0f)
			{
				out_color= float4(1.0f, 0.7f, 0.3f, 0.0f);
			}
			else
			{
				out_color= 0.0f;
			}
		}
		else
		{
			if (_frac(temp.y/2.0f)== 0.0f)
			{
				out_color= 0.0f;
			}
			else
			{
				out_color= float4(1.0f, 0.7f, 0.3f, 0.0f);
			}
		}		
	}
	//render vertex normal
	else if (p_render_debug_mode.x< 3.0f)
	{
		out_color= float4(normal, 0.0f);
	}
	//render bump normal
	else if (p_render_debug_mode.x< 4.0f)
	{
		out_color= float4(bump_normal, 0.0f);
	}
	//render tangent
	else if (p_render_debug_mode.x< 5.0f)
	{
		out_color= float4(tangent, 0.0f);
	}
	//render binormal
	else if (p_render_debug_mode.x< 6.0f)
	{
		out_color= float4(binormal, 0.0f);
	}
	//render tangent
	else if (p_render_debug_mode.x< 7.0f)
	{
		out_color= float4(ambient_only, 0.0f);
	}
	else if (p_render_debug_mode.x< 8.0f)
	{
		out_color= float4(linear_only, 0.0f);
	}
	else if (p_render_debug_mode.x< 9.0f)
	{
		out_color= float4(quadratic, 0.0f);
	}
	else if (p_render_debug_mode.x< 10.0f)
	{
		out_color= float4(texcoord, 0.0f, 0.0f);
	}
	else
	{
		out_color= 0.0f;
	}

	return out_color;
	
}

#endif 