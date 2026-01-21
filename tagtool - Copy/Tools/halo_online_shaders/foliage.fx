#ifdef disable_register_reorder
// magic pragma given to us by the DX10 team
// to disable the register reordering pass that was
// causing a lot of pain on the PC side of the compiler
// with this pragma we get a massive speedup on compile times
// on the PC side
#pragma ruledisable 0x0a0c0101
#endif // #ifdef disable_register_reorder

#include "global.fx"
#include "hlsl_constant_mapping.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"
//#include "clip_plane.fx"

#include "misc_attr_animation.fx"
#include "albedo.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"
#include "albedo_pass.fx"
#include "blend.fx"

#include "shadow_generate.fx"

#include "spherical_harmonics.fx"

PARAM(float, g_tree_animation_coeff);

PARAM(float, animation_amplitude_horizontal);

// 
// DESC: 
// params
//   Desc: phase offset
// Return 
//   Desc a vaule -1 to 1
// @pre
// @post
// @invariants

float vibration(in float offset)
{
	///  DESC: 1 7 2007   21:35 BUNGIE\yaohhu :
	///    Use frc and abs make a repeat forth back movement
	float vibration_base= abs(frac(offset+g_tree_animation_coeff)-0.5f)*2;
	// Use taylor to simulate spring
	float x=(0.5f-vibration_base)*3.14159265f;
	return sin(x);
}

// 
// DESC: Displace leaf branch's vertex position in 3d space (world space usually)
// params
//   Desc: 
// Return 
//   Desc 
// @pre  texture_coord should be placed randomly
// @post
// @invariants

float3 animation_offset(in float2 texture_coord)
{    
    //if(texture_coord.y<0)		return float3(0,0,15);
    float distance=frac(texture_coord.x);
    
	float id=texture_coord.x-distance+3; //add a minimum offset
	float vibration_coeff_horizontal= vibration(id/0.53);
	id+=floor(texture_coord.y)*7;
	float vibration_coeff_vertical= vibration(id/1.1173);
	float dirx= frac(id/0.727)-0.5f;
	float diry= frac(id/0.371)-0.5f;
	
	return float3(
		float2(dirx,diry)*vibration_coeff_horizontal,
		vibration_coeff_vertical*0.3f)*
		distance*animation_amplitude_horizontal;
}

#define DEFORM_TYPE(deform) DEFORM_TYPE_##deform
#define DEFORM_TYPE_deform_world 0
#define DEFORM_TYPE_deform_rigid 1

///  $FIXME: 2 7 2007   12:12 BUNGIE\yaohhu :
///    I copied the above function and added my code without understanding it
///    a modified version of always_local_to_view(...)
void tree_animation_special_local_to_view(
    inout vertex_type vertex,
    out float4 local_to_world_transform[3], 
    out float4 position)
{
    // always practice safe-shader-compilation, kids.
    // (brought to you by trojan)
    [isolate]
    {
       if (always_true)
       {
         vertex_type vertex_copy= vertex;
         float4 local_to_world_transform_copy[3];
         deform(vertex_copy, local_to_world_transform_copy);
         
         ///  $FIXME: 3 7 2007   10:32 BUNGIE\yaohhu :
         ///    some time deform = deform_rigid  which need decompression
         ///    some time deform = deform_world  which don't need decompression
         ///    Can we fix foliage's usage?
#if DEFORM_TYPE(deform) == DEFORM_TYPE_deform_world
		 float2 vertex_texture_coord=vertex.texcoord;
#elif DEFORM_TYPE(deform) == DEFORM_TYPE_deform_rigid
         float2 vertex_texture_coord=vertex.texcoord*UV_Compression_Scale_Offset.xy + UV_Compression_Scale_Offset.zw;
#else
         float2 vertex_texture_coord=float2(0,0);
         // and probabally crash me here next time.
#endif
         vertex_copy.position+=animation_offset(vertex_texture_coord);
         position= mul(float4(vertex_copy.position, 1.0f), View_Projection);
       }
       else 
       {
         position= float4(0, 0, 0, 0);
       }
    }
    
    deform(vertex, local_to_world_transform);
}


//float4 get_albedo(
//	in float2 fragment_position)
//{
//	float4 albedo;
//
//	{
//#ifndef pc
//		fragment_position.xy+= p_tiling_vpos_offset.xy;
//#endif
//
//		albedo = albedo_texture.Load(int3(fragment_position.xy, 0));
//	}
//	
//	return albedo;
//}
							
