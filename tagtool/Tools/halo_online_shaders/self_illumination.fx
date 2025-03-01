
PARAM(float, self_illum_intensity);

float3 calc_self_illumination_none_ps(
	in float2 texcoord,
	inout float3 albedo_times_light,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	return float3(0.0f, 0.0f, 0.0f);
}

PARAM_SAMPLER_2D(self_illum_map);
PARAM(float4, self_illum_map_xform);
PARAM(float4, self_illum_color);

float3 calc_self_illumination_simple_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float4 result= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)) * self_illum_color;		// ###ctchou $PERF roll self_illum_intensity into self_illum_color
	result.rgb *= self_illum_intensity;
	
	return result.rgb;
}

float3 calc_self_illumination_simple_with_alpha_mask_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float4 result= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)) * self_illum_color;		// ###ctchou $PERF roll self_illum_intensity into self_illum_color
	result.rgb *= result.a * self_illum_intensity;
	
	return result.rgb;
}


PARAM_SAMPLER_2D(alpha_mask_map);
PARAM_SAMPLER_2D(noise_map_a);
PARAM_SAMPLER_2D(noise_map_b);
PARAM(float4, alpha_mask_map_xform);
PARAM(float4, noise_map_a_xform);
PARAM(float4, noise_map_b_xform);
PARAM(float4, color_medium);
PARAM(float4, color_sharp);
PARAM(float4, color_wide);
PARAM(float, thinness_medium);
PARAM(float, thinness_sharp);
PARAM(float, thinness_wide);

float3 calc_self_illumination_plasma_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float alpha=	sample2D(alpha_mask_map, transform_texcoord(texcoord, alpha_mask_map_xform)).a;
	float noise_a=	sample2D(noise_map_a, transform_texcoord(texcoord, noise_map_a_xform)).r;
	float noise_b=	sample2D(noise_map_b, transform_texcoord(texcoord, noise_map_b_xform)).r;

	float diff= 1.0f - abs(noise_a-noise_b);
	float medium_diff= pow(diff, thinness_medium);
	float sharp_diff= pow(diff, thinness_sharp);
	float wide_diff= pow(diff, thinness_wide);

	wide_diff-= medium_diff;
	medium_diff-= sharp_diff;
	
	float3 color= color_medium.rgb*color_medium.a*medium_diff + color_sharp.rgb*color_sharp.a*sharp_diff + color_wide.rgb*color_wide.a*wide_diff;
	
	return color*alpha*self_illum_intensity;
}

PARAM(float4, channel_a);
PARAM(float4, channel_b);
PARAM(float4, channel_c);

float3 calc_self_illumination_three_channel_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float4 self_illum= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform));

	self_illum.rgb=		self_illum.r	*	channel_a.a *	channel_a.rgb +
						self_illum.g	*	channel_b.a	*	channel_b.rgb +
						self_illum.b	*	channel_c.a	*	channel_c.rgb;

	return self_illum.rgb * self_illum_intensity;
}

float3 calc_self_illumination_from_albedo_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float3 self_illum= albedo*self_illum_color.xyz*self_illum_intensity;
	albedo= float3(0.f, 0.f, 0.f);
	
	return(self_illum);
}



PARAM_SAMPLER_2D(self_illum_detail_map);
PARAM(float4, self_illum_detail_map_xform);


float3 calc_self_illumination_detail_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float4 self_illum=			sample2D(self_illum_map,			transform_texcoord(texcoord, self_illum_map_xform));
	float4 self_illum_detail=	sample2D(self_illum_detail_map,		transform_texcoord(texcoord, self_illum_detail_map_xform));
	float4 result= self_illum * (self_illum_detail * DETAIL_MULTIPLIER) * self_illum_color;
	
	result.rgb *= self_illum_intensity;

	return result.rgb;
}

PARAM_SAMPLER_2D(meter_map);
PARAM(float4, meter_map_xform);
PARAM(float4, meter_color_off);
PARAM(float4, meter_color_on);
PARAM(float, meter_value);

float3 calc_self_illumination_meter_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float4 meter_map_sample= sample2D(meter_map, transform_texcoord(texcoord, meter_map_xform));
	return (meter_map_sample.x>= 0.5f)
		? (meter_value>= meter_map_sample.w)
			? meter_color_on.xyz 
			: meter_color_off.xyz
		: float3(0,0,0);
}

// PARAM(float3, primary_change_color);
PARAM(float, primary_change_color_blend);

float3 calc_self_illumination_times_diffuse_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float3 self_illum_texture_sample= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	
	float albedo_blend= max(self_illum_texture_sample.g * 10.0 - 9.0, 0.0);
	float3 albedo_part= albedo_blend + (1-albedo_blend) * albedo;
	float3 mix_illum_color = (primary_change_color_blend * primary_change_color.xyz) + ((1 - primary_change_color_blend) * self_illum_color.xyz);	
	float3 self_illum= albedo_part * mix_illum_color * self_illum_intensity * self_illum_texture_sample;
	
	return(self_illum);

}

float3 calc_self_illumination_holograms_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float3 self_illum_texture_sample= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	
	float albedo_blend= max(self_illum_texture_sample.g * 10.0 - 9.0, 0.0);
	float3 albedo_part= albedo_blend + (1-albedo_blend) * albedo;
	float3 self_illum= albedo_part * self_illum_color.xyz * self_illum_intensity * self_illum_texture_sample;
	
	return(self_illum);
}

