
PARAM(float, layer_depth);
PARAM(float, layer_contrast);
PARAM(float, texcoord_aspect_ratio);			// how stretched your texcoords are

PARAM(float, depth_darken);

#if DX_VERSION == 9
PARAM(int, layers_of_4);
#elif DX_VERSION == 11
PARAM(float, layers_of_4);
#endif

float3 calc_self_illumination_multilayer_ps(
	in float2 texcoord,
	inout float3 albedo_times_light,
	float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	texcoord= transform_texcoord(texcoord, self_illum_map_xform);				// transform texcoord first
	
//	texcoord -= view_dir.xy * (layer_depth / 2.0f);
	float2 offset= view_dir.xy * self_illum_map_xform.xy * float2(texcoord_aspect_ratio, 1.0f) * layer_depth / (layers_of_4 * 4);
	
	float4 accum= float4(0.0f, 0.0f, 0.0f, 0.0f);
#ifndef pc
//	[unroll]
#endif
	float depth_intensity= 1.0f;
	for (int x= 0; x < layers_of_4; x++)
	{
		accum += depth_intensity * sample2D(self_illum_map, texcoord);
		texcoord -= offset;	depth_intensity *= depth_darken;
		accum += depth_intensity * sample2D(self_illum_map, texcoord);
		texcoord -= offset;	depth_intensity *= depth_darken;
		accum += depth_intensity * sample2D(self_illum_map, texcoord);
		texcoord -= offset;	depth_intensity *= depth_darken;
		accum += depth_intensity * sample2D(self_illum_map, texcoord);
		texcoord -= offset;	depth_intensity *= depth_darken;
	}
	
	accum.rgba /= (layers_of_4 * 4);
	
	float4 result;
	result.rgb= pow(accum.rgb, layer_contrast) * self_illum_color * self_illum_intensity;
	result.a= accum.a * self_illum_color.a;
	return result.rgb;
}


PARAM_SAMPLER_2D(illum_depth_map);
PARAM(float4, illum_depth_map_xform);


float3 calc_self_illumination_multilayer_depth_ps(
	in float2 texcoord,
	inout float3 albedo_times_light,
	float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float4 tex_depth= sample2D(illum_depth_map, transform_texcoord(texcoord, illum_depth_map_xform));

	texcoord= transform_texcoord(texcoord, self_illum_map_xform);				// transform texcoord first
	
//	texcoord -= view_dir.xy * (layer_depth / 2.0f);
	float2 offset= view_dir.xy * self_illum_map_xform.xy * float2(texcoord_aspect_ratio, 1.0f) * layer_depth / (layers_of_4 * 4);
	
	float4 accum= float4(0.0f, 0.0f, 0.0f, 0.0f);
#ifndef pc
//	[unroll]
#endif
	for (int x= 0; x < layers_of_4; x++)
	{
		accum += sample2D(self_illum_map, texcoord);
		texcoord -= offset;
		accum += sample2D(self_illum_map, texcoord);
		texcoord -= offset;
		accum += sample2D(self_illum_map, texcoord);
		texcoord -= offset;
		accum += sample2D(self_illum_map, texcoord);
		texcoord -= offset;
	}
	
	accum.rgba /= (layers_of_4 * 4);
	
	float4 result;
	result.rgb= pow(accum.rgb, layer_contrast) * self_illum_color.rgb * self_illum_intensity;
	result.a= accum.a * self_illum_color.a;
	return result.rgb;
}




float3 calc_self_illumination_multilayer_cheap_ps(
	in float2 texcoord,
	inout float3 albedo_times_light,
	float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	texcoord= transform_texcoord(texcoord, self_illum_map_xform);				// transform texcoord first
	
	float2 offset= view_dir.xy * self_illum_map_xform.xy * float2(texcoord_aspect_ratio, 1.0f) * layer_depth / (layers_of_4 * 4);
	
	float4 accum= float4(0.0f, 0.0f, 0.0f, 0.0f);
#ifdef pc
	accum += sample2D(self_illum_map, texcoord);
#else // XENON

	float4 delta_h=	{offset.x, offset.y, 0.0f, 0.0f};
	float4 delta_v= {0.0f, 0.0f, 0.0f, 0.0f};

	float4 value= 0.0f;
	asm {
		setGradientH delta_h
		setGradientV delta_v
		tfetch2D value, texcoord, self_illum_map, MinFilter=point, MagFilter=point, MipFilter=point, AnisoFilter=max16to1, UseRegisterGradients=true, UseComputedLOD=false
	};

	accum += value;

#endif
	
	accum.rgba /= (layers_of_4 * 4);
	
	float4 result;
	result.rgb= pow(accum.rgb, layer_contrast) * self_illum_color.rgb * self_illum_intensity;
	result.a= accum.a * self_illum_color.a;
	return result.rgb;
}


PARAM(float3, self_illum_heat_color);
PARAM(float2, z_camera_pixel_size);

