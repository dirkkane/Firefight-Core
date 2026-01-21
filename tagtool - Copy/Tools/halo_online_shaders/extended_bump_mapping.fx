
// warning: must include albedo.fx and bump_mapping.fx before this file

void calc_bumpmap_detail_blend_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float4	base=		tex2D(base_map,		transform_texcoord(texcoord, base_map_xform));
	base.w= saturate(base.w*blend_alpha);
	
	float3 bump= SAMPLE_BUMP_TEXTURE(bump_map, transform_texcoord(texcoord, bump_map_xform));					// in tangent space
	
	float3 detail1= SAMPLE_BUMP_TEXTURE(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform));	// in tangent space
	float3 detail2= SAMPLE_BUMP_TEXTURE(bump_detail_map2, transform_texcoord(texcoord, bump_detail_map2_xform));	// in tangent space
	float3 detail= lerp(detail1, detail2, base.w);
	
	bump.xy+= detail.xy;
	bump= normalize(bump);
	
	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}

void calc_bumpmap_three_detail_blend_ps(
	in float2 texcoord,
	in float3 fragment_to_camera_world,
	in float3x3 tangent_frame,
	out float3 bump_normal)
{
	float4 base=	tex2D(base_map,		transform_texcoord(texcoord, base_map_xform));
	base.w= saturate(base.w*blend_alpha);
	
	float3 bump= SAMPLE_BUMP_TEXTURE(bump_map, transform_texcoord(texcoord, bump_map_xform));					// in tangent space
	float3 detail1= SAMPLE_BUMP_TEXTURE(bump_detail_map, transform_texcoord(texcoord, bump_detail_map_xform));	// in tangent space
	float3 detail2= SAMPLE_BUMP_TEXTURE(bump_detail_map2, transform_texcoord(texcoord, bump_detail_map2_xform));	// in tangent space
	float3 detail3= SAMPLE_BUMP_TEXTURE(bump_detail_map3, transform_texcoord(texcoord, bump_detail_map3_xform));	// in tangent space

	float blend1= saturate(2.0f*base.w);
	float blend2= saturate(2.0f*base.w - 1.0f);

	float3 first_blend=  lerp(detail1, detail2, blend1);
	float3 detail= lerp(first_blend, detail3, blend2);
	
	bump.xy+= detail.xy;
	bump= normalize(bump);
	
	// rotate bump to world space (same space as lightprobe) and normalize
	bump_normal= normalize( mul(bump, tangent_frame) );		// V*M = M'*V = inverse(M)*V    if M is orthogonal (tangent_frame should be orthogonal)	
}
