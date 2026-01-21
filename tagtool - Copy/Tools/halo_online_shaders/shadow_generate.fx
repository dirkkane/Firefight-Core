#line 2 "source\rasterizer\hlsl\shadow_generate.fx"


#ifndef shadow_depth_map_1
//PARAM_SAMPLER_COMPARISON_2D(shadow_depth_map_1);
		sampler shadow_depth_map_1;
#endif


void shadow_generate_vs(
	in vertex_type vertex,
	out float4 screen_position : SV_Position,
//#ifdef pc	
//	out float4 screen_position_copy : TEXCOORD0,
//#endif // pc
	out float  depth : TEXCOORD0,
	out float2 texcoord : TEXCOORD1)
{
	float4 local_to_world_transform[3];
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, screen_position);

//#ifdef pc
//	screen_position_copy= screen_position;	
//#endif // pc
   depth= screen_position.w;
   texcoord= vertex.texcoord;
}

#if DX_VERSION == 9
accum_pixel shadow_generate_ps(
//#ifdef pc
//	in float4 screen_position : TEXCOORD0,
//#endif // pc
	SCREEN_POSITION_INPUT(screen_position),
	in float  depth : TEXCOORD0,
	in float2 texcoord : TEXCOORD1) : SV_Target
{
	float output_alpha;

#ifndef ALPHA_TEST_POST_ALBEDO
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);
#else
	float4 albedo;
    calc_albedo_ps(texcoord, albedo, float3(0,0,0), float4(0,0,0,0), float3(0,0,0), screen_position.xy);
	calc_alpha_test_ps(texcoord, output_alpha, albedo.a);
#endif

	float alpha= 1.0f;
#ifndef NO_ALPHA_TO_COVERAGE
	alpha= output_alpha;
#endif

//#ifdef pc
//	float buffer_depth= screen_position.z / screen_position.w;
//	return float4(buffer_depth, buffer_depth, buffer_depth, alpha);
//#else // xenon
	//return float4(1.0f, 1.0f, 1.0f, alpha);
	accum_pixel result;
	result.color = 1.0f;
	result.dark_color = depth;
	#ifdef SSR_ENABLE
		result.ssr_color = 0.0f;
	#endif
	return result;
//#endif // xenon
}
#elif DX_VERSION == 11
void shadow_generate_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float2 texcoord : TEXCOORD1)
{
	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);
	clip(output_alpha - 0.5);
}
#endif



#define PCF_WIDTH 4
#define PCF_HEIGHT 4

#ifdef pc
#ifdef APPLY_FIXES
#define pixel_size shadow_map_pixel_size		// shadow pixel size...  good thing we care about PC...
#else
#define pixel_size float2(1.0/512.0f, 1.0/512.0f)		// ###ctchou $TODO THIS NEEDS TO BE PASSED IN!!!
#endif
#endif

#include "texture.fx"


float sample_percentage_closer(float3 fragment_shadow_position, float depth_bias)
{
	float color= step(fragment_shadow_position.z, tex2D_offset_point(shadow_depth_map_1, fragment_shadow_position.xy, 0.0f, 0.0f).r);
	return color;
}


float sample_percentage_closer_PCF_3x3_block(float3 fragment_shadow_position, float depth_bias)					// 9 samples, 0 predicated
{
	float2 texel= fragment_shadow_position.xy;
	float4 blend= 1.0f;
	
	float4 max_depth= depth_bias;											// x= [0,0],    y=[-1/1,0] or [0,-1/1],     z=[-1/1,-1/1],		w=[-2/2,0] or [0,-2/2]
	max_depth *= float4(-1.0f, -sqrt(20.0f), -3.0f, -sqrt(26.0f));			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;
	
	float color=	blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, -1.0f).r) + 
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, -1.0f).r) +
					blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, -1.0f).r) +
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, +0.0f).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +0.0f).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, +0.0f).r) +
					blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, +1.0f).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +1.0f).r) +
					blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, +1.0f).r);
					
	return color / 9.0f;
}


float sample_percentage_closer_PCF_3x3_block_predicated(float3 fragment_shadow_position, float depth_bias)					// 9 samples, 5 predicated on 4
{
	float2 texel= fragment_shadow_position.xy;
	float4 blend= 1.0f;
	
	float4 max_depth= depth_bias;											// x= [0,0],    y=[-1/1,0] or [0,-1/1],     z=[-1/1,-1/1],		w=[-2/2,0] or [0,-2/2]
	max_depth *= float4(-1.0f, -sqrt(20.0f), -3.0f, -sqrt(26.0f));			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	float color=	
				step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, -1.0f).r) + 
				step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, -1.0f).r) +
				step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, +1.0f).r) +
				step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, +1.0f).r);
	
	if ((color > 0.1f) && (color < 3.9f))
	{
		color +=	step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, -1.0f).r) +
					step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, +0.0f).r) +
					step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +0.0f).r) +
					step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, +0.0f).r) +
					step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +1.0f).r);
		return color / 9.0f;
	}
	else
	{
		return color / 4.0f;
	}
}


