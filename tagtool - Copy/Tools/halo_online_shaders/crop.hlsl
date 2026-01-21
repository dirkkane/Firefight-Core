#line 2 "source\rasterizer\hlsl\crop.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "texture_xform.fx"
#include "crop_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

// returns black outside of the rectangle (in texture coordinate space:)
//
//    x in [scale.x, scale.z)
//    y in [scale.y, scale.w)
//
// essentially, scale is (left, top, right, bottom)
// left and top are inclusive, right and bottom are exclusive
//

float4 default_ps(screen_output IN) : SV_Target
{
	float2 texcoord= transform_texcoord(IN.texcoord, texcoord_xform);
 	float4 color= sample2D(source_sampler, texcoord);
 	float crop= step(crop_bounds.x, texcoord.x) * step(texcoord.x, crop_bounds.z) * step(crop_bounds.y, texcoord.y) * step(texcoord.y, crop_bounds.w);
 	return color * scale * crop;
}
