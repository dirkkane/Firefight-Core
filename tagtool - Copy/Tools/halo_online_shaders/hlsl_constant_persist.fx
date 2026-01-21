#ifndef _HLSL_CONSTANT_PERSIST_FX_
#ifndef DEFINE_CPP_CONSTANTS
#define _HLSL_CONSTANT_PERSIST_FX_
#endif

//NOTE: if you modify any of this, than you need to modify hlsl_constant_persist.h 

#if defined(pc) || defined(PC)
#define k_maximum_simple_light_count			8
#else
#define k_maximum_simple_light_count			16
#endif

#if DX_VERSION == 9

// Shader constants which are off-limits (expected to persist throughout the frame)
#define k_register_viewproj_xform				c0
#define k_register_camera_forward				c4
#define k_register_camera_left					c5
#define k_register_camera_up					c6
#define k_register_camera_position				c7
#define k_register_screen_xform					c8
#define k_register_viewport_scale				c10
#define k_register_viewport_offset				c11
#define k_ravi_constants_start					c240

#define k_register_camera_position_ps			c16

// 5 registers per simple light: [c18,c58) used on pc and [c18,c98) used on xenon

#define k_register_simple_light_count			c17
#define k_register_simple_light_start			c18

#ifndef PC_CPU
   VERTEX_CONSTANT(float4x4, View_Projection, k_register_viewproj_xform);		// WARNING:  View_Projection[0] is _NOT_ the same as k_register_viewproj_xform, HLSL treats the matrix as transposed
#endif
VERTEX_CONSTANT(float3, Camera_Forward, k_register_camera_forward);			// the position and orientation of the camera in world space
VERTEX_CONSTANT(float3, Camera_Left, k_register_camera_left);
VERTEX_CONSTANT(float3, Camera_Up, k_register_camera_up);
VERTEX_CONSTANT(float3, Camera_Position, k_register_camera_position);
#ifndef PC_CPU
   VERTEX_CONSTANT(float2x4, Screen, k_register_screen_xform);
#endif
VERTEX_CONSTANT(float3, Viewport_Scale, k_register_viewport_scale);
VERTEX_CONSTANT(float3, Viewport_Offset, k_register_viewport_offset);

// hax
#define vs_total_time float(1.0f)


VERTEX_CONSTANT(float4, v_exposure, c232 );
VERTEX_CONSTANT(float4, v_alt_exposure, c239 );

VERTEX_CONSTANT(float4, v_atmosphere_constant_extra, c15);					
VERTEX_CONSTANT(float4, v_atmosphere_constant_0, c233);					
VERTEX_CONSTANT(float4, v_atmosphere_constant_1, c234);					
VERTEX_CONSTANT(float4, v_atmosphere_constant_2, c235);					
VERTEX_CONSTANT(float4, v_atmosphere_constant_3, c236);					
VERTEX_CONSTANT(float4, v_atmosphere_constant_4, c237);					
VERTEX_CONSTANT(float4, v_atmosphere_constant_5, c238);					

VERTEX_CONSTANT(float4, v_lighting_constant_0, c240);
#ifndef PC_CPU
   VERTEX_CONSTANT(float4x4, Shadow_Projection, c240);					// used for dynamic light, to hold the light projection matrix
#endif
VERTEX_CONSTANT(float4, v_lighting_constant_1, c241);
VERTEX_CONSTANT(float4, v_lighting_constant_2, c242);
VERTEX_CONSTANT(float4, v_lighting_constant_3, c243);
VERTEX_CONSTANT(float4, v_lighting_constant_4, c244);
VERTEX_CONSTANT(float4, v_lighting_constant_5, c245);
VERTEX_CONSTANT(float4, v_lighting_constant_6, c246);
VERTEX_CONSTANT(float4, v_lighting_constant_7, c247);
VERTEX_CONSTANT(float4, v_lighting_constant_8, c248);
VERTEX_CONSTANT(float4, v_lighting_constant_9, c249);

#ifdef pc
VERTEX_CONSTANT(bool, v_mesh_squished, b8);
VERTEX_CONSTANT(float4, v_squish_params, c250);
#endif