float4 get_albedo(
	in float2 fragment_position)
{
	float4 albedo;

	{
#ifndef pc
		fragment_position.xy+= p_tiling_vpos_offset.xy;
#endif

#ifdef pc
		float2 screen_texcoord= (fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy;
		albedo= tex2D(albedo_texture, screen_texcoord);
#else // xenon
		float2 screen_texcoord= fragment_position.xy;
		float4 bump_value;
		asm {
			tfetch2D albedo, screen_texcoord, albedo_texture, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true
		};
#endif // xenon
	}
	
	return albedo;
}

struct albedo_vsout
{
	float4 position					: SV_Position;
	//float clip_distance				: SV_ClipDistance;
	float2 texcoord					: TEXCOORD0;
	float4 normal					: TEXCOORD1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

//entry point albedo
albedo_vsout albedo_vs(
	in vertex_type vertex)
{
	albedo_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	float4 local_to_world_transform[3];
		
	//output to pixel shader
	tree_animation_special_local_to_view(vertex, local_to_world_transform, vsout.position);

	vsout.normal.xyz = vertex.normal;
	vsout.normal.w = vsout.position.w;
	vsout.texcoord = vertex.texcoord;
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

albedo_pixel albedo_ps(
	in albedo_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
		
	float4 albedo;
    calc_albedo_ps(vsout.texcoord, albedo, vsout.normal.xyz, misc, float3(0, 0, 0), vsout.position.xy);
	
    float output_alpha;
	// do alpha test
    calc_alpha_test_ps(vsout.texcoord, output_alpha, albedo.a);
	
#ifndef NO_ALPHA_TO_COVERAGE
	albedo.w= output_alpha;
#endif
	
	return convert_to_albedo_target(albedo, vsout.normal.xyz, vsout.normal.w, vsout.normal.xyz);
}

PARAM(float, diffuse_coefficient);
PARAM(float, specular_coefficient);
PARAM(float, back_light);
PARAM(float, roughness);

struct static_common_vsout
{
#ifdef PIXEL_SHADER
	float4 position					: VPOS;
#else
    float4 position					: SV_Position;
#endif
	//float clip_distance				: SV_ClipDistance;
	float2 texcoord					: TEXCOORD0;
	float3 lighting					: TEXCOORD1;
	float3 extinction				: COLOR0;
	float3 inscatter				: COLOR1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

static_common_vsout static_common_vs(
	in vertex_type vertex,
	out float4 local_to_world_transform[3])
{
	static_common_vsout vsout;
	
	//output to pixel shader
	tree_animation_special_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	float3 normal= vertex.normal;
	vsout.texcoord = vertex.texcoord;
	
	// build sh_lighting_coefficients
	float4 sh_lighting_coefficients[10]=
	{
		v_lighting_constant_0, 
		v_lighting_constant_1, 
		v_lighting_constant_2, 
		v_lighting_constant_3, 
		v_lighting_constant_4, 
		v_lighting_constant_5, 
		v_lighting_constant_6, 
		v_lighting_constant_7, 
		v_lighting_constant_8, 
		v_lighting_constant_9 
	}; 	
		
	vsout.lighting = ravi_order_3(normal, sh_lighting_coefficients);
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

accum_pixel static_common_ps(
	in static_common_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif

	float4 out_color;
	//float4 albedo = get_albedo(vsout.position);
	
	
    float2 screen_texcoord = (vsout.position.xy + float2(0.5f, 0.5f)) / texture_size.xy;
    float4 albedo = tex2D(albedo_texture, screen_texcoord);
	
	// need to recalculate for alpha testing from albedo
    float4 albedo_alpha_test_only;
    calc_albedo_ps(vsout.texcoord, albedo_alpha_test_only, float3(0, 0, 1), misc, float3(0, 0, 0), vsout.position.xy);
	
    float output_alpha;
	// do alpha test
    calc_alpha_test_ps(vsout.texcoord, output_alpha, albedo_alpha_test_only.a);
	
	out_color.xyz = (vsout.lighting * albedo.xyz * vsout.extinction + vsout.inscatter * BLEND_FOG_INSCATTER_SCALE) * g_exposure.rrr;
	out_color.w= 0.0f;

#ifndef NO_ALPHA_TO_COVERAGE
	out_color.w= output_alpha;
#endif
   
    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}


//entry_point static_sh
static_common_vsout static_sh_vs(
	in vertex_type vertex)
{
	static_common_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	//output to pixel shader
	float4 local_to_world_transform[3];
	vsout = static_common_vs(
		vertex, 
		local_to_world_transform);

	return vsout;
}

accum_pixel static_sh_ps(
	in static_common_vsout vsout)
{
	return static_common_ps(vsout);
}

static_common_vsout static_per_pixel_vs(
	in vertex_type vertex)
{
	static_common_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	float4 local_to_world_transform[3];
	vsout = static_common_vs(
		vertex,
		local_to_world_transform);
	//no one should be using the foliage shader and per pixel lighting, output red as a warning.
	vsout.lighting.g = vsout.lighting.b = 0.0f;

	return vsout;
}

accum_pixel static_per_pixel_ps(
	in static_common_vsout vsout)
{
	return static_common_ps(vsout);	
}

static_common_vsout static_per_vertex_vs(
	in vertex_type vertex,
	in float4 light_intensity : TEXCOORD3,
	in float4 c0_3_rgbe : TEXCOORD4,
	in float4 c1_1_rgbe : TEXCOORD5,
	in float4 c1_2_rgbe : TEXCOORD6,
	in float4 c1_3_rgbe : TEXCOORD7)
{
	static_common_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif

#ifdef pc	
   // on PC vertex lightnap is stored in unsigned format
   // convert to signed
   light_intensity = 2 * light_intensity - 1;
	c0_3_rgbe = 2 * c0_3_rgbe - 1;
	c1_1_rgbe = 2 * c1_1_rgbe - 1;
	c1_2_rgbe = 2 * c1_2_rgbe - 1;
	c1_3_rgbe = 2 * c1_3_rgbe - 1;
#endif

	// output to pixel shader
	float4 local_to_world_transform[3];
	
	//output to pixel shader
	tree_animation_special_local_to_view(vertex, local_to_world_transform, vsout.position);

	float4 probe0_3_r;
	float4 probe0_3_g;
	float4 probe0_3_b;
	float3 dominant_light_intensity;
	
	float scale= exp2(light_intensity.a * 31.75f);
	light_intensity.rgb*= scale;
	
	scale= exp2(c0_3_rgbe.a * 31.75f);
	c0_3_rgbe.rgb*= scale;
	
	scale= exp2(c1_1_rgbe.a * 31.75f);
	c1_1_rgbe.rgb*= scale;

	scale= exp2(c1_2_rgbe.a * 31.75f);
	c1_2_rgbe.rgb*= scale;
	
	scale= exp2(c1_3_rgbe.a * 31.75f);
	c1_3_rgbe.rgb*= scale;
		
	probe0_3_r= float4(c0_3_rgbe.r, c1_1_rgbe.r, c1_2_rgbe.r, c1_3_rgbe.r);
	probe0_3_g= float4(c0_3_rgbe.g, c1_1_rgbe.g, c1_2_rgbe.g, c1_3_rgbe.g);
	probe0_3_b= float4(c0_3_rgbe.b, c1_1_rgbe.b, c1_2_rgbe.b, c1_3_rgbe.b);
		
	dominant_light_intensity= light_intensity.xyz;
	
	// build sh_lighting_coefficients
	float4 L0_3[3]= {probe0_3_r, probe0_3_g, probe0_3_b};
	
	//compute dominant light dir
	float3 dominant_light_direction= -probe0_3_r.wyz * 0.212656f - probe0_3_g.wyz * 0.715158f - probe0_3_b.wyz * 0.0721856f;
	dominant_light_direction= normalize(dominant_light_direction);
	float4 lighting_constants[4];
	pack_constants_linear(L0_3, lighting_constants);
	
	float3 normal= vertex.normal;
	vsout.texcoord = vertex.texcoord;
	vsout.lighting = ravi_order_2_with_dominant_light(normal, lighting_constants, dominant_light_direction, dominant_light_intensity);
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);

	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

accum_pixel static_per_vertex_ps(
	in static_common_vsout vsout)
{
	return static_common_ps(vsout);	
}

static_common_vsout static_prt_ambient_vs(
	in vertex_type vertex,
#ifdef pc
	in float prt_c0_c3 : BLENDWEIGHT1
#else
	in float vertex_index : SV_VertexID
#endif 
	)
{
	static_common_vsout vsout;
	
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif

	float4 local_to_world_transform[3];
	vsout = static_common_vs(
		vertex,
		local_to_world_transform);

#ifdef pc
	float prt_c0= prt_c0_c3;
#else

	// fetch PRT data from compressed 
	float prt_c0;

	float prt_fetch_index= vertex_index * 0.25f;								// divide vertex index by 4
	float prt_fetch_fraction= frac(prt_fetch_index);							// grab fractional part of index (should be 0, 0.25, 0.5, or 0.75) 

	float4 prt_values, prt_component;
	float4 prt_component_match= float4(0.75f, 0.5f, 0.25f, 0.0f);				// bytes are 4-byte swapped (each dword is stored in reverse order)
	asm
	{
		vfetch	prt_values, prt_fetch_index, blendweight1						// grab four PRT samples
		seq		prt_component, prt_fetch_fraction.xxxx, prt_component_match		// set the component that matches to one		
	};
	prt_c0= dot(prt_component, prt_values) * 3.545f;

#endif // xenon

	vsout.lighting *= prt_c0;

	return vsout;
}

static_common_vsout static_prt_linear_vs(
	in vertex_type vertex,
	in float4 prt_c0_c3 : BLENDWEIGHT1)
{
	static_common_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	float4 local_to_world_transform[3];
	vsout = static_common_vs(
		vertex,
		local_to_world_transform);

#ifdef pc	
   // on PC vertex linear PRT data is stored in unsigned format convert to signed
	prt_c0_c3 = 2 * prt_c0_c3 - 1;
#endif

	float4 prt_c0_c3_monochrome= prt_c0_c3;

	float4 SH_monochrome_3120;
	SH_monochrome_3120.xyz= (v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz) / 3.0f;		// ###ctchou $PERF convert to monochrome before setting the constants yo
	SH_monochrome_3120.w= dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));

	//rotate the first 4 coefficients	
	float4 SH_monochrome_local_0123;
	sh_inverse_rotate_0123_monochrome(
		local_to_world_transform,
		SH_monochrome_3120,
		SH_monochrome_local_0123);
		
	float prt_mono=		dot(SH_monochrome_local_0123, prt_c0_c3_monochrome);	
	vsout.lighting *= prt_mono;

	return vsout;
}

static_common_vsout static_prt_quadratic_vs(
	in vertex_type vertex,
	in float3 prt_c0_c2 : BLENDWEIGHT1,
	in float3 prt_c3_c5 : BLENDWEIGHT2,
	in float3 prt_c6_c8 : BLENDWEIGHT3)
{
	static_common_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	float4 local_to_world_transform[3];
	vsout = static_common_vs(
		vertex,
		local_to_world_transform);

	// convert first 4 coefficients to monochrome
	float4 prt_c0_c3_monochrome= float4(prt_c0_c2.xyz, prt_c3_c5.x);			//(prt_c0_c3_r + prt_c0_c3_g + prt_c0_c3_b) / 3.0f;
	float4 SH_monochrome_3120;
	SH_monochrome_3120.xyz= (v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz) / 3.0f;			// ###ctchou $PERF convert to mono before passing in?
	SH_monochrome_3120.w= dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));
	
	// rotate the first 4 coefficients
	float4 SH_monochrome_local_0123;
	sh_inverse_rotate_0123_monochrome(
		local_to_world_transform,
		SH_monochrome_3120,
		SH_monochrome_local_0123);

	float prt_mono=		dot(SH_monochrome_local_0123, prt_c0_c3_monochrome);

	// convert last 5 coefficients to monochrome
	float4 prt_c4_c7_monochrome= float4(prt_c3_c5.yz, prt_c6_c8.xy);						//(prt_c4_c7_r + prt_c4_c7_g + prt_c4_c7_b) / 3.0f;
	float prt_c8_monochrome= prt_c6_c8.z;													//dot(prt_c8, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));
	float4 SH_monochrome_457= (v_lighting_constant_4 + v_lighting_constant_5 + v_lighting_constant_6) / 3.0f;
	float4 SH_monochrome_8866= (v_lighting_constant_7 + v_lighting_constant_8 + v_lighting_constant_9) / 3.0f;

	// rotate last 5 coefficients
	float4 SH_monochrome_local_4567;
	float SH_monochrome_local_8;
	sh_inverse_rotate_45678_monochrome(
		local_to_world_transform,
		SH_monochrome_457,
		SH_monochrome_8866,
		SH_monochrome_local_4567,
		SH_monochrome_local_8);

	prt_mono	+=	dot(SH_monochrome_local_4567, prt_c4_c7_monochrome);
	prt_mono	+=	SH_monochrome_local_8 * prt_c8_monochrome;
	
	vsout.lighting*= prt_mono;
	
	return vsout;
}

accum_pixel static_prt_ps(
	in static_common_vsout vsout)
{
	return static_common_ps(vsout);	
}
