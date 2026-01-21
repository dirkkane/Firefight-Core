//#line 2 "source\rasterizer\hlsl\shadow_apply.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "deform.fx"
#include "utilities.fx"
#include "atmosphere.fx"
#include "shadow_apply_registers.fx"

#ifndef SAMPLE_PERCENTAGE_CLOSER
#define SAMPLE_PERCENTAGE_CLOSER sample_percentage_closer_PCF_3x3_block
#endif // SAMPLE_PERCENTAGE_CLOSER

LOCAL_SAMPLER_2D(zbuffer, 0);
LOCAL_SAMPLER_2D(shadow, 1);
LOCAL_SAMPLER_2D(normal_buffer, 2);

#define CAMERA_TO_SHADOW_PROJECTIVE_X p_lighting_constant_0
#define CAMERA_TO_SHADOW_PROJECTIVE_Y p_lighting_constant_1
#define CAMERA_TO_SHADOW_PROJECTIVE_Z p_lighting_constant_2

#define INSCATTER_SCALE		p_lighting_constant_3
#define INSCATTER_OFFSET	p_lighting_constant_4

#define zbuffer_xform p_lighting_constant_6
#define screen_xform p_lighting_constant_7

#define ZBUFFER_SCALE (p_lighting_constant_8.r)
#define ZBUFFER_BIAS (p_lighting_constant_8.g)
#define SHADOW_PIXELSIZE (p_lighting_constant_8.b)
#define ZBUFFER_PIXELSIZE (p_lighting_constant_8.a)

#define SHADOW_DIRECTION_WORLDSPACE (p_lighting_constant_9.xyz)

//@generate tiny_position_only
//@entry default
//@entry albedo


#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"


#ifdef pc
#ifdef APPLY_FIXES
#define pixel_size shadow_map_pixel_size		// shadow pixel size...  good thing we care about PC...
#else
#define pixel_size float2(1.0/512.0f, 1.0/512.0f)		// ###ctchou $TODO THIS NEEDS TO BE PASSED IN!!!
#endif
#endif
#include "texture.fx"


#include "texture_xform.fx"

// default for hard shadow
void default_vs(
	in vertex_type vertex,
	out float4 screen_position : SV_Position)
{
    float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(vertex, local_to_world_transform);
	}
	
	if (always_true)
	{
		screen_position= mul(float4(vertex.position, 1.0f), View_Projection);
	}
	else
	{
		screen_position= float4(0,0,0,0);
	}
}


float sample_percentage_closer_PCF_3x3_block(float3 fragment_shadow_position, float depth_bias)					// 9 samples, 0 predicated
{
#ifndef pc
	[isolate]		// optimization - reduces GPRs
#endif // !pc

	float2 texel= fragment_shadow_position.xy;

	float4 blend= 1.0f;
	float scale= 1.0f / 9.0f;
	
//#ifdef BILINEAR_SHADOWS
#ifndef VERTEX_SHADER
   #ifdef pc
      float2 frac_pos = fragment_shadow_position.xy / pixel_size;
      blend.xy = frac(frac_pos);
   #else
	   asm {
		   getWeights2D blend.xy, fragment_shadow_position.xy, shadow, MagFilter=linear, MinFilter=linear, OffsetX=0.5, OffsetY=0.5
	   };
   #endif
	blend.zw= 1.0f - blend.xy;
	scale = 1.0f / 4.0f;
#endif // VERTEX_SHADER
//#endif // BILINEAR_SHADOWS

	
	float4 max_depth= depth_bias;											// x= [0,0],    y=[-1/1,0] or [0,-1/1],     z=[-1/1,-1/1],		w=[-2/2,0] or [0,-2/2]
	max_depth *= float4(-1.0f, -sqrt(20.0f), -3.0f, -sqrt(26.0f));			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	float color=	blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel, -1.0f, -1.0f).r) + 
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow, texel, +0.0f, -1.0f).r) +
					blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow, texel, +1.0f, -1.0f).r) +
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel, -1.0f, +0.0f).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow, texel, +0.0f, +0.0f).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow, texel, +1.0f, +0.0f).r) +
					blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel, -1.0f, +1.0f).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow, texel, +0.0f, +1.0f).r) +
					blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow, texel, +1.0f, +1.0f).r);

	return color * scale;
}