#ifndef PC_CPU
   PIXEL_CONSTANT(float4, g_exposure, c0 );							// exposure multiplier, HDR target multiplier, HDR alpha multiplier, LDR alpha multiplier		// ###ctchou $REVIEW could move HDR target multiplier to exponent bias and just set HDR alpha multiplier..
   PIXEL_CONSTANT(float4, p_lighting_constant_0, c1);					// NOTE: these are also used for shadow_apply entry point (to hold the shadow projection matrix), as well as dynamic lights (to hold additional shadow info)
   PIXEL_CONSTANT(float4, Shadow_Projection_z, c1);					//
   PIXEL_CONSTANT(float4, p_lighting_constant_1, c2);
   PIXEL_CONSTANT(float4, p_lighting_constant_2, c3);
   PIXEL_CONSTANT(float4, p_lighting_constant_3, c4);
   PIXEL_CONSTANT(float4, p_lighting_constant_4, c5);
   PIXEL_CONSTANT(float4, p_dynamic_light_gel_xform, c5);				// overlaps lighting constant - they're unused in the expensive dynamic light pass
   PIXEL_CONSTANT(float4, p_lighting_constant_5, c6);
   PIXEL_CONSTANT(float4, p_lighting_constant_6, c7);
   PIXEL_CONSTANT(float4, p_lighting_constant_7, c8);
   PIXEL_CONSTANT(float4, p_lighting_constant_8, c9);
   PIXEL_CONSTANT(float4, p_lighting_constant_9, c10);

	// hax
	#define ps_total_time float(1.0f)


   PIXEL_CONSTANT(float4, g_alt_exposure, c12);						// self-illum exposure, unused, unused, unused


   // ###xwan moved from oneshot
   PIXEL_CONSTANT(float2,  texture_size, c14);							// used for pixel-shader implemented bilinear, and albedo textures
   PIXEL_CONSTANT(float4,  dynamic_environment_blend, c15);


   PIXEL_CONSTANT(float4, p_lightmap_compress_constant_0, c210);
   PIXEL_CONSTANT(float4, p_lightmap_compress_constant_1, c211);
   PIXEL_CONSTANT(float4, p_lightmap_compress_constant_2, c212);
#endif

#ifndef PC_CPU
   #ifndef pc
   PIXEL_CONSTANT(float4, p_tiling_vpos_offset, c108);
   PIXEL_CONSTANT(float4, p_tiling_resolvetexture_xform, c109);
   PIXEL_CONSTANT(float4, p_tiling_reserved2,   c110);
   PIXEL_CONSTANT(float4, p_tiling_reserved3,   c111);
   #endif
#endif

#ifndef PC_CPU
PIXEL_CONSTANT(float4, p_render_debug_mode, c94);	
#endif

#ifdef pc
#if DX_VERSION == 11
	PIXEL_CONSTANT(float, p_shader_pc_specular_enabled, c95);				// first register after simple lights
	PIXEL_CONSTANT(float, p_shader_pc_albedo_lighting, c96);
#else
	#define p_shader_pc_specular_enabled 1.0f
	#define p_shader_pc_albedo_lighting 1.0f
#endif
#endif // pc

