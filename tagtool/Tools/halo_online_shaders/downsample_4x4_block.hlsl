#line 2 "source\rasterizer\hlsl\downsample_4x4_block.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

//@entry default
//@entry albedo
//@entry static_default

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
	float4 color= 0.0f;

	// this is a 4x4 box filter
	color += tex2D_offset(source_sampler, IN.texcoord, -1, -1);
	color += tex2D_offset(source_sampler, IN.texcoord, +1, -1);
	color += tex2D_offset(source_sampler, IN.texcoord, -1, +1);
	color += tex2D_offset(source_sampler, IN.texcoord, +1, +1);
	color= color / 4.0f;

	return color;
}

#if DX_VERSION == 9

float4 tent_5(sampler2D tex, float2 texcoord)
{
    float4 colour = tex2D(tex, texcoord) * 0.5f;
    colour += tex2D(tex, texcoord + float2( pixel_size.x, 0)) * 0.125f;
    colour += tex2D(tex, texcoord + float2(-pixel_size.x, 0)) * 0.125f;
    colour += tex2D(tex, texcoord + float2(0,  pixel_size.y)) * 0.125f;
    colour += tex2D(tex, texcoord + float2(0, -pixel_size.y)) * 0.125f;

    return colour;
}

float4 upsample_4(sampler2D tex, float2 texcoord, float r)
{
    float2 texel_size = scale.xy * r;
    float4 colour = 0;
    colour += tex2D(tex, texcoord + float2( texel_size.x, 0));
    colour += tex2D(tex, texcoord + float2(-texel_size.x, 0));
    colour += tex2D(tex, texcoord + float2( 0,  texel_size.y));
    colour += tex2D(tex, texcoord + float2( 0, -texel_size.y));
    return colour / 4.0f;
}

float4 albedo_ps(screen_output IN) : SV_Target
{
    return upsample_4(source_sampler, IN.texcoord.xy, 1.0f);
}

screen_output albedo_vs(vertex_type IN)
{
#ifdef VERTEX_SHADER

    return default_vs(IN);

#endif
}

float4 static_default_ps(screen_output IN) : SV_Target
{
    return tent_5(source_sampler, IN.texcoord.xy);
}

screen_output static_default_vs(vertex_type IN)
{
#ifdef VERTEX_SHADER

    return default_vs(IN);

#endif
}

#endif
