#include "texture_xform.fx"

PARAM_SAMPLER_2D(bump_map);
PARAM(float4, bump_map_xform);
PARAM_SAMPLER_2D(bump_detail_map);
PARAM(float4, bump_detail_map_xform);
PARAM_SAMPLER_2D(bump_detail_mask_map);
PARAM(float4, bump_detail_mask_map_xform);
PARAM_SAMPLER_2D(bump_detail_masked_map);
PARAM(float4, bump_detail_masked_map_xform);
PARAM(float, bump_detail_coefficient);
PARAM(float, bump_detail_masked_coefficient);

PARAM_SAMPLER_2D(bump_detail_map2);
PARAM(float4, bump_detail_map2_xform);
PARAM_SAMPLER_2D(bump_detail_map3);
PARAM(float4, bump_detail_map3_xform);

// wrinkle maps
PARAM_SAMPLER_2D(wrinkle_normal);
PARAM(float4, wrinkle_normal_xform);
PARAM_SAMPLER_2D(wrinkle_mask_a);
PARAM(float4, wrinkle_mask_a_xform);
PARAM_SAMPLER_2D(wrinkle_mask_b);
PARAM(float4, wrinkle_mask_b_xform);
PARAM(float4, wrinkle_weights_a);
PARAM(float4, wrinkle_weights_b);

#include "bump_mapping_util.fx"

#ifndef SAMPLE_BUMP_TEXTURE
#define SAMPLE_BUMP_TEXTURE sample_bumpmap
#endif

//#if defined(pc) && (DX_VERSION == 9)
//#define BUMP_CONVERT(x)  ((x) * (255.0f / 127.f) - (128.0f / 127.f))
//#else
//#define BUMP_CONVERT(x)  (x)
//#endif

float3 sample_bumpmap(in texture_sampler_2d bump_map, in float2 texcoord)
{
#ifdef pc
	float3 bump= sample2D(bump_map, texcoord).rgb;
   bump.xy = BUMP_CONVERT(bump.xy);
#else					// xenon compressed bump textures don't calculate z automatically
	float4 bump;
	asm {
		tfetch2D bump, texcoord, bump_map, FetchValidOnly= false
	};
#endif
	
	float2 bump2= bump.xy * bump.xy;
	bump.z= min(bump2.x + bump2.y, 1.0f);
	bump.z= sqrt(1 - bump.z);

	bump.xyz= normalize(bump.xyz);		// ###ctchou $PERF do we need to normalize?  why?
	
	return bump.xyz;
}


void calc_bumpmap_off_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
//	float3 bump= fast3(0.0f, 0.0f, 1.0f);		// in tangent space

	// rotate bump to world space (same space as lightprobe) and normalize
//	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)

	bump_normal= tangent_frame[2];
}


void calc_bumpmap_default_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,	
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump= sample_bumpmap(bump_map, transform_texcoord(texcoord, bump_map_xform));		// in tangent space

	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)
}


void calc_bumpmap_detail_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump= sample_bumpmap(bump_map, transform_texcoord(texcoord, bump_map_xform));					// in tangent space
	float3 detail= sample_bumpmap(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform));	// in tangent space
	
	bump.xy+= detail.xy * bump_detail_coefficient;
	bump= normalize(bump);
	
	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}


void calc_bumpmap_detail_unorm_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump = sample_bumpmap(bump_map, transform_texcoord(texcoord, bump_map_xform));					// in tangent space
	bump = bump * 2.0f - 1.0f;
	float3 detail = sample_bumpmap(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform));	// in tangent space

	bump.xy += detail.xy * bump_detail_coefficient;
	bump = normalize(bump);

	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal = normalize(mul(bump, tangent_frame));		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}


PARAM(bool, invert_mask);

void calc_bumpmap_detail_masked_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump = sample_bumpmap(bump_map, transform_texcoord(texcoord, bump_map_xform));               // in tangent space
	float3 detail = sample_bumpmap(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform)); // in tangent space
	float  mask = sample2D(bump_detail_mask_map, transform_texcoord(texcoord, bump_detail_mask_map_xform)).r;
#ifdef APPLY_FIXES
	mask = invert_mask ? 1.0f - mask : mask;
#endif

	bump.xy += detail.xy * mask * bump_detail_coefficient;
	bump = normalize(bump);

	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal = normalize(mul(bump, tangent_frame));		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}

//=========================================

void calc_bumpmap_detail_plus_detail_masked_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump = sample_bumpmap(bump_map, transform_texcoord(texcoord, bump_map_xform));               // in tangent space
	float3 detail = sample_bumpmap(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform)); // in tangent space
	float3 detail_masked = sample_bumpmap(bump_detail_masked_map, transform_texcoord(texcoord, bump_detail_masked_map_xform)); // in tangent space
	float  mask = sample2D(bump_detail_mask_map, transform_texcoord(texcoord, bump_detail_mask_map_xform)).r;

	bump.xy += detail.xy * bump_detail_coefficient;
	bump.xy += detail_masked.xy * mask * bump_detail_masked_coefficient;
	bump = normalize(bump);

	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal = normalize(mul(bump, tangent_frame));		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}


void add_wrinkle_onto_bump_unnormalized(
	in float2 texcoord,
	inout float3 bump_normal)
{
	float3 wrinkle_bump= SAMPLE_BUMP_TEXTURE(wrinkle_normal, transform_texcoord(texcoord, wrinkle_normal_xform));

	float4 mask_a= tex2D(wrinkle_mask_a, transform_texcoord(texcoord, wrinkle_mask_a_xform));
	float4 mask_b= tex2D(wrinkle_mask_b, transform_texcoord(texcoord, wrinkle_mask_b_xform));

	float wrinkle_weight= dot(mask_a, wrinkle_weights_a) + dot(mask_b, wrinkle_weights_b);
	wrinkle_weight= saturate(wrinkle_weight);

	wrinkle_bump= lerp(float3(0, 0, 1), wrinkle_bump, wrinkle_weight);

	bump_normal= float3(bump_normal.xy+wrinkle_bump.xy, bump_normal.z*wrinkle_bump.z);
	bump_normal= normalize(bump_normal);
}

void calc_bumpmap_default_wrinkle_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,	
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump= SAMPLE_BUMP_TEXTURE(bump_map, transform_texcoord(texcoord, bump_map_xform));		// in tangent space

	add_wrinkle_onto_bump_unnormalized(texcoord, bump);

	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)
}


void calc_bumpmap_detail_wrinkle_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float3 bump= SAMPLE_BUMP_TEXTURE(bump_map, transform_texcoord(texcoord, bump_map_xform));					// in tangent space
	float3 detail= SAMPLE_BUMP_TEXTURE(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform));	// in tangent space
	
	bump.xy+= detail.xy;
	bump= normalize(bump);

	add_wrinkle_onto_bump_unnormalized(texcoord, bump);
	
	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}


/*
void calc_bumpmap_from_height_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	// this doesn't work very well - too much aliasing and ugliness from using a height map instead of a normal map
	float height= sample2D(bump_map, transform_texcoord(texcoord, bump_map_xform)) * -0.05f;
	
	float3 dBPx= ddx(fragment_to_camera_world) + tangent_frame[2] * ddx(height);
	float3 dBPy= ddy(fragment_to_camera_world) + tangent_frame[2] * ddy(height);
	
	bump_normal= -normalize( cross(dBPx, dBPy) );
}
*/
