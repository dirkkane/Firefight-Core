//#line 2 "source\rasterizer\hlsl\shadow_apply.hlsl"
#ifndef _SHADOW_MASK_FX_
#define _SHADOW_MASK_FX_


void get_shadow_mask(out float4 shadow_mask, in float2 fragment_position)
{
#if defined(pc) || !defined(SCOPE_LIGHTING_OPAQUE)  || defined(SINGLE_PASS_LIGHTING)
    shadow_mask= float4(1, .5 , .5,1);
#else
	float2 screen_texcoord= fragment_position.xy;
	asm {
		tfetch2D shadow_mask, screen_texcoord, shadow_mask_texture, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true
	};
#endif // xenon
}


void apply_shadow_mask_to_vmf_lighting_coefficients(in float4 shadow_mask, inout float4 vmf_lighting_coefficients[4])
{
	// shadow_mask.a	== analytical light intensity mask
	vmf_lighting_coefficients[0].w		*= shadow_mask.a;
	
	// shadow_mask.r	== ambient / vmf light intensity mask, removing bandwidth attenuation..
	vmf_lighting_coefficients[1].rgb	*= shadow_mask.r;		// saturate(shadow_mask.r + shadow_intenstiy_preserve_for_vmf * (1-vmf_lighting_coefficients[1].a));
	
	// turning off ambient multiplier for now...  reinstate if we need it
	// vmf_lighting_coefficients[3].rgb	*= shadow_mask.r;
}


void apply_shadow_mask_to_vmf_lighting_coefficients_direct_only(in float4 shadow_mask, inout float4 vmf_lighting_coefficients[4])
{
	// shadow_mask.a	== analytical light intensity mask
	vmf_lighting_coefficients[0].w		*= shadow_mask.a;
}


#endif // _SHADOW_MASK_FX_