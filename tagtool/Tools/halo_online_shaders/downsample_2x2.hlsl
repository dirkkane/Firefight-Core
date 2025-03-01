#line 2 "source\rasterizer\hlsl\downsample_2x2.hlsl"

#define PIXEL_SIZE

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);

float4 default_ps(screen_output IN) : SV_Target
{
#ifdef pc
	float3 color= 0.00000001f;							// hack to keep divide by zero from happening on the nVidia cards
#else
	float3 color= 0.0f;
#endif

/*
	// this is a 2x2 box filter, requires bilinear filtering
	color= convert_from_bloom_buffer( tex2D_offset(source_sampler, IN.texcoord, +0, +0));
*/
	IN.texcoord *= scale.xy;
	IN.texcoord += scale.zw;

	// this is a 4x4 gaussian filter, requires bilinear filtering:   (note: this might over-blur for a 2x2 downsample in some cases)
	//
	//		[ 1  3  3  1 ]
	//		[ 3  9  9  3 ]  / 64
	//		[ 3  9  9  3 ]
	//		[ 1  3  3  1 ]
	//
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, +3.0/4.0, +3.0/4.0));
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, -3.0/4.0, +3.0/4.0));
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, -3.0/4.0, -3.0/4.0));
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, +3.0/4.0, -3.0/4.0));
//	color= color / 4.0f;

	// this is a sharper filter
	//
	//		[ 1  9   9   1 ]
	//		[ 9  81  81  9 ]
	//		[ 9  81  81  9 ]
	//		[ 1  9   9   1 ]
	//
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, +2.5/10.0, +2.5/10.0));
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, -2.5/10.0, +2.5/10.0));
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, -2.5/10.0, -2.5/10.0));
//	color += convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, +2.5/10.0, -2.5/10.0));
//	color= color / 4.0f;

	// even sharper (box filter)
	color= convert_from_bloom_buffer(	tex2D_offset_exact(source_sampler, IN.texcoord, +0.0/10.0, +0.0/10.0));

	return convert_to_bloom_buffer(color);
}
