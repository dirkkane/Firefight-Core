#line 2 "source\rasterizer\hlsl\decorators.hlsl"

#define IGNORE_SKINNING_NODES

#include "global.fx"
#include "wind.fx"

#include "hlsl_constant_mapping.fx"
//#include "deform.fx"
#include "utilities.fx"

//#define LDR_ONLY
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"
#include "albedo_pass.fx"

#include "atmosphere.fx"
#include "quaternions.fx"
#include "decorators_registers.fx"

#ifdef VERTEX_SHADER
#define SIMPLE_LIGHT_DATA v_simple_lights
#define SIMPLE_LIGHT_COUNT v_simple_light_count.x
#undef dynamic_lights_use_array_notation			// decorators dont use array notation, they use loop-friendly notation
#include "simple_lights.fx"
#endif // VERTEX_SHADER

#include "atmosphere.fx"
#include "decorators.h"

// decorator shader is defined as 'world' vertex type, even though it really doesn't have a vertex type - it does its own custom vertex fetches
//@generate decorator

/*
	POSITION	0:		vertex position
	TEXCOORD	0:		vertex texcoord
	POSITION	1:		instance position
	NORMAL		1:		instance quaternion
	COLOR		1:		instance color
	POSITION	2:		vertex index
*/

#define vertex_compression_scale Position_Compression_Scale
#define vertex_compression_offset Position_Compression_Offset
#define texture_compression UV_Compression_Scale_Offset


LOCAL_SAMPLER_2D(diffuse_texture, 0);			// pixel shader
//LOCAL_SAMPLER_2D(geo_normal_texture, 1);			// pixel shader


#ifdef DECORATOR_EDIT


#define pc_ambient_light p_lighting_constant_0
#define selection_point p_lighting_constant_1
#define selection_curve p_lighting_constant_2
#define selection_color p_lighting_constant_3


struct interpolators
{
	float4	position			:	SV_Position;
	float2	texcoord			:	TEXCOORD0;
	float3	world_position		:	TEXCOORD1;
};

interpolators default_vs(
	float4 vertex_position : POSITION,
	float2 vertex_texcoord : TEXCOORD0)
{
	interpolators OUT;

	// decompress position
	vertex_position.xyz= vertex_position.xyz * vertex_compression_scale.xyz + vertex_compression_offset.xyz;

	OUT.world_position= quaternion_transform_point(instance_quaternion, vertex_position.xyz) * instance_position_and_scale.w + instance_position_and_scale.xyz;
	OUT.position= mul(float4(OUT.world_position.xyz, 1.0f), View_Projection);
	OUT.texcoord= vertex_texcoord.xy * texture_compression.xy + texture_compression.zw;
	return OUT;
}