accum_pixel default_ps(
	SCREEN_POSITION_INPUT(pixel_pos))
{
#ifdef pc
	float2 texture_pos= transform_texcoord(pixel_pos.xy, zbuffer_xform);
#else
	pixel_pos.xy += p_tiling_vpos_offset.xy;
	float2 texture_pos= transform_texcoord(pixel_pos.xy, zbuffer_xform);
#endif

	float pixel_depth= sample2D(zbuffer, texture_pos).r;
#if defined(pc) && (DX_VERSION == 9)
	pixel_depth = -pixel_depth;
#else 
	pixel_depth = 1.0f / (pixel_depth * ZBUFFER_SCALE + ZBUFFER_BIAS);					// convert to 'true' depth		(z)
#endif

	// calculate projected screen position
	float4 screen_position= float4(transform_texcoord(pixel_pos.xy, screen_xform) * pixel_depth, pixel_depth, 1.0f);
	
/*
	// GRADIENT NORMAL - not used cuz we have normal buffers now

	float4 fragment_shadow_position;
	fragment_shadow_position.x= dot(screen_position, CAMERA_TO_SHADOW_X);
	fragment_shadow_position.y= dot(screen_position, CAMERA_TO_SHADOW_Y);
	fragment_shadow_position.z= dot(screen_position, CAMERA_TO_SHADOW_Z);
	fragment_shadow_position.w= 1.0f;

	float3 shadow_gradient_x= ddx(fragment_shadow_position.xyz);
	float3 shadow_gradient_y= ddy(fragment_shadow_position.xyz);
	float3 normal_shadow_space= normalize(cross(shadow_gradient_y, shadow_gradient_x));
	float cosine= normal_shadow_space.z;
*/

	// NOTE: if we want projective shadows, do this dot product and divide x,y,z by w
	float3 fragment_shadow_projected;
	fragment_shadow_projected.x= dot(screen_position, CAMERA_TO_SHADOW_PROJECTIVE_X);				
	fragment_shadow_projected.y= dot(screen_position, CAMERA_TO_SHADOW_PROJECTIVE_Y);
	fragment_shadow_projected.z= dot(screen_position, CAMERA_TO_SHADOW_PROJECTIVE_Z);
	
   //float3 texel = fragment_shadow_projected;
   //float sh_res = sample2D(shadow, texel.xy).r;
   //sh_res = sh_res > texel.z;
   //return convert_to_render_target(float4(sh_res, 0.0, 0.0, 0.0), false, true);

	float3 normal_world_space= sample2D(normal_buffer, texture_pos).xyz * 2.0f - 1.0f;										// ###ctchou $PERF bias this in the texture format
	float cosine= dot(normal_world_space, SHADOW_DIRECTION_WORLDSPACE.xyz);

	float shadow_falloff= saturate(fragment_shadow_projected.z*2-1);													// shift z-depth falloff to bottom half of the shadow volume (no depth falloff in top half)
	shadow_falloff *= shadow_falloff;																					// square depth
	
#ifdef DOUBLE_COSINE
	float cosine_falloff= saturate(cosine) * saturate(cosine);
#else
	float cosine_falloff= saturate(cosine);
#endif
	
	float shadow_darkness= k_ps_constant_shadow_alpha.r * (1-shadow_falloff*shadow_falloff) * cosine_falloff;			// z_depth_falloff= 1 - (shifted_depth)^4,    incident_falloff= cosine lobe
	
	float darken= 1.0f;
#ifndef pc
	[predicateBlock]
//	[predicate]
//	[branch]
#endif // !pc

	if (shadow_darkness > 0.001)		// if maximum shadow darkness is zero (or very very close), don't bother doing the expensive PCF sampling
	{
		// calculate depth_bias (the maximum allowed depth_disparity within a single pixel)
		//		depth_bias = maximum_fragment_slope * half_pixel_size
		//      maximum fragment slope is the magnitude of the surface gradient with respect to shadow-space-Z (basically, glancing pixels have high slope)
		//      half pixel size is the distance in world space from the center of a shadow pixel to a corner (dotted line in diagram)
		//          ___________
		//         |         .'|
		//         |       .'  |
		//         |     .'    |
		//         |           |
		//         |___________|
		//
		//		the basic idea is:  we know the current fragment is within half_pixel_size of the center of this pixel in the shadow projection
		//							the depth map stores the Z value of the center of the pixel, we want to determine what the Z value is at our projection
		//							our simple approximation is to assume it is at the farthest point in the pixel, and do the compare at that point

#if /*(defined(pc) && (DX_VERSION == 9)) || */(! defined(FASTER_SHADOWS))
		cosine= max(cosine, 0.24253562503633297351890646211612);									// limits max slope to 4.0, and prevents divide by zero  ###ctchou $REVIEW could make this (4.0) a shader parameter if you have trouble with the masterchief's helmet not shadowing properly
		float slope= sqrt(1-cosine*cosine) / cosine;												// slope == tan(theta) == sin(theta)/cos(theta) == sqrt(1-cos^2(theta))/cos(theta)
		slope= slope + 0.2f;
#else
		float slope= 0.0f;
#endif // FASTER_SHADOWS

		float half_pixel_size= SHADOW_PIXELSIZE;													// the texture coordinate distance from the center of a pixel to the corner of the pixel
		float depth_bias= slope * half_pixel_size;
			
		// sample shadow depth
		float percentage_closer= SAMPLE_PERCENTAGE_CLOSER(fragment_shadow_projected.xyz, depth_bias);
		
		// compute darkening
		darken= saturate(1.01-shadow_darkness + percentage_closer * shadow_darkness);		// 1.001 to fix round off error..  (we want to ensure we output at least 1.0 when percentage_closer= 1, not 0.9999)
		darken*= darken;
	}
	
	//return convert_to_render_target(float4(shadow_darkness, 0.0, 0.0, 0.0), false, true);

	// compute inscatter
	float3 inscatter= -pixel_depth * INSCATTER_SCALE + INSCATTER_OFFSET;
	
	//return convert_to_render_target(float4(normal_world_space, 0.0), false, true);
	
	// the destination contains (pixel * extinction + inscatter) - we want to change it to (pixel * darken * extinction + inscatter)
	// so we multiply by darken (aka src alpha), and add inscatter * (1-darken)
	return convert_to_render_target(float4(inscatter * g_exposure.rrr, darken), false, true		// Note: the (inscatter*(1-darken)) clamping is not correct, but only when the inscatter is HDR already - in which case you can't see anything anyways
				#ifdef SSR_ENABLE
				, 0.0f
				#endif
				);
				// ###ctchou $PERF multiply inscatter by g_exposure before passing to this shader  :)
}


