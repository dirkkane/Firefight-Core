#ifndef __LIGHTMAP_SAMPLING_FX_H__
#define __LIGHTMAP_SAMPLING_FX_H__

#ifdef PC_CPU
#pragma once
#endif 

/*
LIGHTMAP_SAMPLING.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
2/3/2007 3:24:00 PM (haochen)
	shared code for sampling light probe texture
*/

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
	out float3 sh_coefficients[4],
	out float3 dominant_light_direction,
	out float3 dominant_light_intensity)
{

//#ifndef pc

#ifdef DEBUG_UNCOMPRESSED_LIGHTMAPS
	if ( p_lightmap_compress_constant_using_dxt )
#endif //DEBUG_UNCOMPRESSED_LIGHTMAPS
	{	

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

		float3 lightmap_texcoord_bottom= float3(lightmap_texcoord, 0.0f);

		TFETCH_3D(sh_dxt_vector_0, lightmap_texcoord_bottom, lightprobe_texture_array, 0.5, 8);
		TFETCH_3D(sh_dxt_vector_1, lightmap_texcoord_bottom, lightprobe_texture_array, 1.5, 8);
		TFETCH_3D(sh_dxt_vector_2, lightmap_texcoord_bottom, lightprobe_texture_array, 2.5, 8);
		TFETCH_3D(sh_dxt_vector_3, lightmap_texcoord_bottom, lightprobe_texture_array, 3.5, 8);
		TFETCH_3D(sh_dxt_vector_4, lightmap_texcoord_bottom, lightprobe_texture_array, 4.5, 8);
		TFETCH_3D(sh_dxt_vector_5, lightmap_texcoord_bottom, lightprobe_texture_array, 5.5, 8);
		TFETCH_3D(sh_dxt_vector_6, lightmap_texcoord_bottom, lightprobe_texture_array, 6.5, 8);
		TFETCH_3D(sh_dxt_vector_7, lightmap_texcoord_bottom, lightprobe_texture_array, 7.5, 8);
		TFETCH_3D(sh_dxt_vector_8, lightmap_texcoord_bottom, dominant_light_intensity_map, 0.5, 2);
		TFETCH_3D(sh_dxt_vector_9, lightmap_texcoord_bottom, dominant_light_intensity_map, 1.5, 2);

		sh_coefficients[0] = decode_bpp16_luvw(sh_dxt_vector_0, sh_dxt_vector_1, p_lightmap_compress_constant_0.x);	
		sh_coefficients[1] = decode_bpp16_luvw(sh_dxt_vector_2, sh_dxt_vector_3, p_lightmap_compress_constant_0.y);	
		sh_coefficients[2] = decode_bpp16_luvw(sh_dxt_vector_4, sh_dxt_vector_5, p_lightmap_compress_constant_0.z);	
		sh_coefficients[3] = decode_bpp16_luvw(sh_dxt_vector_6, sh_dxt_vector_7, p_lightmap_compress_constant_1.x);	
		dominant_light_intensity= decode_bpp16_luvw(sh_dxt_vector_8, sh_dxt_vector_9, p_lightmap_compress_constant_1.y);
		
		float3 dominant_light_dir_r= float3(-sh_coefficients[3].r, -sh_coefficients[1].r, sh_coefficients[2].r);
		float3 dominant_light_dir_g= float3(-sh_coefficients[3].g, -sh_coefficients[1].g, sh_coefficients[2].g);
		float3 dominant_light_dir_b= float3(-sh_coefficients[3].b, -sh_coefficients[1].b, sh_coefficients[2].b);
		dominant_light_direction= dominant_light_dir_r * 0.212656f + dominant_light_dir_g * 0.715158f + dominant_light_dir_b * 0.0721856f;
#ifdef APPLY_FIXES
		dominant_light_direction= safe_normalize(dominant_light_direction);
#else
        dominant_light_direction= normalize(dominant_light_direction);
#endif

		//subtract the dominant light from the sh linear coefficients
		//float4 dir_eval= float4(0.2820948f, -0.4886025f * dominant_light_direction.y, 0.4886025f * dominant_light_direction.z, -0.4886025 * dominant_light_direction.x);
		//sh_coefficients[0]-= dir_eval.x * dominant_light_intensity;
		//sh_coefficients[1]-= dir_eval.y * dominant_light_intensity;
		//sh_coefficients[2]-= dir_eval.z * dominant_light_intensity;
		//sh_coefficients[3]-= dir_eval.w * dominant_light_intensity;
		
	}
#ifdef DEBUG_UNCOMPRESSED_LIGHTMAPS
	else
	{
		float4 temp_0, temp_1, temp_2, temp_3;
		float4 intensity;
		float3 lightmap_texcoord_bottom= float3(lightmap_texcoord, 0.0f);

		TFETCH_3D(temp_0, lightmap_texcoord_bottom, lightprobe_texture_array, 0.5, 4);
		TFETCH_3D(temp_1, lightmap_texcoord_bottom, lightprobe_texture_array, 1.5, 4);
		TFETCH_3D(temp_2, lightmap_texcoord_bottom, lightprobe_texture_array, 2.5, 4);
		TFETCH_3D(temp_3, lightmap_texcoord_bottom, lightprobe_texture_array, 3.5, 4);
		TFETCH_3D(intensity, lightmap_texcoord_bottom, dominant_light_intensity_map, 0.5, 1);
		
		dominant_light_intensity= intensity.xyz;
		float3 dominant_light_dir_r= float3(-temp_3.r, -temp_1.r, temp_2.r);
		float3 dominant_light_dir_g= float3(-temp_3.g, -temp_1.g, temp_2.g);
		float3 dominant_light_dir_b= float3(-temp_3.b, -temp_1.b, temp_2.b);

		dominant_light_direction= dominant_light_dir_r * 0.212656f + dominant_light_dir_g * 0.715158f + dominant_light_dir_b * 0.0721856f;
		dominant_light_direction= safe_normalize(dominant_light_direction);

		sh_coefficients[0]= temp_0.xyz;
		sh_coefficients[1]= temp_1.xyz;
		sh_coefficients[2]= temp_2.xyz;
		sh_coefficients[3]= temp_3.xyz;
		
		//float4 dir_eval= float4(0.2820948f, -0.4886025f * dominant_light_direction.y, 0.4886025f * dominant_light_direction.z, -0.4886025 * dominant_light_direction.x);		
		//sh_coefficients[0]-= dir_eval.x * dominant_light_intensity;
		//sh_coefficients[1]-= dir_eval.y * dominant_light_intensity;
		//sh_coefficients[2]-= dir_eval.z * dominant_light_intensity;
		//sh_coefficients[3]-= dir_eval.w * dominant_light_intensity;

	}
#endif //DEBUG_UNCOMPRESSED_LIGHTMAPS
			
// #else //pc
// 
// 	sh_coefficients[0]= 1.0f;
// 	sh_coefficients[1]= 0.0f;
// 	sh_coefficients[2]= 0.0f;
// 	sh_coefficients[3]= 0.0f;
// 	dominant_light_direction= float3(0.0f, 0.0f, 1.0f);
// 	dominant_light_intensity= 0.5f;
// 	
// #endif //pc
	

}
		
#endif //__LIGHTMAP_SAMPLING_FX_H__