#ifndef PC_CPU
   #ifdef pc
      PIXEL_CONSTANT(float, simple_light_count, k_register_simple_light_count);
      PIXEL_CONSTANT(float4, simple_lights[k_maximum_simple_light_count][5], k_register_simple_light_start); 
      #define dynamic_lights_use_array_notation 1
   #else // xenon
      PIXEL_CONSTANT(int, simple_light_count_int, i0);
      PIXEL_CONSTANT(float, simple_light_count_float, k_register_simple_light_count);

      #ifdef xdk_2907
      // stupid unoptimized code can't handle loops apparently - requires floating point light count
      #define simple_light_count simple_light_count_float
      PIXEL_CONSTANT(float4, simple_lights[k_maximum_simple_light_count][5], k_register_simple_light_start); 
      #define dynamic_lights_use_array_notation 1
      #else
      #define simple_light_count simple_light_count_int
      PIXEL_CONSTANT(float4, simple_lights[k_maximum_simple_light_count * 5], k_register_simple_light_start); 
      #endif

   #endif // xenon


   PIXEL_CONSTANT(float3, Camera_Position_PS, k_register_camera_position_ps);

   bool always_true : register(b0);
   /*#ifdef pc
	   #define actually_calc_albedo true	// no bool constants in pixel shader
	   //	###xwan	constants for light map dxt5 compression, reservated comstants from 60 to 79
	   #define p_lightmap_compress_constant_using_dxt true	// lighting calcs albedo instead of sampling it 
   #else*/
	   bool actually_calc_albedo : register(b12);	// lighting calcs albedo instead of sampling it 
	   //	###xwan	constants for light map dxt5 compression, reservated comstants from 60 to 79
	   bool p_lightmap_compress_constant_using_dxt : register(b10);	// lighting calcs albedo instead of sampling it 
   //#endif 


   PIXEL_CONSTANT(bool, LDR_gamma2, b14);		// ###ctchou $TODO $PERF remove these when we settle on a render target format
   PIXEL_CONSTANT(bool, HDR_gamma2, b15);


   //vertex shader samplers
   VERTEX_SAMPLER_CONSTANT (sampler_atmosphere_neta_table, s0);
   VERTEX_SAMPLER_CONSTANT (sampler_weather_occlusion, s1);	// can go in oneshot if necessary


   //pixel shader common samplers --- do not allow any collisions by explicitly declaring samplers greater than 10 elsewhere!!!
   //STATIC LIGHTING
   sampler albedo_texture;
   sampler normal_texture;

   sampler lightprobe_texture_array;
   sampler dominant_light_intensity_map;


   //WATER, ACTIVE CAMO
   sampler scene_ldr_texture;

   //WATER, PARTICLES 
   sampler depth_buffer;
#endif

#elif DX_VERSION == 11

#ifndef DEFINE_CPP_CONSTANTS
#define always_true true
#endif

CBUFFER_BEGIN(ViewVS)
	CBUFFER_CONST(ViewVS, 		float4x4,	View_Projection,			k_viewproj_xform)
	CBUFFER_CONST(ViewVS,		float4x4,	View,						k_view_xform)
	CBUFFER_CONST(ViewVS,		float4x2,	Screen,						k_screen_xform)
	CBUFFER_CONST(ViewVS,		float4,		v_clip_plane,				k_clip_plane)
	CBUFFER_CONST(ViewVS,		float,		vs_total_time,				k_vs_total_time)
	CBUFFER_CONST(ViewVS,		float3,		vs_total_time_pad,			k_vs_total_time_pad)
	CBUFFER_CONST(ViewVS,		bool,		v_always_true,				k_vs_always_true)
CBUFFER_END	
	
SHADER_CONST_ALIAS(ViewVS,		float4,		View_Projection_X,			View_Projection._m00_m10_m20_m30,	k_viewproj_xform_x,		k_viewproj_xform, 	0)
SHADER_CONST_ALIAS(ViewVS,		float4,		View_Projection_Y,			View_Projection._m01_m11_m21_m31,	k_viewproj_xform_y,		k_viewproj_xform, 	16)
SHADER_CONST_ALIAS(ViewVS,		float4,		View_Projection_Z,			View_Projection._m02_m12_m22_m32,	k_viewproj_xform_z,		k_viewproj_xform, 	32)
SHADER_CONST_ALIAS(ViewVS,		float4,		View_Projection_W,			View_Projection._m03_m13_m23_m33,	k_viewproj_xform_w,		k_viewproj_xform, 	48)
			
SHADER_CONST_ALIAS(ViewVS,		float3,		Camera_Forward,				View._m00_m10_m20,					k_camera_forward,		k_view_xform,		0)
SHADER_CONST_ALIAS(ViewVS,		float3,		Camera_Left,				View._m01_m11_m21,					k_camera_left,			k_view_xform,		16)
SHADER_CONST_ALIAS(ViewVS,		float3,		Camera_Up,					View._m02_m12_m22,					k_camera_up,			k_view_xform,		32)
SHADER_CONST_ALIAS(ViewVS,		float3,		Camera_Position,			View._m03_m13_m23,					k_camera_position,		k_view_xform,		48)
			
