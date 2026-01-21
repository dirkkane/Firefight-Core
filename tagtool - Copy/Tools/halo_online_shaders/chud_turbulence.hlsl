// ==== SHADER DOCUMENTATION
// shader: chud_turbulence
#define IGNORE_SKINNING_NODES

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"

#define LDR_ONLY
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

#include "chud_util.fx"

//@generate chud_simple
//@entry default
//@entry albedo
//@entry dynamic_light

// rename entry point of water passes 
#define draw_turbulence_vs			default_vs
#define draw_turbulence_ps			default_ps
#define apply_to_distortion_vs		albedo_vs
#define apply_to_distortion_ps		albedo_ps
#define apply_to_blur_vs			dynamic_light_vs
#define apply_to_blur_ps			dynamic_light_ps

// The following defines the protocol for passing interpolated data between vertex/pixel shaders
struct s_chud_interpolators
{
	float4 position			:SV_Position;
	float2 texcoord			:TEXCOORD0;
};

// sampler of turbulence
LOCAL_SAMPLER_2D(chud_turbulence_sampler, 3);
static const float max_chud_distortion= 0.04f;


s_chud_interpolators draw_turbulence_vs(vertex_type IN)
{
    s_chud_interpolators OUT;
    
    float3 virtual_position= chud_local_to_virtual(IN.position.xy);    
    OUT.position= chud_virtual_to_screen(virtual_position);
	OUT.texcoord= IN.texcoord.xy*chud_texture_transform.xy + chud_texture_transform.zw;	
    return OUT;
}

float2 build_subsample_texcoord(float2 texcoord, float4 gradients, float dh, float dv)
{
	float2 result= texcoord;
	result+= gradients.xz*dh;
	result+= gradients.yw*dv;
	
	return result;
}

float4 texture_lookup(float2 texcoord)
{
#ifndef pc
	float4 bitmap_result;
	asm{
	tfetch2D bitmap_result, texcoord, basemap_sampler, MinFilter=linear, MagFilter=linear
	};
	return bitmap_result;
#else
	float4 bitmap_result= sample2D(basemap_sampler, texcoord);
	return bitmap_result;
#endif
}

// pixel fragment entry points
accum_pixel draw_turbulence_ps(s_chud_interpolators IN) : SV_Target
{	
#ifndef pc
	float4 gradients;
	float2 texcoord= IN.texcoord;	
	asm {
		getGradients gradients, texcoord, basemap_sampler 
	};
	
	float4 result= 0.0;
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients, -2.0/9.0,  2.0/9.0));
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients, -2.0/9.0, -2.0/9.0));
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients,  2.0/9.0, -2.0/9.0));
	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients,  2.0/9.0,  2.0/9.0));
	result /= 4.0;

#else // pc
	float4 result= texture_lookup(IN.texcoord);	
#endif // pc

	// alpha testing
	clip(result.a-0.5f);

	// bias distortion
	result.xy= result.xy - 0.5f; 
	result.x= -result.x; // reverse x, hack
	result.z= 0.0f;
	result.w= 0.0f;

	result.xy= result.xy*chud_widget_mirror_ps.xy; 	
    result.x= dot(result, chud_widget_transform1_ps.xyz);
    result.y= dot(result, chud_widget_transform2_ps.xyz);

	//return result;
	return convert_to_render_target(result, false, false);
}


s_chud_interpolators apply_to_distortion_vs(
	float4 position : POSITION,
	float4 texcoord : TEXCOORD0)
{
    s_chud_interpolators OUT;    
    OUT.position= position;    
	OUT.texcoord= texcoord.xy;
    return OUT;
}

float4 apply_to_distortion_ps(s_chud_interpolators IN) : SV_Target
{
	float4 result= sample2D(chud_turbulence_sampler, IN.texcoord);
#ifdef pc
#if DX_VERSION == 9
	const float offset = (float)0x04 / 0xff;
#elif DX_VERSION == 11
	const float offset = 0.5f;
#endif
	result.xy= max_chud_distortion * 16.0f * 2.0f * (result.xy - offset);
	result.xy = result.xy * 1024.0f / 32767.0f; // on PC use [0, 1] range instead [6/12/2012 paul.smirnov]
#else
	result.xy= max_chud_distortion * 16.0f * 2.0f * (result.xy - 0.5f);
#endif
	return result;
}