// albedo for ambient blur shadow

void albedo_vs(
	in vertex_type vertex,
	out float4 screen_position : POSITION)
{
    float4 local_to_world_transform[3];
	if (always_true)
	{
		deform(vertex, local_to_world_transform);
	}
	
	if (always_true)
	{
		screen_position= mul(float4(vertex.position, 1.0f), View_Projection);
	}
	else
	{
		screen_position= float4(0,0,0,0);
	}
}


#ifdef pc
#define		SPHERE_DATA(index, offset, registers)	occlusion_spheres[k_occlusion_sphere_stride * index + offset].registers
#else
#define		SPHERE_DATA(index, offset, registers)	occlusion_spheres[index + offset].registers
#endif

#define		SPHERE_CENTER(index)			SPHERE_DATA(index, 0, xyz)
#define		SPHERE_AXIS(index)				SPHERE_DATA(index, 1, xyz)
#define		SPHERE_RADIUS_SHORTER(index)	SPHERE_DATA(index, 0, w)
#define		SPHERE_RADIUS_LONGER(index)		SPHERE_DATA(index, 1, w)

accum_pixel albedo_ps(
	SCREEN_POSITION_INPUT(pixel_pos))
{
	// get world position of current pixel	
#ifndef pc	
	pixel_pos.xy += p_tiling_vpos_offset.xy;
#endif	
	float2 texture_pos= transform_texcoord(pixel_pos.xy, zbuffer_xform);	
	float pixel_depth= sample2D(zbuffer, texture_pos).r; // todo: do we need to transform this depth? [11/15/2012 paul.smirnov]
#if defined(pc) && (DX_VERSION == 9)
	pixel_depth = -(1 / pixel_depth + ZBUFFER_BIAS) / ZBUFFER_SCALE;
#endif	
	float4 world_position= float4(transform_texcoord(pixel_pos.xy, screen_xform), pixel_depth, 1.0f);
	world_position= mul(world_position, view_inverse_matrix);
	world_position.xyz/= world_position.w;

	float percentage_closer= 1.0f;
	[loop]
	for (int sphere_index= 0; sphere_index < occlusion_spheres_count; sphere_index++)
	{
		//float3 sphere_center= SPHERE_CENTER(sphere_index);
		float3 ellipse_center= SPHERE_CENTER(sphere_index);
		float3 ellipse_axis= SPHERE_AXIS(sphere_index);
		float ellipse_radius_shorter= SPHERE_RADIUS_SHORTER(sphere_index);
		float ellipse_radius_longer= SPHERE_RADIUS_LONGER(sphere_index);

		float3 center_to_pixel_direction= ellipse_center-world_position.xyz;		
		float center_to_pixel_distance= length(center_to_pixel_direction);

		// darken by distance along light path
		float darken= 0.0f;
		{
			float3 light_to_cent= cross(center_to_pixel_direction, SHADOW_DIRECTION_WORLDSPACE);
			float light_to_cent_length= length(light_to_cent);

			// normalize light to center vector
			light_to_cent/= light_to_cent_length;
			float along_axis= abs( dot(light_to_cent, ellipse_axis) );
			float radius= lerp(ellipse_radius_shorter, ellipse_radius_longer, along_axis);

			// compute darken			
			float ratio= max(light_to_cent_length / radius, 0.5f);
			//ratio= sqrt(ratio);
			darken= saturate( 1.0f - 0.3f * ratio);		
		}

		// influence by distance and normal direction
		float influence= 0.0f;
		{
			// normalize direction
			center_to_pixel_direction/= center_to_pixel_distance;
			float radius= ellipse_radius_shorter;

			// compute influence			
			//influence= saturate(radius / center_to_pixel_distance);			
			influence= saturate(1.0f - 0.2f * center_to_pixel_distance / radius);			
			//influence*= influence;

			float avoid_self_shadow= saturate(-0.2f + 1.2f*dot(center_to_pixel_direction, SHADOW_DIRECTION_WORLDSPACE));
			influence*= avoid_self_shadow ;
		}

		//percentage_closer= min(percentage_closer, 1.0f - darken * influence);
		percentage_closer*= 1.0f - darken * influence;
	}

	float3 normal_world_space= sample2D(normal_buffer, texture_pos).xyz * 2.0f - 1.0f;										// ###ctchou $PERF bias this in the texture format
	float cosine= dot(normal_world_space, SHADOW_DIRECTION_WORLDSPACE.xyz);
	float shadow_darkness= k_ps_constant_shadow_alpha.r * saturate(0.6f + 0.4f * cosine);			// z_depth_falloff= 1 - (shifted_depth)^4,    incident_falloff= cosine lobe

	//float shadow_darkness= k_ps_constant_shadow_alpha.r * 0.8;
	

	float darken= 1.0f;
	if (shadow_darkness > 0.001)		// if maximum shadow darkness is zero (or very very close), don't bother doing the expensive PCF sampling
	{		
		// compute darkening
		darken= saturate(1.01-shadow_darkness + percentage_closer * shadow_darkness);		// 1.001 to fix round off error..  (we want to ensure we output at least 1.0 when percentage_closer= 1, not 0.9999)
		darken*= darken;
	}	

	// compute inscatter
#if defined(pc) && (DX_VERSION == 9)
	float3 inscatter= -(1.0f - pixel_depth) * INSCATTER_SCALE + INSCATTER_OFFSET;
#else
	float3 inscatter= -pixel_depth * INSCATTER_SCALE + INSCATTER_OFFSET;
#endif

	// the destination contains (pixel * extinction + inscatter) - we want to change it to (pixel * darken * extinction + inscatter)
	// so we multiply by darken (aka src alpha), and add inscatter * (1-darken)
	return convert_to_render_target(float4(inscatter * g_exposure.rrr, darken), false, true
				#ifdef SSR_ENABLE
				, 0.0f
				#endif
				);		// Note: the (inscatter*(1-darken)) clamping is not correct, but only when the inscatter is HDR already - in which case you can't see anything anyways
	// ###ctchou $PERF multiply inscatter by g_exposure before passing to this shader  :)
}
