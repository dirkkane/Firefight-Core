#line 2 "source\rasterizer\hlsl\restore_ldr_hdr_depth.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(ldr_sampler, 0);
LOCAL_SAMPLER_2D(hdr_sampler, 1);
LOCAL_SAMPLER_2D(depth_sampler, 2);

struct triple_out
{
	float4 color[3] : SV_Target0;
};

triple_out default_ps(screen_output IN, SCREEN_POSITION_INPUT(pixel_coordinates))
{
	triple_out out_colors;
	
	float4 ldr_color, hdr_color;
#ifdef pc
	ldr_color= sample2D(ldr_sampler, IN.texcoord);
	hdr_color= sample2D(hdr_sampler, IN.texcoord);
#else
	asm
	{
		tfetch2D ldr_color, pixel_coordinates, ldr_sampler, UnnormalizedTextureCoords=true
		tfetch2D hdr_color, pixel_coordinates, hdr_sampler, UnnormalizedTextureCoords=true
	};
#endif
 	out_colors.color[1]= ldr_color;
 	out_colors.color[2]= hdr_color;
 	
	float4 depth_color;
#ifdef pc
	depth_color= sample2D(depth_sampler, IN.texcoord);
#else
 	float column= pixel_coordinates.x / 80;
 	float halfcolumn= frac( column );
 	if( halfcolumn>= 0.5 )
 		pixel_coordinates.x-= 40;
    else
		pixel_coordinates.x+= 40;
	asm
	{
		tfetch2D depth_color.zyxw, pixel_coordinates, depth_sampler, UnnormalizedTextureCoords=true
	};
#endif
 	out_colors.color[0]= depth_color;
 	return out_colors;
}
