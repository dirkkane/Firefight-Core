#line 2 "source\rasterizer\hlsl\screenshot_memexport.hlsl"

#define USE_CUSTOM_POSTPROCESS_CONSTANTS

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "screenshot_memexport_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(source_sampler, 0);
LOCAL_SAMPLER_2D(background_sampler, 1);			// destination texture

// pixel fragment entry points
float4 default_ps(screen_output IN, SCREEN_POSITION_INPUT(pos)) : SV_Target
{
	float2 pixel_coord= pos.xy * vpos_to_pixel_xform.xy + vpos_to_pixel_xform.zw;
	int pixel_index= min(pixel_coord.y * export_info.x + pixel_coord.x, export_info.y);

	// sample source
	float2 source_coord= pixel_coord.xy * pixel_to_source_xform.xy + pixel_to_source_xform.zw;	
	float4 source= sample2D(source_sampler, source_coord);

	// screenshot gamma -> linear
//	source.rgb= pow(source.rgb, export_info.z);

	// sample background
	float4 result= source;
#ifdef pc
	source += sample2D(background_sampler, IN.texcoord);
#else

	// grab exact background pixel
	float4 background;
	asm {
		tfetch2D	background, pixel_coord, background_sampler, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
	};

	// screenshot gamma -> linear
//	background.rgb= pow(background.rgb, export_info.z);

	result += background;
	result.rgb= result.bgr;

	// linear -> screenshot gamma
//	result.rgb= pow(result.rgb, 1.0f / export_info.z);

	// mem-export!
	const float4 k_offset_const= { 0, 1, 0, 0 };
	asm {
		alloc export=1
		mad eA, pixel_index, k_offset_const, export_stream_constant
		mov eM0, result
	};

#endif
	return result;
}
