#line 1 "source\rasterizer\hlsl\player_emblem.fx"
/*
player_emblem.fx
Copyright (c) Microsoft Corporation, 2007. All rights reserved.
Friday February 23, 2007, 12:05pm Stefan S.

For Halo3, player emblems have 3 components:
1) background channel, modulated by emblem background color
2) foreground channel #1, modulated by emblem foreground color #1
3) foreground channel #2, modulated by emblem foreground color #2 - this channel can be optionally disabled

The artwork is being setup as follows:
* all channels packed into a single bitmap
* blue channel is for emblem background icons
* green channel is for emblem foreground channel #1
* red channel is for emblem foreground channel #2
* 2 texture samplers needed, since foreground & background emblem indices are independent,
  even though they will come from the same bitmap group
*/

#ifndef __PLAYER_EMBLEM_FX__
#define __PLAYER_EMBLEM_FX__

/* ---------- headers */

#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "player_emblem_registers.fx"

/* ---------- constants */

// the setting of these constants controls the shader output
// in the game shell UI, the UI rendering code for emblems would set the appropriate shader constants
// for rendering on the in-game player, the desire would be to have object functions used to set these
// the 3 bool constants are stored in alpha channels of the color components
// passed into the shaders b/c no way to get bool values into shaders from object functions
LOCAL_SAMPLER_2D(tex0_sampler, 0);
LOCAL_SAMPLER_2D(tex1_sampler, 1);

/* ---------- private code */

static float get_emblem_pixel_for_channel(float channel_value, bool flip)
{
	if (flip)
	{
		channel_value= 1.f-channel_value;
	}
	
	return channel_value;
}

static float4 generate_emblem_pixel(float2 texcoord) : COLOR
{	
	/*
	tex0_sampler == emblem background texture bitmap, ARGB format (NOTE: alpha channel ignored)
	tex1_sampler == emblem foreground texture bitmap, ARGB format (NOTE: alpha channel ignored)
	emblem_pixel.b == background icon
	emblem_pixel.g == foreground icon 1
	emblem_pixel.r == foreground icon 2 - can be toggled on or off (emblem_alternate_foreground_channel_enabled)
	emblem_pixel.a == boolean flag :
		emblem_color_background.a == "emblem_alternate_foreground_channel_enabled"
		emblem_color_icon1.a == "emblem_flip_foreground"
		emblem_color_icon2.a == "emblem_flag_flip_background"
	*/
	
	bool emblem_alternate_foreground_channel_enabled= (emblem_color_background_argb.a!=0);
	bool emblem_flip_foreground= (emblem_color_icon1_argb.a!=0);
	bool emblem_flip_background= (emblem_color_icon2_argb.a!=0);
	
	// foreground channel(s), weighted by alpha
	float4 fore_pixel= float4(0.0f, 0.0f, 0.0f, 0.0f);
	{
		float4 emblem_foreground_pixel= sample2D(tex1_sampler, texcoord);
		float value= get_emblem_pixel_for_channel(emblem_foreground_pixel.g, emblem_flip_foreground);
		fore_pixel.rgb= emblem_color_icon1_argb.rgb * value;
		fore_pixel.a= value;
		
		// blend alternate foreground channel over original
		if (emblem_alternate_foreground_channel_enabled)
		{
			float value= get_emblem_pixel_for_channel(emblem_foreground_pixel.r, emblem_flip_foreground);
			fore_pixel.rgb= fore_pixel.rgb * (1-value) + emblem_color_icon2_argb.rgb * value;
			fore_pixel.a= saturate(fore_pixel.a + value);
		}
	}

	// background channel
	float back_pixel;
	{
		float4 emblem_background_pixel= sample2D(tex0_sampler, texcoord);
		back_pixel= get_emblem_pixel_for_channel(emblem_background_pixel.b, emblem_flip_background);
	}
	
	// blend foreground over background
	float4 out_pixel;
	out_pixel.rgb= emblem_color_background_argb.rgb * back_pixel * (1-fore_pixel.a) + fore_pixel.rgb;
	out_pixel.a= saturate(back_pixel + fore_pixel.a);
	
	// normalize color for alpha blend	
	out_pixel.rgb/= max(out_pixel.a, 0.001f);
	
	return out_pixel;
}

#endif //__PLAYER_EMBLEM_FX__