accum_pixel default_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float2 texcoord : TEXCOORD0,
	in float3 world_position : TEXCOORD1)
{
//#define pc_ambient_light p_lighting_constant_0
//#define selection_point p_lighting_constant_1
//#define selection_curve p_lighting_constant_2
//#define selection_color p_lighting_constant_3

	float4 diffuse_albedo= sample2D(diffuse_texture, texcoord);
	clip(diffuse_albedo.a - k_decorator_alpha_test_threshold);				// alpha test
	
	float4 color= diffuse_albedo * pc_ambient_light * g_exposure.rrrr;

	// blend in selection cursor	
	float dist= distance(world_position, selection_point.xyz);
	float alpha= step(dist, selection_point.w);
	alpha *= selection_color.w;
	color.rgb= lerp(color.rgb, selection_color.rgb, alpha);
	
	return convert_to_render_target(color, true, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
	


#else	// DECORATOR_EDIT


#ifdef VERTEX_SHADER

void default_vs(
#ifndef pc
	in int index						:	SV_VertexID,
#else
	float4 vertex_position : POSITION,
	float2 vertex_texcoord : TEXCOORD0,
	float3 vertex_normal   : NORMAL,

#if DX_VERSION == 11
	uint4 instance_position_int : TEXCOORD1,
#else	
	float4 instance_position   : TEXCOORD1,
#endif
	float4 instance_quaternion : TEXCOORD2,
	float4 instance_color      : TEXCOORD3,
#endif	
	out float4	out_position			:	SV_Position,
	out float4	out_texcoord			:	TEXCOORD0,
	out float4	out_ambient_light		:	TEXCOORD1,
	out float4	out_inscatter			:	TEXCOORD2
//#ifdef pc   
//   ,out float3	out_normal  			:	TEXCOORD3
//#endif
   )
{
	
	
#ifndef pc
    // what instance are we? - compute index to fetch from the instance stream
	int instance_index = floor(( index + 0.5 ) / instance_data.x);
#endif

#if defined(pc) && (DX_VERSION == 9)
	// convert fron signed short to unsigned
	// PC doesn't supoort USHORT format
	instance_position += 32767;
#elif DX_VERSION == 11
	float4 instance_position = instance_position_int;	// + 32767;
#else	
	// fetch instance data
	float4 instance_position;
	asm
	{
	    vfetch instance_position,	instance_index, position1;
	};
#endif	
	instance_position.xyz= instance_position.xyz * instance_compression_scale.xyz + instance_compression_offset.xyz;
	
	float3 camera_to_vertex= (instance_position.xyz - Camera_Position);
	float distance= sqrt(dot(camera_to_vertex, camera_to_vertex));
	out_ambient_light.a= saturate(distance * LOD_constants.x + LOD_constants.y);
	
	// if the decorator is not completely faded
#ifndef pc
	[ifAll]
#endif // pc
	if (out_ambient_light.a <= k_decorator_alpha_test_threshold)
	{
		out_position= 0.0f;
		out_texcoord= 0.0f;
		out_ambient_light.rgba= 0.0f;
		out_inscatter= 0.0f;
		return;
	}
	
#ifdef pc
   // convert fron unsigned to signed PC doesn't supoort BYTE4N format
   instance_quaternion = instance_quaternion * 2 - 1;
//   instance_color = 1;
   
#else	
	float4 instance_quaternion;
	float4 instance_color;
	asm
	{
	    vfetch instance_quaternion, instance_index, normal1;
       vfetch instance_color, instance_index.x, color1;
	};
#endif	

	float shifted_bits= instance_position.w / 256;				// integer part == type_index, fractional part == motion_scale
	float type_index= floor(shifted_bits);						// type_index = high 8 bits
	float motion_scale= shifted_bits - type_index;				// motion scale = low 8 bits	(aka sun intensity)

#ifndef pc
	// compute the index index to fetch from the index buffer stream
	float index_index = index + (type_index - instance_index) * instance_data.x;
	float vertex_index= index_index;							// unindexed:  vertex_index == index_index
#endif		

#ifndef pc
	// fetch the actual vertex
	float4 vertex_position;
	float2 vertex_texcoord;
	float3 vertex_normal = -1;
	asm
	{
		vfetch vertex_position,	vertex_index.x, position0;
		vfetch vertex_texcoord.xy, vertex_index.x, texcoord0;
		vfetch vertex_normal.xyz, vertex_index.x, normal0;
	};
#endif		
	vertex_position.xyz= vertex_position.xyz * vertex_compression_scale.xyz + vertex_compression_offset.xyz;
	vertex_texcoord= vertex_texcoord.xy * texture_compression.xy + texture_compression.zw;
	
	float height_scale= 1.0f;
	float2 wind_vector= 0.0f;

#ifdef DECORATOR_WIND
	// apply wind
	wind_vector= sample_wind(instance_position.xy);
	motion_scale *= saturate(vertex_position.z);										// apply model motion scale (increases linearly up to the top)
	wind_vector.xy *= motion_scale;														// modulate wind vector by motion scale
	
	// calculate height offset	(change in height because of bending from wind)
	float wind_squared= dot(wind_vector.xy, wind_vector.xy);							// how far did we move?
	float instance_scale= dot(instance_quaternion.xyzw, instance_quaternion.xyzw);		// scale value
	float height_squared= (instance_scale * vertex_position.z) + 0.01;
	height_scale= sqrt(height_squared / (height_squared + wind_squared));
#endif // DECORATOR_WIND

#ifdef DECORATOR_WAVY
	float phase= vertex_position.z * wave_flow.w + wind_data2.w * wave_flow.z + dot(instance_position.xy, wave_flow.xy);
	float wave= motion_scale * saturate(abs(vertex_position.z)) * sin(phase);
	vertex_position.x += wave;
#endif // DECORATOR_WAVY

	// combine the instance position with the mesh position
	float4 world_position= vertex_position;
	vertex_position.z *= height_scale;
	
	float3 rotated_position= quaternion_transform_point(instance_quaternion, vertex_position.xyz);
	world_position.xyz= rotated_position + instance_position.xyz;										// max scale of 2.0 is built into vertex compression	
	world_position.xy += wind_vector.xy * height_scale;													// apply wind vector after transformation

	out_position= mul(float4(world_position.xyz, 1.0f), View_Projection);
	
#ifdef DECORATOR_SHADED_LIGHT	
	float3 world_normal= rotated_position;
#else
	float3 world_normal= quaternion_transform_point(instance_quaternion, vertex_normal.xyz);
#endif		
	world_normal= normalize(world_normal);					// get rid of scale

	float3 fragment_to_camera_world= Camera_Position - world_position.xyz;
	float3 view_dir= normalize(fragment_to_camera_world);

	float3 diffuse_dynamic_light= 0.0f;
#ifdef DECORATOR_DYNAMIC_LIGHTS		
	// point normal towards camera (two-sided only!)
	float3 two_sided_normal= world_normal * sign(dot(world_normal, fragment_to_camera_world));
	
	// accumulate dynamic lights
	calc_simple_lights_analytical_diffuse_translucent(
		world_position,
		two_sided_normal,
		translucency,
		diffuse_dynamic_light);
#endif // DECORATOR_DYNAMIC_LIGHTS

#ifdef DECORATOR_DOMINANT_LIGHT
	diffuse_dynamic_light += 
		motion_scale * sun_color * calc_diffuse_lobe(world_normal, sun_direction, translucency);
#endif // DECORATOR_DOMINANT_LIGHT

	out_texcoord.xy= vertex_texcoord;
	out_texcoord.zw= 0.0f;	
	out_ambient_light.rgb= (instance_color.rgb * exp2(instance_color.a * 63.75 - 31.75)) + diffuse_dynamic_light;

#ifdef DECORATOR_SHADED_LIGHT
	out_texcoord.z= dot(rotated_position, sun_direction);				// position relative to decorator center, projected onto sun direction
//	out_texcoord.w= dot(rotated_position, rotated_position);			// distance of position from decorator center (normalization term) - dividing z by w will give us a per-pixel cosine term
	out_texcoord.w= sqrt(dot(rotated_position, rotated_position));		// distance of position from decorator center (normalization term) - dividing z by w will give us a per-pixel cosine term
	out_texcoord.z= out_texcoord.z / out_texcoord.w;					// normalized projection == cosine lobe
#endif // DECORATOR_SHADED_LIGHT
	
	float3 extinction;
	compute_scattering(
		Camera_Position,
		world_position.xyz,
		extinction,
		out_inscatter.xyz);
	out_inscatter.w= 0.0f;
	
   out_ambient_light.rgb *= extinction;

#ifdef pc
	out_inscatter.w= out_position.w;
   //out_normal = world_normal;
#endif // pc
}

#endif // VERTEX_SHADER


// ***************************************
// WARNING   WARNING   WARNING
// ***************************************
//    be careful changing this code.  it is optimized to use very few GPRs + interpolators
//			current optimized shader:	3 GPRs

#ifdef pc
albedo_pixel
#else   
float4 
#endif 
default_ps(
	SCREEN_POSITION_INPUT(screen_position),
	in float4	texcoord			:	TEXCOORD0,								// z coordinate is unclamped cosine lobe for the 'sun'
	in float4	ambient_light		:	TEXCOORD1,
	in float4	inscatter			:	TEXCOORD2
//#ifdef pc   
//   ,in float3	normal   			:	TEXCOORD3
//#endif
   ) : SV_Target0					// w unused
{

	float4 light= ambient_light;
#ifdef DECORATOR_SHADED_LIGHT
	{
		[isolate]				// this reduces GPRs by one	
		light.rgb *= saturate(texcoord.z) * contrast.y + contrast.x;
	}
#endif
   
#ifdef pc
   float position_w= inscatter.w;
   inscatter.w= 0;
#endif // pc

	texcoord= sample2D(diffuse_texture, texcoord.xy);								// ###HACK warning: I should use a new variable to hold the albedo sample, but re-using texcoord makes the stupid HLSL compiler generate one less GPR
	
	float4 color= texcoord * light + inscatter;

#if DX_VERSION == 11	
	clip(color.a - k_decorator_alpha_test_threshold);								// alpha clip on D3D11
#endif

	color.rgb *= g_exposure.rrr;
#if DX_VERSION == 9
	//color.a *= (0.5f / k_decorator_alpha_test_threshold);						// convert alpha for alpha-to-coverage (0.5f based)
	clip(color.a - k_decorator_alpha_test_threshold); // we no longer use ATOC
#endif

#ifdef pc
	
	//float2 screen_coords = (screen_position.xy + 0.5f) / texture_size.xy;
	//float3 geo_normal = (sample2D(geo_normal_texture, screen_coords).xyz - 0.5f) * 2.0f; // workaround for xenon shadowing parity
				
	float3 fake_normal = float3(0,0,1); // up
	return convert_to_albedo_target(color, fake_normal, position_w, fake_normal);
#else   
	return color;
#endif // pc
}

#endif // DECORATOR_EDIT