SHADER_CONST_ALIAS(ViewVS,		float4,		Screen_X,					Screen._m00_m10_m20_m30,			k_screen_xform_x,		k_screen_xform,		0)
SHADER_CONST_ALIAS(ViewVS,		float4,		Screen_Y,					Screen._m01_m11_m21_m31,			k_screen_xform_y,		k_screen_xform,		16)
	
CBUFFER_BEGIN(ExposureVS)	
	CBUFFER_CONST(ExposureVS,	float4,		v_exposure,					k_vs_exposure)
	CBUFFER_CONST(ExposureVS,	float4,		v_alt_exposure,				k_vs_alt_exposure)
CBUFFER_END

CBUFFER_BEGIN(AtmosphereVS)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_0,		k_vs_atmosphere_constant_0)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_1,		k_vs_atmosphere_constant_1)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_2,		k_vs_atmosphere_constant_2)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_3,		k_vs_atmosphere_constant_3)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_4,		k_vs_atmosphere_constant_4)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_5,		k_vs_atmosphere_constant_5)
	CBUFFER_CONST(AtmosphereVS,	float4,		v_atmosphere_constant_extra,	k_vs_atmosphere_constant_extra)
CBUFFER_END

CBUFFER_BEGIN(LightingVS)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_0,			k_vs_lighting_constant_0)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_1,			k_vs_lighting_constant_1)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_2,			k_vs_lighting_constant_2)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_3,			k_vs_lighting_constant_3)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_4,			k_vs_lighting_constant_4)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_5,			k_vs_lighting_constant_5)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_6,			k_vs_lighting_constant_6)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_7,			k_vs_lighting_constant_7)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_8,			k_vs_lighting_constant_8)
	CBUFFER_CONST(LightingVS,	float4,		v_lighting_constant_9,			k_vs_lighting_constant_9)
CBUFFER_END

CBUFFER_BEGIN(DynamicLightClipVS)
	CBUFFER_CONST_ARRAY(DynamicLightClipVS,		float4,		v_dynamic_light_clip_plane, [6],	k_vs_dynamic_light_clip_planes)
CBUFFER_END

CBUFFER_BEGIN(ShadowProjVS)
	CBUFFER_CONST(ShadowProjVS,	float4x4,	Shadow_Projection,				k_vs_shadow_projection)
CBUFFER_END

CBUFFER_BEGIN(ViewPS)
   CBUFFER_CONST(ViewPS,		float3, 	Camera_Position_PS, 			k_register_camera_position_ps)
CBUFFER_END

CBUFFER_BEGIN(ExposurePS)
	CBUFFER_CONST(ExposurePS,	float4,		g_exposure,						k_ps_exposure)
	CBUFFER_CONST(ExposurePS,	float4,		g_alt_exposure,					k_ps_alt_exposure)
CBUFFER_END

CBUFFER_BEGIN(LightingPS)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_0,			k_ps_lighting_constant_0)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_1,			k_ps_lighting_constant_1)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_2,			k_ps_lighting_constant_2)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_3,			k_ps_lighting_constant_3)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_4,			k_ps_lighting_constant_4)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_5,			k_ps_lighting_constant_5)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_6,			k_ps_lighting_constant_6)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_7,			k_ps_lighting_constant_7)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_8,			k_ps_lighting_constant_8)
	CBUFFER_CONST(LightingPS,	float4,		p_lighting_constant_9,			k_ps_lighting_constant_9)
CBUFFER_END

SHADER_CONST_ALIAS(LightingPS,	float4,		p_dynamic_light_gel_xform,		p_lighting_constant_4,			k_ps_dynamic_light_gel_xform,	k_ps_lighting_constant_0,	0)