float sample_percentage_closer_PCF_3x3_diamond_predicated(float3 fragment_shadow_position, float depth_bias)		// 13 samples, 9 predicated on 4
{
	float2 texel= fragment_shadow_position.xy;

	float4 max_depth= depth_bias;											// x= [0,0],    y=[-1/1,0] or [0,-1/1],     z=[-1/1,-1/1],		w=[-2/2,0] or [0,-2/2]
	max_depth *= float4(-1.0f, -sqrt(20.0f), -3.0f, -sqrt(26.0f));			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	float color= 
			step(max_depth.w, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, -2.0f).r) +
			step(max_depth.w, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +2.0f).r) +
			step(max_depth.w, tex2D_offset_point(shadow_depth_map_1, texel, -2.0f, +0.0f).r) +
			step(max_depth.w, tex2D_offset_point(shadow_depth_map_1, texel, +2.0f, +0.0f).r);
			
	if ((color > 0.1f) && (color < 3.9f))
	{
		float4 blend= 1.0f;
		color	+=		blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, -1.0f).r) + 
						1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, -1.0f).r) +
						blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, -1.0f).r) +
						blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, +0.0f).r) +
						1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +0.0f).r) +
						blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, +0.0f).r) +
						blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, -1.0f, +1.0f).r) +
						1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel, +0.0f, +1.0f).r) +
						blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel, +1.0f, +1.0f).r);
		
		return color / 13.0f;
	}
	else
	{
		return color / 4.0f;
	}
}


float sample_percentage_closer_PCF_5x5_block_predicated(float3 fragment_shadow_position, float depth_bias)
{
#if DX_VERSION == 9
	const float half_texel_offset = 0.5f;
#elif DX_VERSION == 11
	const float half_texel_offset = 0.0f;
#endif

	float2 texel1= fragment_shadow_position.xy;

	float4 blend;
#ifdef pc
	#ifdef TERRAIN_COMPILE_HACK // only defined in unit testing
		float2 frac_pos = fragment_shadow_position.x / pixel_size + half_texel_offset;
		blend.xy = frac_pos - floor(frac_pos); // ??? does not compile the same as below...
	#else
		float2 frac_pos = fragment_shadow_position.xy / pixel_size + half_texel_offset;
		blend.xy = frac(frac_pos);
	#endif
#else
#ifndef VERTEX_SHADER
//	fragment_shadow_position.xy += 0.5f;
	asm {
		getWeights2D blend.xy, fragment_shadow_position.xy, shadow_depth_map_1, MagFilter=linear, MinFilter=linear
	};
#endif
#endif
	blend.zw= 1.0f - blend.xy;

#define offset_0 (-2.0f + half_texel_offset)
#define offset_1 (-1.0f + half_texel_offset)
#define offset_2 (+0.0f + half_texel_offset)
#define offset_3 (+1.0f + half_texel_offset)

	float3 max_depth= depth_bias;							// x= central samples,   y = adjacent sample,   z= diagonal sample
	max_depth *= float3(-2.0f, -sqrt(5.0f), -4.0f);			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	// 4x4 point and 3x3 bilinear
	float color=	blend.z * blend.w * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel1, offset_0, offset_0).r) +
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_1, offset_0).r) +
					1.0f    * blend.w * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_2, offset_0).r) +
					blend.x * blend.w * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel1, offset_3, offset_0).r) +
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_0, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel1, offset_1, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel1, offset_2, offset_1).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_3, offset_1).r) +
					blend.z * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_0, offset_2).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel1, offset_1, offset_2).r) +
					1.0f    * 1.0f    * step(max_depth.x, tex2D_offset_point(shadow_depth_map_1, texel1, offset_2, offset_2).r) +
					blend.x * 1.0f    * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_3, offset_2).r) +
					blend.z * blend.y * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel1, offset_0, offset_3).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_1, offset_3).r) +
					1.0f    * blend.y * step(max_depth.y, tex2D_offset_point(shadow_depth_map_1, texel1, offset_2, offset_3).r) +
					blend.x * blend.y * step(max_depth.z, tex2D_offset_point(shadow_depth_map_1, texel1, offset_3, offset_3).r);

	color /= 9.0f;

	return color;
}