float3 calc_self_illumination_change_color_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float3 self_illum_texture_sample= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	
	float3 mix_illum_color = (primary_change_color_blend * primary_change_color.xyz) + ((1 - primary_change_color_blend) * self_illum_color.xyz);	
	float3 self_illum= mix_illum_color * self_illum_intensity * self_illum_texture_sample;
	
	return(self_illum);

}

float3 calc_self_illumination_change_color_detail_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
    float4 self_illum = sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform));
    float4 self_illum_detail = sample2D(self_illum_detail_map, transform_texcoord(texcoord, self_illum_detail_map_xform));
    float4 result = self_illum * (self_illum_detail * DETAIL_MULTIPLIER);

    result.rgb *= primary_change_color * self_illum_intensity;

    return result.rgb;
}

PARAM_SAMPLER_2D(illum_index_map);
PARAM(float4, illum_index_map_xform);
PARAM(float, index_selection);
PARAM(float, left_falloff);
PARAM(float, right_falloff);
PARAM(float4, transform_xform);

float3 calc_self_illumination_palette_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float illum_index= sample2D(illum_index_map, transform_texcoord(texcoord, illum_index_map_xform)).x;
	
	float illum= (illum_index - index_selection);
	float falloff= (illum < 0.0f ? left_falloff : right_falloff);
	illum= 1.0f - pow(abs(illum), falloff);
	
	float3 self_illum= illum * self_illum_color.rgb * self_illum_intensity;
	
	return self_illum;
}

PARAM_SAMPLER_2D(opacity_map);
PARAM(float4, opacity_map_xform);
PARAM_SAMPLER_2D(walls);
PARAM(float4, walls_xform);
PARAM_SAMPLER_2D(floors);
PARAM(float4, floors_xform);
PARAM_SAMPLER_2D(ceiling);
PARAM(float4, ceiling_xform);
PARAM_SAMPLER_2D(window_property_map);
PARAM(float4, window_property_map_xform);
PARAM(float, distance_fade_scale);

float3 calc_self_illumination_window_room_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	// flip view direction to be incoming (pointing towards the surface)
    view_dir = -view_dir;

	// calculate the coordinate of the first wall we will intersect (x wall and y wall), by quantizing our current coordinate (and rounding up or down based on the view direction)
    float2 wall_coordinate_xy = (floor(texcoord.xy * transform_xform.xy + transform_xform.zw + 0.5f + sign(view_dir.xy) * 0.5f) - transform_xform.zw) / transform_xform.xy;
	
	// calculate the distance each of the walls
    float2 distance_xy = (wall_coordinate_xy - texcoord.xy) / view_dir.xy;

	// we hit the closest wall first.  calculate the intersection coordinates
    float3 intersection = float3(texcoord.xy, 0) + min(distance_xy.x, distance_xy.y) * view_dir.xyz;
	
	// sample our per-window property map (tint r,g,b and texture offset used to select room properties)
//	float4 window=				tex2D(window_property_map, transform_texcoord(texcoord, window_property_map_xform));
    float4 window = float4(1.0f, 1.0f, 1.0f, 0.0f);
	
    float4 color;
    if (distance_xy.x < distance_xy.y)
    {
        color = tex2D(walls, transform_texcoord(intersection.zy, walls_xform)); // + float2(0.0f, window.a));
//		asm {
//			tfetch2D color, wall_texcoord, walls, FetchValidOnly = false
//		}
    }
    else
    {
        if (view_dir.y > 0)
        {
            color = tex2D(floors, transform_texcoord(intersection.xz, floors_xform)); // + float2(window.a, 0.0f));
        }
        else
        {
            color = tex2D(ceiling, transform_texcoord(intersection.xz, ceiling_xform)); // + float2(window.a, 0.0f));
        }
    }

/*
	float4 color;
	float index= (distance_xy.x > distance_xy.y);		// walls = 0, floor = 1, ceiling = 2
	index= index + index * (view_dir.y > 0);
	
	float2 delta_index=		float2(ddx(index), ddy(index));
	[ifany]
	if (dot(delta_index, delta_index) > 0)
	{
		// sample all
		color=	float4(1.0f, 0.0f, 0.0f, 1.0f);
		float4 local_color[3];
		local_color[0]=	tex2D(walls,	transform_texcoord(intersection.zy, walls_xform));	// + float2(0.0f, window.a));
		local_color[1]=	tex2D(floors,	transform_texcoord(intersection.xz, floors_xform));	// + float2(window.a, 0.0f));
		local_color[2]=	tex2D(ceiling,	transform_texcoord(intersection.xz, ceiling_xform));	// + float2(window.a, 0.0f));
		color= local_color[index];
	}
	else
	{
		// can sample independently
		color=	float4(0.0f, 1.0f, 0.0f, 1.0f);
		if (index == 0)
		{
			color=	tex2D(walls,	transform_texcoord(intersection.zy, walls_xform));	// + float2(0.0f, window.a));
		}
		else if (index == 1)
		{	
			color=	tex2D(floors,	transform_texcoord(intersection.xz, floors_xform));	// + float2(window.a, 0.0f));
		}
		else
		{
			color=	tex2D(ceiling,	transform_texcoord(intersection.xz, ceiling_xform));	// + float2(window.a, 0.0f));
		}
	}
*/

    float falloff = saturate(1.0f + intersection.z * distance_fade_scale);
    float4 opacity = tex2D(opacity_map, transform_texcoord(texcoord, opacity_map_xform));
    return color.rgb * self_illum_intensity * falloff * opacity.rgb * window.rgb;
}