CBUFFER_BEGIN(MiscPS)
	CBUFFER_CONST(MiscPS,		float2,		texture_size,							k_ps_texture_size)
	CBUFFER_CONST(MiscPS,		float2,		texture_size_pad,						k_ps_texture_size_pad)
	CBUFFER_CONST(MiscPS,		float4,		dynamic_environment_blend,				k_ps_dynamic_environment_blend)
	CBUFFER_CONST(MiscPS,		float4,		p_render_debug_mode,					k_ps_render_debug_mode)
	CBUFFER_CONST(MiscPS,		float,		p_shader_pc_specular_enabled,			k_shader_pc_specular_enabled)
	CBUFFER_CONST(MiscPS,		float3,		p_shader_pc_specular_enabled_pad,		k_shader_pc_specular_enabled_pad)
	CBUFFER_CONST(MiscPS,		float,		p_shader_pc_albedo_lighting,			k_shader_pc_albedo_lighting)
	CBUFFER_CONST(MiscPS,		float3,		p_shader_pc_albedo_lighting_pad,		k_shader_pc_albedo_lighting_pad)
	CBUFFER_CONST(MiscPS,		bool,		LDR_gamma2,								k_ps_ldr_gamma2)
	CBUFFER_CONST(MiscPS,		bool,		HDR_gamma2,								k_ps_hdr_gamma2)
	CBUFFER_CONST(MiscPS,		bool,	 	actually_calc_albedo,					k_ps_actually_calc_albedo)
	CBUFFER_CONST(MiscPS,		bool,		p_lightmap_compress_constant_using_dxt,	k_ps_lightmap_compress_constant_using_dxt)
	CBUFFER_CONST(MiscPS,		float,		ps_total_time,							k_ps_total_time)
	CBUFFER_CONST(MiscPS,		float3,		ps_total_time_pad,						k_ps_total_time_pad)
CBUFFER_END

CBUFFER_BEGIN(LightmapCompressPS)
	CBUFFER_CONST(LightmapCompressPS,	float4,		p_lightmap_compress_constant_0,		k_ps_lightmap_compress_constant_0)
	CBUFFER_CONST(LightmapCompressPS,	float4,		p_lightmap_compress_constant_1,		k_ps_lightmap_compress_constant_1)
	CBUFFER_CONST(LightmapCompressPS,	float4,		p_lightmap_compress_constant_2,		k_ps_lightmap_compress_constant_2)
CBUFFER_END

CBUFFER_BEGIN(SimpleLightsPS)
	CBUFFER_CONST(SimpleLightsPS,		float,		simple_light_count,									k_register_simple_light_count)
	CBUFFER_CONST(SimpleLightsPS,		float3,		simple_light_count_pad,								k_register_simple_light_count_pad)
	CBUFFER_CONST_ARRAY(SimpleLightsPS,	float4,		simple_lights, [k_maximum_simple_light_count][5],	k_register_simple_light_start)
CBUFFER_END

#define dynamic_lights_use_array_notation 1

VERTEX_TEXTURE_AND_SAMPLER(_2D,			sampler_atmosphere_neta_table,	k_vs_sampler_atmosphere_neta_table,		0)
#ifndef COMPUTE_SHADER
VERTEX_TEXTURE_AND_SAMPLER(_2D,			sampler_weather_occlusion,		k_vs_sampler_weather_occlusion,			1)
#endif

PIXEL_TEXTURE_AND_SAMPLER(_2D_ARRAY,	lightprobe_texture_array,		k_sampler_lightprobe_texture_array,		13)
PIXEL_TEXTURE_AND_SAMPLER(_2D_ARRAY,	dominant_light_intensity_map,	k_sampler_dominant_light_intensity_map,	14)

PIXEL_TEXTURE_AND_SAMPLER(_2D,			scene_ldr_texture,				k_sampler_scene_ldr_texture,			15)

PIXEL_TEXTURE(_2D,		albedo_texture,					k_sampler_albedo_texture,				16)
PIXEL_TEXTURE(_2D,		normal_texture,					k_sampler_normal_texture,				17)
PIXEL_TEXTURE(_2D,		depth_buffer,					k_sampler_depth_buffer,					18)

#endif

#define V_ILLUM_SCALE (v_alt_exposure.r)
#define V_ILLUM_EXPOSURE (v_alt_exposure.g)
#define ILLUM_SCALE (g_alt_exposure.r)
#define ILLUM_EXPOSURE (g_alt_exposure.g)

#endif //ifndef _HLSL_CONSTANT_PERSIST_FX_

