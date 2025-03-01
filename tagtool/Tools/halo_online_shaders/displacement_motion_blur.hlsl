//#line 1 "source\rasterizer\hlsl\displacement_motion_blur.hlsl"

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"

//#define DISTORTION_MULTISAMPLED 1
#define LDR_ONLY 1

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

#include "displacement_registers.fx"

//@generate screen
LOCAL_SAMPLER_2D(displacement_sampler, 0);
LOCAL_SAMPLER_2D(ldr_buffer, 1);
#ifndef LDR_ONLY
LOCAL_SAMPLER_2D(hdr_buffer, 2);
#endif

LOCAL_SAMPLER_2D(distortion_depth_buffer, 3);

struct displacement_output
{
	float4 HPosition	:SV_Position;
	float4 Texcoord		:TEXCOORD0;
};

displacement_output default_vs(vertex_type IN)
{
    displacement_output OUT;

    OUT.HPosition.xy= IN.position;
    OUT.HPosition.zw= 1.0f;
	OUT.Texcoord.xy= IN.texcoord;
	OUT.Texcoord.zw= OUT.HPosition.xy;
	
    return OUT;
}

#if DX_VERSION == 9
static const float half_pixel_offset = 0.5f;
#elif DX_VERSION == 11
static const float half_pixel_offset = 0.0f;
#endif

accum_pixel default_ps(displacement_output IN, SCREEN_POSITION_INPUT(screen_coords)) : SV_Target0
{
	// Motion blur stuff
	float4 depth;
#ifndef pc
	asm
	{
		// note: Zbuf is stored in the texture on X360
		tfetch2D depth, screen_coords, distortion_depth_buffer, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#elif DX_VERSION == 11
	depth = distortion_depth_buffer.t.Load(int3(screen_coords.xy, 0)).x;
#else
	depth= sample2D(distortion_depth_buffer, (screen_coords + 0.5f) * screen_constants.xy).x; // note: (-Zcam) is stored in the texture on PC (original Zcam is negative)
	depth.x = zbuffer_xform.x / depth.x + zbuffer_xform.y; // Zbuf = -FN/(F-N) / z + F/(F-N)
#endif
	
	float2 screen_position= IN.Texcoord.zw;
	float4 clip_space_position= float4(screen_position.xy, depth.x, 1.0f);
	float4 world_space_position= mul(clip_space_position, transpose(screen_to_world));
	
	// turns out that using mul(vector, transpose(matrix)) is faster than pre-transposing it because the MADs use fewer GPRs than the DP4s, hence more threads
	float4 previous_world_space_position= float4(world_space_position.xyz /*- velocity.xyz * world_space_position.w*/, world_space_position.w); 
	float4 previous_screen_position= mul(previous_world_space_position, transpose(previous_view_projection));
	previous_screen_position/= previous_screen_position.w;
	
	const float2 max_blur= blur_max_and_scale.xy; 
	const float2 motion_blur_scale= blur_max_and_scale.zw; 
	
	float2 crosshair_relative_position= screen_position.xy - crosshair_center.xy;
	float center_falloff_scale_factor= min(1.0f, dot(crosshair_relative_position.xy, crosshair_relative_position.xy) * misc_values.w);
	
	float2 screen_position_delta= screen_position.xy - previous_screen_position.xy;
	screen_position_delta*= motion_blur_scale; // I optimized by premultiplying misc_values.y into the motion blur scale;
	
	float2 frame_texcoords= (screen_coords + half_pixel_offset) * screen_constants.xy;
	 
	if (do_distortion)
	{
		// This is the exact 0 displacement.  Need to get it exact for the "clip" to work.
#ifdef pc
		static float distortion_offset= 0x80/(float)0xff;
#else
		static float distortion_offset= 0x8000/(float)0xffff;
#endif
		static float max_displacement= 1.0f;	// if used, keep in sync with particle_render.hlsl
		float2 displacement= 2.0f * max_displacement * screen_constants.zw * (sample2D(displacement_sampler, IN.Texcoord).xy - distortion_offset);
#ifdef DISTORTION_MULTISAMPLED
		displacement*= 0.5f;	// Displacement is accumulated in pixel unit on 1/4-size buffer, applied on full-size buffer.
#endif
		frame_texcoords+= displacement;
	}
	
	float inverse_num_taps= 1.0f / misc_values.x;
	float2 uv_delta= inverse_num_taps * (max(min(screen_position_delta, max_blur), -max_blur));

	// no need to clamp anymore; we're not using sub-viewports
	// float2 current_texcoords= clamp(frame_texcoords, window_bounds.xy, window_bounds.zw);
	
	float2 current_texcoords= frame_texcoords;
	float4 center_color= sample2D(ldr_buffer, current_texcoords);
	center_color.a= 1-center_color.a;
	float4 accum_color= 0;
	
	float combined_weight= center_color.a * center_falloff_scale_factor;
	for (int i = 0; i < num_taps; ++ i)
	{
		current_texcoords+= uv_delta;
		float4 ldr_value= sample2D(ldr_buffer, current_texcoords);
		ldr_value.a= 1-ldr_value.a;
		accum_color.rgb+= ldr_value.rgb * ldr_value.a;
		accum_color.a+= ldr_value.a;
	}

	center_falloff_scale_factor = center_color.a * -center_falloff_scale_factor + 0.01;
	accum_color = center_falloff_scale_factor < 0.0f ? accum_color : 0.0f;
	
#if DX_VERSION == 11
	if (accum_color.a > 0)
#endif
	{	
		accum_color.rgb /= accum_color.a;
	}
		
	accum_pixel displaced_pixel;
	displaced_pixel.color= 0;
	float3 final_color= lerp(center_color, accum_color.rgb, combined_weight * accum_color.a * inverse_num_taps);
	displaced_pixel.color.rgb= final_color;
	
#ifndef LDR_ONLY
	displaced_pixel.dark_color= sample2D(hdr_buffer, frame_texcoords);
#endif

	return displaced_pixel;
}