// #define DEBUG_CLIP

void shadow_apply_vs(
	in vertex_type vertex,
	out float4 screen_position : SV_Position,
	out float3 world_position : TEXCOORD0,
	out float2 texcoord : TEXCOORD1,
//	out float4 bump_texcoord : TEXCOORD2,		// UNUSED
	out float3 normal : TEXCOORD3,
	out float3 fragment_shadow_position : TEXCOORD4,
	out float3 extinction : COLOR0,
	out float3 inscatter : COLOR1)
{
	float4 local_to_world_transform[3];
	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, screen_position);

	world_position= vertex.position;
	// project vertex
	   texcoord= vertex.texcoord;
	normal= vertex.normal;
	
	compute_scattering(Camera_Position, vertex.position, extinction, inscatter);
	
	fragment_shadow_position.x= dot(float4(world_position, 1.0), v_lighting_constant_0);
	fragment_shadow_position.y= dot(float4(world_position, 1.0), v_lighting_constant_1);
	fragment_shadow_position.z= dot(float4(world_position, 1.0), v_lighting_constant_2);
}

accum_pixel shadow_apply_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float3 world_position : TEXCOORD0,
	in float2 texcoord : TEXCOORD1,
//	in float4 bump_texcoord : TEXCOORD2,
	in float3 normal : TEXCOORD3,
	in float3 fragment_shadow_position : TEXCOORD4,
	in float3 extinction : COLOR0,
	in float3 inscatter : COLOR1)
{
	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);

	// transform position by shadow projection
//	float3 fragment_shadow_position; // = transform_point(world_position, shadow_projection_1);
//	fragment_shadow_position.x= dot(float4(world_position, 1.0), p_lighting_constant_0);			// ###ctchou $TODO $PERF pass float4(world_position, 1.0) from vertex shader
//	fragment_shadow_position.y= dot(float4(world_position, 1.0), p_lighting_constant_1);			// ###ctchou $TODO $PERF or even better - do this transformation in the vertex shader
//	fragment_shadow_position.z= dot(float4(world_position, 1.0), p_lighting_constant_2);			// ###ctchou $TODO $PERF and pass the transformed point to the pixel shader

	// compute maximum slope given normal
	normal.xyz= normalize(normal.xyz);
	float3 light_dir= normalize(p_lighting_constant_2.xyz);											// ###ctchou $TODO $PERF pass additional normalized version of this into shader
	float cosine= -dot(normal.xyz, light_dir);														// transform normal into 'lighting' space (only Z component - equivalent to normal dot lighting direction)
	
	   // compute the bump normal in local tangent space												// shadows do not currently respect bump
//	float3 bump_normal_in_tangent_space;
//	calc_bumpmap_ps(texcoord, bump_texcoord, bump_normal_in_tangent_space);
	// rotate bump to world space (same space as lightprobe) and normalize
//	float3 bump_normal= normalize( mul(bump_normal_in_tangent_space, tangent_frame) );
	
	float shadow_darkness;																			// ###ctchou $TODO pass this in (based on ambientness of the lightprobe)
	
	// compute shadow falloff as a function of the z depth (distance from front shadow volume plane), and the incident angle from lightsource (cosine falloff)
	float shadow_falloff= max(0.0f, fragment_shadow_position.z*2-1);								// shift z-depth falloff to bottom half of the shadow volume (no depth falloff in top half)
	shadow_falloff *= shadow_falloff;																// square depth
	shadow_darkness= k_ps_constant_shadow_alpha.r * (1-shadow_falloff*shadow_falloff) * max(0.0f, cosine);		// z_depth_falloff= 1 - (shifted_depth)^4,	incident_falloff= cosine lobe

	float darken= 1.0f;
	if (shadow_darkness > 0.001)																	// if maximum shadow darkness is zero (or very very close), don't bother doing the expensive PCF sampling
	{
		// sample shadow depth
		float percentage_closer= sample_percentage_closer_PCF_3x3_block(fragment_shadow_position, /*unused*/ 0.0f);
	
		// compute darkening
		darken= 1-shadow_darkness + percentage_closer * shadow_darkness;
		darken*= darken;
	}
//	else
//	{
//		clip(-1.0f);		// DEBUG - to clip regions that aren't calculated						// ###ctchou $TODO $PERF - putting this clip in might improve performance if we're alpha-blend bound (unlikely)
//	}
	
	
	// the destination contains (pixel * extinction + inscatter) - we want to change it to (pixel * darken * extinction + inscatter)
	// so we multiply by darken (aka src alpha), and add inscatter * (1-darken)
	return convert_to_render_target(float4(inscatter*g_exposure.rrr, darken), true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}
