#line 2 "source\rasterizer\hlsl\texture_xform.fx"
#ifndef __TEXTURE_XFORM_FX
#define __TEXTURE_XFORM_FX

#define BITMAP_ROTATION(rotation) ROTATION_TYPE_##rotation
#define ROTATION_TYPE_0 0
#define ROTATION_TYPE_1 1
#define ROTATION_TYPE_2 2


float2 transform_texcoord(in float2 texcoord, in float4 transform)
{
#if BITMAP_ROTATION(bitmap_rotation)==ROTATION_TYPE_1
	float2 output_texcoord;
	float sine= sin(transform.x);
	float cosine= cos(transform.x);
	
	texcoord-= transform.zw;

	output_texcoord.x= transform.y*(cosine*texcoord.x - sine*texcoord.y);
	output_texcoord.y= transform.y*(sine*texcoord.x + cosine*texcoord.y);
	
	output_texcoord+= transform.zw;

	return output_texcoord;
#else
	return texcoord * transform.xy + transform.zw;
#endif // BITMAP_ROTATION
}


#endif // __TEXTURE_XFORM_FX