#ifndef __LIGHTMAP_SAMPLING_FX_OLD_H__
#define __LIGHTMAP_SAMPLING_FX_OLD_H__
#pragma once
/*
LIGHTMAP_SAMPLING.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
2/3/2007 3:24:00 PM (haochen)
	shared code for sampling light probe texture
*/

#include "hlsl_constant_mapping.fx"

float3 decode_bpp16_luvw(
	in float4 val0,
	in float4 val1,
	in float l_range)
{
	float L = val0.a * val1.a * l_range;
	float3 uvw = val0.xyz + val1.xyz;
	return (uvw * 2.0f - 2.0f) * L;	
}

void sample_lightprobe_texture(
	in float2 lightmap_texcoord,
	out float3 sh_coefficients[9],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{

#ifdef DEBUG_UNCOMPRESSED_LIGHTMAPS
	if ( p_lightmap_compress_constant_using_dxt )
#endif //DEBUG_UNCOMPRESSED_LIGHTMAPS
	{	
#ifndef pc
		float4 sh_dxt_vector_0;
		float4 sh_dxt_vector_1;
		float4 sh_dxt_vector_2;
		float4 sh_dxt_vector_3;
		float4 sh_dxt_vector_4;
		float4 sh_dxt_vector_5;
		float4 sh_dxt_vector_6;
		float4 sh_dxt_vector_7;
		float4 sh_dxt_vector_8;
		float4 sh_dxt_vector_9;
		float4 sh_dxt_vector_10;
		float4 sh_dxt_vector_11;
		float4 sh_dxt_vector_12;
		float4 sh_dxt_vector_13;
		float4 sh_dxt_vector_14;
		float4 sh_dxt_vector_15;
		float4 sh_dxt_vector_16;
		float4 sh_dxt_vector_17;

		float3 lightmap_texcoord_bottom= float3(lightmap_texcoord, 0.0f);
		float3 lightmap_texcoord_up= float3(lightmap_texcoord, 11.5f / 18.0f);

		asm{ tfetch3D sh_dxt_vector_0, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 0.5 };
		asm{ tfetch3D sh_dxt_vector_1, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 1.5 };

		asm{ tfetch3D sh_dxt_vector_2, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 2.5 };
		asm{ tfetch3D sh_dxt_vector_3, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 3.5 };

		asm{ tfetch3D sh_dxt_vector_4, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 4.5 };
		asm{ tfetch3D sh_dxt_vector_5, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 5.5 };

		asm{ tfetch3D sh_dxt_vector_6, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 6.5 };
		asm{ tfetch3D sh_dxt_vector_7, lightmap_texcoord_bottom, lightprobe_texture_array, OffsetZ= 7.5 };

		asm{ tfetch3D sh_dxt_vector_8, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ=-3.0 };
		asm{ tfetch3D sh_dxt_vector_9, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ=-2.0 };

		asm{ tfetch3D sh_dxt_vector_10, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ=-1.0 };
		asm{ tfetch3D sh_dxt_vector_11, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 0.0 };

		asm{ tfetch3D sh_dxt_vector_12, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 1.0 };
		asm{ tfetch3D sh_dxt_vector_13, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 2.0 };

		asm{ tfetch3D sh_dxt_vector_14, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 3.0 };
		asm{ tfetch3D sh_dxt_vector_15, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 4.0 };

		asm{ tfetch3D sh_dxt_vector_16, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 5.0 };
		asm{ tfetch3D sh_dxt_vector_17, lightmap_texcoord_up, lightprobe_texture_array, OffsetZ= 6.0 };	

		sh_coefficients[0] = decode_bpp16_luvw(sh_dxt_vector_0, sh_dxt_vector_1, p_lightmap_compress_constant_0.x);	
		sh_coefficients[1] = decode_bpp16_luvw(sh_dxt_vector_2, sh_dxt_vector_3, p_lightmap_compress_constant_0.y);	
		sh_coefficients[2] = decode_bpp16_luvw(sh_dxt_vector_4, sh_dxt_vector_5, p_lightmap_compress_constant_0.z);	
		sh_coefficients[3] = decode_bpp16_luvw(sh_dxt_vector_6, sh_dxt_vector_7, p_lightmap_compress_constant_1.x);	
		sh_coefficients[4] = decode_bpp16_luvw(sh_dxt_vector_8, sh_dxt_vector_9, p_lightmap_compress_constant_1.y);	
		sh_coefficients[5] = decode_bpp16_luvw(sh_dxt_vector_10, sh_dxt_vector_11, p_lightmap_compress_constant_1.z);	
		sh_coefficients[6] = decode_bpp16_luvw(sh_dxt_vector_12, sh_dxt_vector_13, p_lightmap_compress_constant_2.x);	
		sh_coefficients[7] = decode_bpp16_luvw(sh_dxt_vector_14, sh_dxt_vector_15, p_lightmap_compress_constant_2.y);	
		sh_coefficients[8] = decode_bpp16_luvw(sh_dxt_vector_16, sh_dxt_vector_17, p_lightmap_compress_constant_2.z);
		
		float3 dominant_light_dir_r= float3(-sh_coefficients[3].r, -sh_coefficients[1].r, sh_coefficients[2].r);
		float3 dominant_light_dir_g= float3(-sh_coefficients[3].g, -sh_coefficients[1].g, sh_coefficients[2].g);
		float3 dominant_light_dir_b= float3(-sh_coefficients[3].b, -sh_coefficients[1].b, sh_coefficients[2].b);
		dominant_light_direction= dominant_light_dir_r * 0.212656f + dominant_light_dir_g * 0.715158f + dominant_light_dir_b * 0.0721856f;
		dominant_light_direction= normalize(dominant_light_direction);
		
		float4 dir_eval= float4(0.2820948f, -0.4886025f * dominant_light_direction.y, 0.4886025f * dominant_light_direction.z, -0.4886025 * dominant_light_direction.x);		
		dominant_light_intensity.r= dot(dir_eval, float4(sh_coefficients[0].r, sh_coefficients[1].r, sh_coefficients[2].r, sh_coefficients[3].r));
		dominant_light_intensity.g= dot(dir_eval, float4(sh_coefficients[0].g, sh_coefficients[1].g, sh_coefficients[2].g, sh_coefficients[3].g));
		dominant_light_intensity.b= dot(dir_eval, float4(sh_coefficients[0].b, sh_coefficients[1].b, sh_coefficients[2].b, sh_coefficients[3].b));
		dominant_light_intensity*= 0.7161972f;
			
#else //pc
		sh_coefficients[0]= float4(1.0f, 1.0f, 1.0f, 0.0f);
		sh_coefficients[1]= 0.0f;
		sh_coefficients[2]= 0.0f;
		sh_coefficients[3]= 0.0f;
		sh_coefficients[4]= 0.0f;
		sh_coefficients[5]= 0.0f;
		sh_coefficients[6]= 0.0f;
		sh_coefficients[7]= 0.0f;
		sh_coefficients[8]= 0.0f;
		dominant_light_direction= float3(0.0f, 0.0f, 1.0f);
		dominant_light_intensity= 0.0f;
#endif //pc

	}
#ifdef DEBUG_UNCOMPRESSED_LIGHTMAPS
	else
	{
	
#ifndef pc

		float4 sh_coefficients0;
		float4 sh_coefficients1;
		float4 sh_coefficients2;
		float4 sh_coefficients3;
		float4 sh_coefficients4;
		float4 sh_coefficients5;
		float4 sh_coefficients6;
		float4 sh_coefficients7;
		float4 sh_coefficients8;
		float3 lightmap_texcoord_hack= float3(lightmap_texcoord, 0.0f);
		asm{ tfetch3D sh_coefficients0, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 0.5 }; sh_coefficients[0] = sh_coefficients0.xyz;
		asm{ tfetch3D sh_coefficients1, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 1.5 }; sh_coefficients[1] = sh_coefficients1.xyz;
		asm{ tfetch3D sh_coefficients2, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 2.5 }; sh_coefficients[2] = sh_coefficients2.xyz;
		asm{ tfetch3D sh_coefficients3, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 3.5 }; sh_coefficients[3] = sh_coefficients3.xyz;
		asm{ tfetch3D sh_coefficients4, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 4.5 }; sh_coefficients[4] = sh_coefficients4.xyz;
		asm{ tfetch3D sh_coefficients5, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 5.5 }; sh_coefficients[5] = sh_coefficients5.xyz;
		asm{ tfetch3D sh_coefficients6, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 6.5 }; sh_coefficients[6] = sh_coefficients6.xyz;
		asm{ tfetch3D sh_coefficients7, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ= 7.5 }; sh_coefficients[7] = sh_coefficients7.xyz;
		asm{ tfetch3D sh_coefficients8, lightmap_texcoord_hack, lightprobe_texture_array, OffsetZ=-0.5 }; sh_coefficients[8] = sh_coefficients8.xyz;
		
		sh_coefficients[0]= sh_coefficients0.xyz;
		sh_coefficients[1]= sh_coefficients1.xyz;
		sh_coefficients[2]= sh_coefficients2.xyz;
		sh_coefficients[3]= sh_coefficients3.xyz;
		sh_coefficients[4]= sh_coefficients4.xyz;
		sh_coefficients[5]= sh_coefficients5.xyz;
		sh_coefficients[6]= sh_coefficients6.xyz;
		sh_coefficients[7]= sh_coefficients7.xyz;
		sh_coefficients[8]= sh_coefficients8.xyz;
		
		float3 dominant_light_dir_r= float3(-sh_coefficients[3].r, -sh_coefficients[1].r, sh_coefficients[2].r);
		float3 dominant_light_dir_g= float3(-sh_coefficients[3].g, -sh_coefficients[1].g, sh_coefficients[2].g);
		float3 dominant_light_dir_b= float3(-sh_coefficients[3].b, -sh_coefficients[1].b, sh_coefficients[2].b);
		dominant_light_direction= dominant_light_dir_r * 0.212656f + dominant_light_dir_g * 0.715158f + dominant_light_dir_b * 0.0721856f;
		dominant_light_direction= normalize(dominant_light_direction);
		
		float4 dir_eval= float4(0.2820948f, -0.4886025f * dominant_light_direction.y, 0.4886025f * dominant_light_direction.z, -0.4886025 * dominant_light_direction.x);		
		dominant_light_intensity.r= dot(dir_eval, float4(sh_coefficients[0].r, sh_coefficients[1].r, sh_coefficients[2].r, sh_coefficients[3].r));
		dominant_light_intensity.g= dot(dir_eval, float4(sh_coefficients[0].g, sh_coefficients[1].g, sh_coefficients[2].g, sh_coefficients[3].g));
		dominant_light_intensity.b= dot(dir_eval, float4(sh_coefficients[0].b, sh_coefficients[1].b, sh_coefficients[2].b, sh_coefficients[3].b));
		dominant_light_intensity*= 0.7161972f;
		
#else //pc
		sh_coefficients[0]= float4(1.0f, 1.0f, 1.0f, 0.0f);
		sh_coefficients[1]= 0.0f;
		sh_coefficients[2]= 0.0f;
		sh_coefficients[3]= 0.0f;
		sh_coefficients[4]= 0.0f;
		sh_coefficients[5]= 0.0f;
		sh_coefficients[6]= 0.0f;
		sh_coefficients[7]= 0.0f;
		sh_coefficients[8]= 0.0f;
		dominant_light_direction= float3(0.0f, 0.0f, 1.0f);
		dominant_light_intensity= 0.0f;
#endif //pc
		
	}
#endif //DEBUG_UNCOMPRESSED_LIGHTMAPS

}
		
#endif //__LIGHTMAP_SAMPLING_FX_H__