float3 calc_self_illumination_scope_blur_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	texcoord= transform_texcoord(texcoord, self_illum_map_xform);
	float4 color_0, color_1, color_2, color_3;
	
#ifdef pc
	#ifdef APPLY_FIXES
		float2 texStep= z_camera_pixel_size.xy / 2.0f;
	#else
		float2 texStep= float2(0.001736 / 2.0, 0.003125 / 2.0); // texStep = rcp(1152x640 / 2) / 2.0f
	#endif
		
 	color_0= sample2D(self_illum_map, float2(texcoord.x + texStep.x, texcoord.y + texStep.y));
	color_1= sample2D(self_illum_map, float2(texcoord.x - texStep.x, texcoord.y + texStep.y));
	color_2= sample2D(self_illum_map, float2(texcoord.x - texStep.x, texcoord.y - texStep.y));
	color_3= sample2D(self_illum_map, float2(texcoord.x + texStep.x, texcoord.y - texStep.y));
#else
 
	asm
	{
		tfetch2D color_0, texcoord, self_illum_map, OffsetX=  0.5f, OffsetY=  0.5f
		tfetch2D color_1, texcoord, self_illum_map, OffsetX= -0.5f, OffsetY=  0.5f
		tfetch2D color_2, texcoord, self_illum_map, OffsetX= -0.5f, OffsetY= -0.5f
		tfetch2D color_3, texcoord, self_illum_map, OffsetX=  0.5f, OffsetY= -0.5f
	};
#endif
	float2 average= (color_0 + color_1 + color_2 + color_3).xy * 0.25f;
	float3 color= average.r * self_illum_color.rgb + (1.0f - average.r) * average.g * self_illum_heat_color;
	return (color * self_illum_intensity);
}


//PIXEL_CONSTANT(float3, depth_constants, c201);
//PIXEL_CONSTANT (sampler, depth_buffer, s11);

float4	global_depth_constants;
float3	global_camera_forward;

float compute_depth_fade(float2 screen_coords, float depth, float range, float view_dot_normal)
{
#if BLEND_MODE(opaque)
	return 1;
#else //!opaque	
	float4 depth_value;
#ifdef pc
 	depth_value= tex2D(depth_buffer, (screen_coords + 0.5f) / texture_size.xy);
#else	
	asm {
		tfetch2D depth_value, screen_coords, depth_buffer, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#endif
//	float scene_depth= 1.0f - depth_value.x;
//	scene_depth= 1.0f / (global_depth_constants.x + scene_depth * global_depth_constants.y);	// convert to real depth
				
#ifdef pc
	float scene_depth= depth_value.x;	// convert to real depth
#else
	float scene_depth= 1.0f / (global_depth_constants.z - depth_value.x * global_depth_constants.y);	// convert to real depth
#endif
	float particle_depth= depth;
	float delta_depth= scene_depth - particle_depth;
	return saturate(delta_depth * view_dot_normal / range);
#endif //opaque mode	
}


float alpha_modulation_factor;

sampler palette;
float4 palette_xform;
float depth_fade_range;
float v_coordinate;

float3 calc_self_illumination_palettized_plasma_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float noise_a=	tex2D(noise_map_a,	transform_texcoord(texcoord, noise_map_a_xform)).r;
	float noise_b=	tex2D(noise_map_b,	transform_texcoord(texcoord, noise_map_b_xform)).r;
	float index=	abs(noise_a - noise_b);

	float alpha=	tex2D(alpha_mask_map, transform_texcoord(texcoord, alpha_mask_map_xform)).a;

	float depth_fade_alpha=	compute_depth_fade(fragment_position, abs(dot(fragment_to_camera_world, global_camera_forward)), depth_fade_range, view_dot_normal);		// length(fragment_to_camera_world)

	index=	saturate(index + (1-alpha*depth_fade_alpha) * alpha_modulation_factor);

	float4 palette_value=	sample2D(palette, float2(index, v_coordinate));

	return palette_value.rgb * self_illum_color.rgb * self_illum_intensity;
}



float3 calc_self_illumination_palettized_depth_fade_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir,
	in float2 fragment_position,
	in float3 fragment_to_camera_world,
	in float view_dot_normal)
{
	float index=	sample2D(noise_map_a,	transform_texcoord(texcoord, noise_map_a_xform)).r;
	float alpha=	sample2D(alpha_mask_map, transform_texcoord(texcoord, alpha_mask_map_xform)).a;

	float depth_fade_alpha=	compute_depth_fade(fragment_position, abs(dot(fragment_to_camera_world, global_camera_forward)), depth_fade_range, view_dot_normal);		// length(fragment_to_camera_world)
	index=	saturate(index + (1-alpha*depth_fade_alpha) * alpha_modulation_factor);

	float4 palette_value=	sample2D(palette, float2(index, v_coordinate));

	return palette_value.rgb * self_illum_color.rgb * self_illum_intensity;
}