s_chud_interpolators apply_to_blur_vs(
	float4 position : SV_Position,
	float4 texcoord : TEXCOORD0)
{
    s_chud_interpolators OUT;    
    OUT.position= position;    
	OUT.texcoord= texcoord.xy;
    return OUT;
}

float4 apply_to_blur_ps(s_chud_interpolators IN) : SV_Target
{
	float4 result= sample2D(chud_turbulence_sampler, IN.texcoord);
	result= result.z;
	return result;
}

// end of rename entry points
#undef draw_turbulence_vs
#undef draw_turbulence_ps
#undef apply_to_distortion_vs
#undef apply_to_distortion_ps
#undef apply_to_blur_vs
#undef apply_to_blur_ps


//// pixel fragment entry points
//accum_pixel default_ps(s_chud_interpolators IN) : COLOR
//{
//	float3 tex_color= 0.0f;
//#ifndef pc
//	//float subsample_scale= 1.0/9.0;
//
//	float4 gradients;
//	float2 texcoord= IN.texcoord;
//	
//	asm {
//		getGradients gradients, texcoord, basemap_sampler 
//	};
//	
//	float4 result= 0.0;
//	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients, -2.0/9.0,  2.0/9.0));
//	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients, -2.0/9.0, -2.0/9.0));
//	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients,  2.0/9.0, -2.0/9.0));
//	result+= texture_lookup(build_subsample_texcoord(texcoord, gradients,  2.0/9.0,  2.0/9.0));
//	result /= 4.0;
//	tex_color= result.xyz;
//
//	result= build_subpixel_result_shared(result);	
//
//#else // pc
//	float4 result= build_subpixel_result(IN.texcoord);
//	tex_color= result.xyz;
//#endif // pc
//
//	IN.position_ss/= IN.position_ss.w;
//	float2 texcoord_ss= IN.position_ss.xy;
//	texcoord_ss= texcoord_ss / 2 + 0.5;
//	texcoord_ss.y= 1 - texcoord_ss.y;
//	texcoord_ss+= (tex_color.xy - 0.5f)/30.0f;
//	float3 buffer_color= 0.0f; 
//	{
//	#ifndef pc		
//		const int downsample_level_num= 3;
//		float4 color[downsample_level_num];
//		color[0]= tex2D(chud_frame_buffer_0_sampler, texcoord_ss);
//		color[1]= tex2D(chud_frame_buffer_1_sampler, texcoord_ss);
//		color[2]= tex2D(chud_frame_buffer_2_sampler, texcoord_ss);
//
//		color[0].rgb= color[0].rgb * color[1].a + color[1].rgb;
//
//		// recover color
//		for (int index=1; index<downsample_level_num; index++)
//		{
//			color[index].rgb*= chud_bloom_scale_c51.x;			
//		}
//
//		// get alpha
//		float alpha = saturate(tex_color.z);
//
//		float weight[3];		
//		weight[0] = (1 - alpha);
//		weight[0]*= weight[0];
//		weight[1] = alpha * alpha;
//		weight[2]= 1.0f - weight[0] - weight[1];
//		for (int index=0; index<3; index++)
//		{
//			buffer_color+= weight[index] * color[index].xyz;
//		}		
//	#else //pc
//		buffer_color= tex2D(chud_frame_buffer_0_sampler, texcoord_ss);
//	#endif //pc
//	}
//
//	//result.xyz= lerp(buffer_color, result.xyz, result.w);
//	result.rgb= buffer_color;
//	result.w= 1.0f;
//
//	
//	//apply hue and saturation
//	float4x4 hue_saturation_matrix= {p_postprocess_hue_saturation_matrix_v0, p_postprocess_hue_saturation_matrix_v1, p_postprocess_hue_saturation_matrix_v2, p_postprocess_hue_saturation_matrix_v3};
//	result.rgb= mul(result.rgb, hue_saturation_matrix);
//
//	//return result;
//	return chud_compute_result_pixel(result);
//}
