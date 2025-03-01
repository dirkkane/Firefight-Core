//#include "clip_plane.fx"
#include "dynamic_light_clip.fx"

//#ifndef pc
#define ALPHA_OPTIMIZATION
//#endif

//#define NORMAL_DEBUG

#ifndef APPLY_OVERLAYS
#define APPLY_OVERLAYS(color, texcoord, view_dot_normal)
#endif // APPLY_OVERLAYS

PARAM_SAMPLER_2D(radiance_map);

PARAM_SAMPLER_2D(dynamic_light_gel_texture);
//float4 dynamic_light_gel_texture_xform;		// no way to extern this, so I replace it with p_dynamic_light_gel_xform which is aliased on p_lighting_constant_4
#include "common.fx"

float3 get_constant_analytical_light_dir_vs()
{
 	return -normalize(v_lighting_constant_1.xyz + v_lighting_constant_2.xyz + v_lighting_constant_3.xyz);		// ###ctchou $PERF : pass this in as a constant
}


void get_albedo_and_normal(out float3 bump_normal, out float4 albedo, in float3 texcoord, in float3x3 tangent_frame, in float3 fragment_to_camera_world, in float2 fragment_position, in float4 misc)
{
#ifdef always_calc_albedo
	
	calc_bumpmap_ps(texcoord.xy, fragment_to_camera_world, tangent_frame, bump_normal);
	calc_albedo_ps(texcoord.xy, albedo, bump_normal, misc, normalize(fragment_to_camera_world), fragment_position);
	#if defined(apply_soft_fade)
		apply_soft_fade(albedo, tangent_frame[2].xyz, normalize(fragment_to_camera_world), texcoord.z, fragment_position);
	#endif
	
#else // always_calc_albedo
	
	#ifdef maybe_calc_albedo
		if (actually_calc_albedo)					// transparent objects must generate their own albedo + normal
		{
			calc_bumpmap_ps(texcoord.xy, fragment_to_camera_world, tangent_frame, bump_normal);
			calc_albedo_ps(texcoord.xy, albedo, bump_normal, misc, normalize(fragment_to_camera_world), fragment_position);
	#if defined(apply_soft_fade)
			apply_soft_fade(albedo, tangent_frame[2].xyz, normalize(fragment_to_camera_world), texcoord.z, fragment_position);
	#endif
		}
		else		
	#endif // maybe_calc_albedo
		{
	#ifndef pc
			fragment_position.xy+= p_tiling_vpos_offset.xy;
	#endif
			
	#if DX_VERSION == 11
			int3 fragment_position_int = int3(fragment_position.xy, 0);
			bump_normal = normal_texture.Load(fragment_position_int) * 2.0f - 1.0f;
			albedo = albedo_texture.Load(fragment_position_int);
	#else
			float2 screen_texcoord= (fragment_position.xy + float2(0.5f, 0.5f)) / texture_size.xy;
			bump_normal= tex2D(normal_texture, screen_texcoord).xyz * 2.0f - 1.0f;
			albedo= tex2D(albedo_texture, screen_texcoord);
	#endif // DX_VERSION
		}
#endif // always_calc_albedo
}
	
struct albedo_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
	float2 texcoord					: TEXCOORD0;
	float4 normal					: TEXCOORD1;
	float3 binormal					: TEXCOORD2;
	float3 tangent					: TEXCOORD3;
	float3 fragment_to_camera_world	: TEXCOORD4;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
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
	always_local_to_view(vertex, local_to_world_transform, vsout.position, true);
	
	// normal, tangent and binormal are all in world space
	vsout.normal.xyz = vertex.normal;
	vsout.normal.w = vsout.position.w;
	vsout.texcoord = vertex.texcoord;
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;

	// world space vector from vertex to eye/camera
	vsout.fragment_to_camera_world = Camera_Position - vertex.position;

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
	
	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal.xyz= normalize(vsout.normal.xyz);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif

	float3 view_dir = normalize(vsout.fragment_to_camera_world);
	
	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal.xyz };
	
	// convert view direction from world space to tangent space
	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	
	// compute parallax
	float2 texcoord;
	calc_parallax_ps(vsout.texcoord, view_dir_in_tangent_space, texcoord);

	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);
	
   	// compute the bump normal in world_space
	float3 bump_normal;
	calc_bumpmap_ps(texcoord, vsout.fragment_to_camera_world, tangent_frame, bump_normal);
	
	float4 albedo;
    calc_albedo_ps(texcoord, albedo, bump_normal, misc, view_dir, vsout.position.xy);
	
#ifndef NO_ALPHA_TO_COVERAGE
	albedo.w= output_alpha;
#endif
	
	#ifdef NORMAL_DEBUG
    albedo.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif
	
	return convert_to_albedo_target(albedo, bump_normal, vsout.normal.w, tangent_frame[2]);
}



#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
albedo_vsout static_default_vs(
	in vertex_type vertex)
{
	return albedo_vs(vertex);
}

accum_pixel static_default_ps(
	in albedo_vsout vsout)
{
	albedo_pixel result= albedo_ps(vsout);
    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(result.albedo_specmask, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}

float4 calc_output_color_with_explicit_light_quadratic(
	float2 fragment_position,
	float3x3 tangent_frame,				// = {tangent, binormal, normal};
	float4 sh_lighting_coefficients[10],
	float3 fragment_to_camera_world,	// direction to eye/camera, in world space
#ifdef APPLY_FIXES
	float3 original_texcoord,
#else
	float2 original_texcoord,
#endif
	float4 prt_ravi_diff,
	float3 light_direction,
	float3 light_intensity,
	float3 extinction,
	float3 inscatter,
	float4 misc,
	out float4 ssr_color)
{
	float3 view_dir= normalize(fragment_to_camera_world);

	// convert view direction to tangent space
	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	
	// compute parallax
	float2 texcoord;
	calc_parallax_ps(original_texcoord.xy, view_dir_in_tangent_space, texcoord);

	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);

	// get diffuse albedo, specular mask and bump normal
	float3 bump_normal;
	float4 albedo;	
    float sf_depth = 0.0f;
#ifdef APPLY_FIXES
	sf_depth = original_texcoord.z;
#endif
    get_albedo_and_normal(bump_normal, albedo, float3(texcoord, sf_depth), tangent_frame, fragment_to_camera_world, fragment_position, misc);
	
	// compute a blended normal attenuation factor from the length squared of the normal vector
	// blended normal pixels are MSAA pixels that contained normal samples from two different polygons, therefore the lerped vector upon resolve does not have a length of 1.0
	float normal_lengthsq= dot(bump_normal.xyz, bump_normal.xyz);
#ifndef pc	
	float blended_normal_attenuate= pow(normal_lengthsq, 8);
	light_intensity*= blended_normal_attenuate;
#endif

	// normalize bump to make sure specular is smooth as a baby's bottom	
	bump_normal /= sqrt(normal_lengthsq);

	float3 specular_mask;
	calc_specular_mask_ps(texcoord, albedo.w, specular_mask);
	
	// calculate view reflection direction (in world space of course)
	float view_dot_normal=	dot(view_dir, bump_normal);
	///  DESC: 18 7 2007   12:50 BUNGIE\yaohhu :
	///    We don't need to normalize view_reflect_dir, as long as bump_normal and view_dir have been normalized
	/// float3 view_reflect_dir= normalize( (view_dot_normal * bump_normal - view_dir) * 2 + view_dir );
	float3 view_reflect_dir= (view_dot_normal * bump_normal - view_dir) * 2 + view_dir;

	float4 envmap_specular_reflectance_and_roughness;
	float3 envmap_area_specular_only;
	float4 specular_radiance;
	float3 diffuse_radiance= ravi_order_3(bump_normal, sh_lighting_coefficients);
	
	//float4 lightint_coefficients[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
	
	CALC_MATERIAL(material_type)(
		view_dir,						// normalized
		fragment_to_camera_world,		// actual vector, not normalized
		bump_normal,					// normalized
		view_reflect_dir,				// normalized
		
		sh_lighting_coefficients,	
		light_direction,				// normalized
		light_intensity,
		
		albedo.xyz,					// diffuse_reflectance
		specular_mask,
		texcoord,
		prt_ravi_diff,

		tangent_frame,
		misc,

		envmap_specular_reflectance_and_roughness,
		envmap_area_specular_only,
		specular_radiance,
		diffuse_radiance);
		
	//compute environment map
	envmap_area_specular_only= max(envmap_area_specular_only, 0.001f);
	float3 envmap_radiance= CALC_ENVMAP(envmap_type)(view_dir, bump_normal, view_reflect_dir, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, ssr_color);

	//compute self illumination	
	float3 self_illum_radiance= calc_self_illumination_ps(texcoord, albedo.xyz, view_dir_in_tangent_space, fragment_position, fragment_to_camera_world, view_dot_normal) * ILLUM_SCALE;
	
	// apply opacity fresnel effect	
	{
		float final_opacity, specular_scalar;
		calc_alpha_blend_opacity(albedo.w, tangent_frame[2], view_dir, texcoord, final_opacity, specular_scalar);

		envmap_radiance*= specular_scalar;
		specular_radiance*= specular_scalar;
		albedo.w= final_opacity;
	}
	
	float4 out_color;
	
	// set color channels
#ifdef BLEND_MULTIPLICATIVE
	out_color.xyz= (albedo.xyz + self_illum_radiance);		// No lighting, no fog, no exposure
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= out_color.xyz * BLEND_MULTIPLICATIVE;
	out_color.w= ALPHA_CHANNEL_OUTPUT;
#elif defined(BLEND_FRESNEL)
	out_color.xyz= (diffuse_radiance * albedo.xyz * albedo.w + self_illum_radiance + envmap_radiance + specular_radiance);
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= (out_color.xyz * extinction + inscatter * BLEND_FOG_INSCATTER_SCALE) * g_exposure.rrr;
	out_color.w= saturate(specular_radiance.w + albedo.w);
#else
	out_color.xyz= (diffuse_radiance * albedo.xyz + specular_radiance.rgb + self_illum_radiance + envmap_radiance);
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= (out_color.xyz * extinction + inscatter * BLEND_FOG_INSCATTER_SCALE) * g_exposure.rrr;
	out_color.w= ALPHA_CHANNEL_OUTPUT;
#endif
		

	return out_color;
}
	

float4 calc_output_color_with_explicit_light_linear_with_dominant_light(
	float2 fragment_position,
	float3x3 tangent_frame,				// = {tangent, binormal, normal};
	float4 sh_lighting_coefficients[4],
	float3 fragment_to_camera_world,	// direction to eye/camera, in world space
#ifdef APPLY_FIXES
	float3 original_texcoord,
#else
	float2 original_texcoord,
#endif
	float4 prt_ravi_diff,
	float3 light_direction,
	float3 light_intensity,
	float3 extinction,
	float3 inscatter,
	float4 misc,
	out float4 ssr_color)
{

	float3 view_dir= normalize(fragment_to_camera_world);

	// convert view direction to tangent space
	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	
	// compute parallax
	float2 texcoord;
	calc_parallax_ps(original_texcoord.xy, view_dir_in_tangent_space, texcoord);

	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);

	// get diffuse albedo, specular mask and bump normal
	float3 bump_normal;
	float4 albedo;	
    float sf_depth = 0.0f;
#ifdef APPLY_FIXES
	sf_depth = original_texcoord.z;
#endif
    get_albedo_and_normal(bump_normal, albedo, float3(texcoord, sf_depth), tangent_frame, fragment_to_camera_world, fragment_position, misc);
	
	// compute a blended normal attenuation factor from the length squared of the normal vector
	// blended normal pixels are MSAA pixels that contained normal samples from two different polygons, therefore the lerped vector upon resolve does not have a length of 1.0
	float normal_lengthsq= dot(bump_normal.xyz, bump_normal.xyz);
#ifndef pc	
   // PC normals are denormalized due to 8888 format
	float blended_normal_attenuate= pow(normal_lengthsq, 8);
	light_intensity*= blended_normal_attenuate;
#endif

	///  DESC: 20 7 2007   19:54 BUNGIE\yaohhu :
	///   normalize normal to avoid band effect for specular
	bump_normal/=sqrt(normal_lengthsq);

	float3 specular_mask;
	///  DESC: 11 7 2007   18:1 BUNGIE\yaohhu :
	///     Denomalized normal (averaged in AA) will cause artifact (raid bug 44328)
	///     Not perfect, when demoanized only a little, like the wire's top on the ground
	///     We still have problem. Hard to fix theoritically. We can only hack. 
	///     This is my hack:
#ifndef pc	
	if(normal_lengthsq>=1-1e-2f)
	{
    	calc_specular_mask_ps(texcoord, albedo.w, specular_mask);
    }else{
        specular_mask=0;
    }
#else    
   // No MSAA on PC and normals are denormalized due to 8888 format
 	calc_specular_mask_ps(texcoord, albedo.w, specular_mask);
#endif

	// calculate view reflection direction (in world space of course)
	float view_dot_normal=	dot(view_dir, bump_normal);
	///  DESC: 18 7 2007   12:50 BUNGIE\yaohhu :
	///    We don't need to normalize view_reflect_dir, as long as bump_normal and view_dir have been normalized
	/// float3 view_reflect_dir= normalize( (view_dot_normal * bump_normal - view_dir) * 2 + view_dir );
	float3 view_reflect_dir= (view_dot_normal * bump_normal - view_dir) * 2 + view_dir;

	float4 envmap_specular_reflectance_and_roughness;
	float3 envmap_area_specular_only;
	float4 specular_radiance;
	float3 diffuse_radiance= ravi_order_2_with_dominant_light(bump_normal, sh_lighting_coefficients, light_direction, light_intensity);
	
	float4 zero_vec= 0.0f;
	float4 lightint_coefficients[10]= {
		sh_lighting_coefficients[0],
		sh_lighting_coefficients[1],
		sh_lighting_coefficients[2],
		sh_lighting_coefficients[3],
		zero_vec,
		zero_vec,
		zero_vec,
		zero_vec,
		zero_vec,
		zero_vec};

	CALC_MATERIAL(material_type)(
		view_dir,						// normalized
		fragment_to_camera_world,		// actual vector, not normalized
		bump_normal,					// normalized
		view_reflect_dir,				// normalized
		
		lightint_coefficients,	
		light_direction,				// normalized
		light_intensity,
		
		albedo.xyz,					// diffuse_reflectance
		specular_mask,
		texcoord,
		prt_ravi_diff,
		tangent_frame,
		misc,

		envmap_specular_reflectance_and_roughness,
		envmap_area_specular_only,
		specular_radiance,
		diffuse_radiance);
			
	//compute environment map
	envmap_area_specular_only= max(envmap_area_specular_only, 0.001f);
	float3 envmap_radiance= CALC_ENVMAP(envmap_type)(view_dir, bump_normal, view_reflect_dir, envmap_specular_reflectance_and_roughness, envmap_area_specular_only, ssr_color);

	//compute self illumination	
	float3 self_illum_radiance= calc_self_illumination_ps(texcoord, albedo.xyz, view_dir_in_tangent_space, fragment_position, fragment_to_camera_world, view_dot_normal) * ILLUM_SCALE;
	
	// apply opacity fresnel effect	
	{
		float final_opacity, specular_scalar;
		calc_alpha_blend_opacity(albedo.w, tangent_frame[2], view_dir, texcoord, final_opacity, specular_scalar);

		envmap_radiance*= specular_scalar;
		specular_radiance*= specular_scalar;
		albedo.w= final_opacity;
	}
	
	float4 out_color;
	
	// set color channels
#ifdef BLEND_MULTIPLICATIVE
	out_color.xyz= (albedo.xyz + self_illum_radiance);		// No lighting, no fog, no exposure
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= out_color.xyz * BLEND_MULTIPLICATIVE;
	out_color.w= ALPHA_CHANNEL_OUTPUT;
#elif defined(BLEND_FRESNEL)
	out_color.xyz= (diffuse_radiance * albedo.xyz * albedo.w + self_illum_radiance + envmap_radiance + specular_radiance);
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= (out_color.xyz * extinction + inscatter * BLEND_FOG_INSCATTER_SCALE) * g_exposure.rrr;
	out_color.w= saturate(specular_radiance.w + albedo.w);
#else
	out_color.xyz= (diffuse_radiance * albedo.xyz + specular_radiance.rgb + self_illum_radiance + envmap_radiance);
	APPLY_OVERLAYS(out_color.xyz, texcoord, view_dot_normal)
	out_color.xyz= (out_color.xyz * extinction + inscatter * BLEND_FOG_INSCATTER_SCALE) * g_exposure.rrr;
	out_color.w= ALPHA_CHANNEL_OUTPUT;
#endif
		
//	return float4(albedo.xyz, 0);	
	return out_color;
}

struct static_per_pixel_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
#ifdef APPLY_FIXES
	float3 texcoord					: TEXCOORD0;
#else
    float2 texcoord					: TEXCOORD0;
#endif
	float3 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 tangent					: TEXCOORD5;
	float2 lightmap_texcoord		: TEXCOORD6_CENTROID;
	float3 fragment_to_camera_world	: TEXCOORD7;
	float3 extinction				: COLOR0;
	float3 inscatter				: COLOR1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

///constant to do order 2 SH convolution
#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_per_pixel_vsout static_per_pixel_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap)
{
	static_per_pixel_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif

	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal = vertex.normal;
#ifdef APPLY_FIXES
	vsout.texcoord = float3(vertex.texcoord, vsout.position.w);
#else
    vsout.texcoord = vertex.texcoord;
#endif
	vsout.lightmap_texcoord = lightmap.texcoord;
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world = Camera_Position - vertex.position;

	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

#include "lightmap_sampling.fx"

accum_pixel static_per_pixel_ps(
	in static_per_pixel_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
											
	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal= normalize(vsout.normal);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif

	// setup tangent frame
	float3x3 tangent_frame = {vsout.tangent, vsout.binormal, vsout.normal};

	float3 sh_coefficients[4];

	float3 dominant_light_direction;
	float3 dominant_light_intensity;

	sample_lightprobe_texture(
		vsout.lightmap_texcoord.xy,
		sh_coefficients,
		dominant_light_direction,
		dominant_light_intensity);

	float4 prt_ravi_diff= float4(1.0f, 1.0f, 1.0f, dot(tangent_frame[2], dominant_light_direction));

	float4 sh_lighting_coefficients[4];	
	pack_constants_texture_array_linear(sh_coefficients, sh_lighting_coefficients);

	float4 ssr_color;
	float4 out_color= calc_output_color_with_explicit_light_linear_with_dominant_light(
		vsout.position.xy,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		vsout.texcoord,
		prt_ravi_diff,
		dominant_light_direction,
		dominant_light_intensity,
		vsout.extinction,
		vsout.inscatter,
		misc,
		ssr_color);
											
											
	
	
	#ifdef NORMAL_DEBUG
    out_color.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif

	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, ssr_color
#endif
	);
	
}

///constant to do order 2 SH convolution
struct static_sh_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
#ifdef APPLY_FIXES
	float4 texcoord_and_vertexNdotL	: TEXCOORD0;
#else
    float3 texcoord_and_vertexNdotL : TEXCOORD0;
#endif
	float3 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 tangent					: TEXCOORD5;
	float3 fragment_to_camera_world	: TEXCOORD6;
	float3 extinction				: COLOR0;
	float3 inscatter				: COLOR1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_sh_vsout static_sh_vs(
	in vertex_type vertex)
{
	static_sh_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif

	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal = vertex.normal;
	vsout.texcoord_and_vertexNdotL.xy = vertex.texcoord;
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;
	
	vsout.texcoord_and_vertexNdotL.z = dot(vsout.normal, get_constant_analytical_light_dir_vs());
#ifdef APPLY_FIXES
	vsout.texcoord_and_vertexNdotL.w = vsout.position.w;
#endif
		
	// world space direction to eye/camera
	vsout.fragment_to_camera_world.rgb = Camera_Position - vertex.position;
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
accum_pixel static_sh_ps(
	in static_sh_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal= normalize(vsout.normal);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal };

	// build sh_lighting_coefficients
	float4 sh_lighting_coefficients[10]=
		{
			p_lighting_constant_0, 
			p_lighting_constant_1, 
			p_lighting_constant_2, 
			p_lighting_constant_3, 
			p_lighting_constant_4, 
			p_lighting_constant_5, 
			p_lighting_constant_6, 
			p_lighting_constant_7, 
			p_lighting_constant_8, 
			p_lighting_constant_9 
		}; 	
	
    float4 ssr_color;
	float4 prt_ravi_diff= float4(1.0f, 0.0f, 1.0f, dot(tangent_frame[2], k_ps_dominant_light_direction.xyz));
#ifdef APPLY_FIXES
	float3 original_texcoord = vsout.texcoord_and_vertexNdotL.xyw;
#else
    float2 original_texcoord = vsout.texcoord_and_vertexNdotL.xy;
#endif
	float4 out_color= calc_output_color_with_explicit_light_quadratic(
		vsout.position.xy,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		original_texcoord,
		prt_ravi_diff,
		k_ps_dominant_light_direction.xyz,
		k_ps_dominant_light_intensity.xyz,
		vsout.extinction,
		vsout.inscatter,
		misc,
		ssr_color);

	#ifdef NORMAL_DEBUG
    out_color.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif

    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, ssr_color
#endif
	);
}

///constant to do order 2 SH convolution
struct static_per_vertex_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
	float4 texcoord					: TEXCOORD0; // zw contains inscatter.xy
	float3 fragment_to_camera_world	: TEXCOORD1;
	float3 tangent					: TEXCOORD2;
#ifdef APPLY_FIXES
	float4 normal					: TEXCOORD3;
#else
    float3 normal					: TEXCOORD3;
#endif
	float3 binormal					: TEXCOORD4;
	float4 probe0_3_r				: TEXCOORD5;
	float4 probe0_3_g				: TEXCOORD6;
	float4 probe0_3_b				: TEXCOORD7;
	float3 dominant_light_intensity	: TEXCOORD8;
	float4 extinction				: COLOR0;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_per_vertex_vsout static_per_vertex_vs(
	in vertex_type vertex,
	in float4 light_intensity : TEXCOORD3,
	in float4 c0_3_rgbe : TEXCOORD4,
	in float4 c1_1_rgbe : TEXCOORD5,
	in float4 c1_2_rgbe : TEXCOORD6,
	in float4 c1_3_rgbe : TEXCOORD7)
{
	static_per_vertex_vsout vsout;
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
	always_local_to_view(vertex, local_to_world_transform, vsout.position);

    vsout.normal.xyz = vertex.normal;
#ifdef APPLY_FIXES
	vsout.normal.w = vsout.position.w;
#endif
	vsout.texcoord.xy = vertex.texcoord;
	vsout.binormal = vertex.binormal;
	vsout.tangent = vertex.tangent;
	
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
		
	vsout.probe0_3_r = float4(c0_3_rgbe.r, c1_1_rgbe.r, c1_2_rgbe.r, c1_3_rgbe.r);
	vsout.probe0_3_g = float4(c0_3_rgbe.g, c1_1_rgbe.g, c1_2_rgbe.g, c1_3_rgbe.g);
	vsout.probe0_3_b = float4(c0_3_rgbe.b, c1_1_rgbe.b, c1_2_rgbe.b, c1_3_rgbe.b);

	vsout.dominant_light_intensity = light_intensity.xyz;

	vsout.fragment_to_camera_world = Camera_Position - vertex.position;
	
	float3 inscatter;
	compute_scattering(Camera_Position, vertex.position, vsout.extinction.xyz, inscatter);
	vsout.texcoord.zw = inscatter.xy;
	vsout.extinction.w = inscatter.z;

	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
accum_pixel static_per_vertex_ps(
	in static_per_vertex_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif

	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal.xyz= normalize(vsout.normal.xyz);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif

	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal.xyz };

	// build sh_lighting_coefficients
	float4 L0_3[3] = { vsout.probe0_3_r, vsout.probe0_3_g, vsout.probe0_3_b };
	
	//compute dominant light dir
	float3 dominant_light_direction = vsout.probe0_3_r.wyz * 0.212656f + vsout.probe0_3_g.wyz * 0.715158f + vsout.probe0_3_b.wyz * 0.0721856f;
	dominant_light_direction= dominant_light_direction * float3(-1.0f, -1.0f, 1.0f);
	dominant_light_direction= normalize(dominant_light_direction);
	
	float4 lighting_constants[4];
	pack_constants_linear(L0_3, lighting_constants);

	float4 prt_ravi_diff= float4(1.0f, 1.0f, 1.0f, dot(tangent_frame[2], dominant_light_direction));

    float4 ssr_color;
#ifdef APPLY_FIXES
	float3 original_texcoord = float3(vsout.texcoord.xy, vsout.normal.w);
#else
    float2 original_texcoord = vsout.texcoord.xy;
#endif
	float4 out_color= calc_output_color_with_explicit_light_linear_with_dominant_light(
		vsout.position.xy,
		tangent_frame,
		lighting_constants,
		vsout.fragment_to_camera_world,
		original_texcoord,
		prt_ravi_diff,
		dominant_light_direction,
		vsout.dominant_light_intensity,
		vsout.extinction.xyz,
		float3(vsout.texcoord.z, vsout.texcoord.w, vsout.extinction.w),
		misc,
		ssr_color);
	
	#ifdef NORMAL_DEBUG
    out_color.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif
		
    return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, ssr_color
#endif
	);
}

//straight vert color
struct static_per_vertex_color_vsout
{
    float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
#ifdef APPLY_FIXES
	float3 texcoord					: TEXCOORD0;
#else
    float2 texcoord					: TEXCOORD0;
#endif
	float3 vert_color				: TEXCOORD1;
	float3 fragment_to_camera_world	: TEXCOORD2;
	float3 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 tangent					: TEXCOORD5;
	float3 extinction				: COLOR0;
	float3 inscatter				: COLOR1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_per_vertex_color_vsout static_per_vertex_color_vs(
	in vertex_type vertex,
	in float3 vert_color				: TEXCOORD3)
{
	static_per_vertex_color_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	// output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.fragment_to_camera_world = Camera_Position - vertex.position; // world space direction to eye/camera
	
	vsout.normal = vertex.normal;
	vsout.texcoord.xy = vertex.texcoord;
#ifdef APPLY_FIXES
	vsout.texcoord.z = vsout.position.w;
#endif
	vsout.binormal = vertex.binormal;
	vsout.tangent = vertex.tangent;
	vsout.vert_color = vert_color;
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
accum_pixel static_per_vertex_color_ps(
	in static_per_vertex_color_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	
	// normalize interpolated values
	vsout.normal = normalize(vsout.normal);

	// no parallax?

	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(vsout.texcoord.xy, output_alpha);
	
	// get diffuse albedo, specular mask and bump normal
	float4 albedo;	
#ifdef always_calc_albedo
	
	calc_albedo_ps(vsout.texcoord.xy, albedo, vsout.normal, misc, normalize(vsout.fragment_to_camera_world), vsout.position.xy);
	#if defined(apply_soft_fade)
		float sf_depth = 0.0f;
		#ifdef APPLY_FIXES
			sf_depth = vsout.texcoord.z;
		#endif
		apply_soft_fade(albedo, vsout.normal, normalize(vsout.fragment_to_camera_world), sf_depth, vsout.position);
	#endif
	
#else
	
	#ifdef maybe_calc_albedo
		if (actually_calc_albedo)						// transparent objects must generate their own albedo + normal
		{
			calc_albedo_ps(vsout.texcoord.xy, albedo, vsout.normal, misc, normalize(vsout.fragment_to_camera_world), vsout.position.xy);
	#if defined(apply_soft_fade)
			float sf_depth = 0.0f;
		#ifdef APPLY_FIXES
			sf_depth = vsout.texcoord.z;
		#endif
			apply_soft_fade(albedo, vsout.normal, normalize(vsout.fragment_to_camera_world), sf_depth, vsout.position);
	#endif
		}
		else		
	#endif
		{
			//albedo = albedo_texture.Load(int3(vsout.position.xy, 0));
			
	        float2 screen_texcoord = (vsout.position.xy + float2(0.5f, 0.5f)) / texture_size.xy;
	        albedo = tex2D(albedo_texture, screen_texcoord);
	    }
#endif

	//compute self illumination	
    float3 view_dir_none= 0.0f;
#if APPLY_FIXES
	view_dir_none= 1.0f;
#endif
    float3 self_illum_radiance= calc_self_illumination_ps(vsout.texcoord.xy, albedo.xyz, view_dir_none, vsout.position.xy, vsout.fragment_to_camera_world, 1.0f) * ILLUM_SCALE;
	
	float3 simple_light_diffuse_light;
	float3 simple_light_specular_light;
	float3 fragment_position_world = Camera_Position_PS - vsout.fragment_to_camera_world;
	calc_simple_lights_analytical(
		fragment_position_world,
		vsout.normal,
		float3(1.0f, 0.0f, 0.0f),										// view reflection direction (not needed cuz we're doing diffuse only)
		1.0f,
		simple_light_diffuse_light,
		simple_light_specular_light);
	
	// set color channels
	float4 out_color;
#ifdef BLEND_MULTIPLICATIVE
	out_color.xyz= (vsout.vert_color * albedo.xyz + self_illum_radiance) * BLEND_MULTIPLICATIVE;		// No lighting, no fog, no exposure
#else
	out_color.xyz = ((vsout.vert_color + simple_light_diffuse_light) * albedo.xyz + self_illum_radiance);
	out_color.xyz = (out_color.xyz * vsout.extinction + vsout.inscatter * BLEND_FOG_INSCATTER_SCALE) * g_exposure.rrr;
#endif
	//out_color.xyz= vert_color * g_exposure.rgb;
	out_color.w= ALPHA_CHANNEL_OUTPUT;
	
	#ifdef NORMAL_DEBUG
    out_color.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif
		
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
	
}

struct static_prt_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
#ifdef APPLY_FIXES
	float3 texcoord					: TEXCOORD0;
#else
    float2 texcoord					: TEXCOORD0;
#endif
	float3 normal					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 tangent					: TEXCOORD5;
	float3 fragment_to_camera_world	: TEXCOORD6;
	float4 prt_ravi_diff			: TEXCOORD7;
	float3 extinction				: COLOR0;
	float3 inscatter				: COLOR1;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_prt_vsout static_prt_ambient_vs(
	in vertex_type vertex,
#ifdef pc
	in float prt_c0_c3		: BLENDWEIGHT1
#else // xenon
	in float vertex_index	: SV_VertexID
#endif // xenon
	)
{
	static_prt_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
#ifdef pc
	float prt_c0= prt_c0_c3;
#else // xenon
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
	prt_c0= dot(prt_component, prt_values);
#endif // xenon

	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal= vertex.normal;
#ifdef APPLY_FIXES
	vsout.texcoord = float3(vertex.texcoord, vsout.position.w);
#else
    vsout.texcoord = vertex.texcoord;
#endif
	vsout.tangent= vertex.tangent;
	vsout.binormal= vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world= Camera_Position-vertex.position;
	
	float ambient_occlusion= prt_c0;
	float lighting_c0= 	dot(v_lighting_constant_0.xyz, float3(1.0f/3.0f, 1.0f/3.0f, 1.0f/3.0f));			// ###ctchou $PERF convert to monochrome before passing in!
	float ravi_mono= (0.886227f * lighting_c0)/3.1415926535f;
	float prt_mono= ambient_occlusion * lighting_c0;
		
	prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
	ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
	float prt_ravi_ratio= prt_mono /ravi_mono;
	vsout.prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
	vsout.prt_ravi_diff.y= prt_mono;														// unused
	vsout.prt_ravi_diff.z= (ambient_occlusion * 3.1415926535f)/0.886227f;					// specular occlusion % (ambient occlusion)
	vsout.prt_ravi_diff.w= min(dot(vsout.normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
	
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);

	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_prt_vsout static_prt_linear_vs(
	in vertex_type vertex,
	in float4 prt_c0_c3 : BLENDWEIGHT1)
{
	static_prt_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal= vertex.normal;
#ifdef APPLY_FIXES
	vsout.texcoord = float3(vertex.texcoord, vsout.position.w);
#else
    vsout.texcoord = vertex.texcoord;
#endif
	vsout.tangent= vertex.tangent;
	vsout.binormal= vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world= Camera_Position-vertex.position;
	
	// new monochrome PRT/RAVI ratio calculation
	
	
#ifdef pc	
   // on PC vertex linear PRT data is stored in unsigned format convert to signed
	prt_c0_c3 = 2 * prt_c0_c3 - 1;
#endif
	
	// convert to monochrome	
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
	float ravi_mono= ravi_order_2_monochromatic(vsout.normal, SH_monochrome_3120);
		
	prt_mono= max(prt_mono, 0.01f);																			// clamp prt term to be positive
	ravi_mono= max(ravi_mono, 0.01f);																		// clamp ravi term to be larger than prt term by a little bit
	float prt_ravi_ratio= prt_mono / ravi_mono;
	vsout.prt_ravi_diff.x= prt_ravi_ratio;																	// diffuse occlusion % (prt ravi ratio)
	vsout.prt_ravi_diff.y= prt_mono;																		// unused
	vsout.prt_ravi_diff.z= (prt_c0_c3_monochrome.x * 3.1415926535f)/0.886227f;								// specular occlusion % (ambient occlusion)
	vsout.prt_ravi_diff.w= min(dot(vsout.normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)

	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);

	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

void prt_quadratic(
	in float3 prt_c0_c2,
	in float3 prt_c3_c5,
	in float3 prt_c6_c8,	
	in float3 normal,
	float4 local_to_world_transform[3],
	out float4 prt_ravi_diff)
{
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

	float ravi_mono= ravi_order_3_monochromatic(normal, SH_monochrome_3120, SH_monochrome_457, SH_monochrome_8866);
	
	prt_mono= max(prt_mono, 0.01f);													// clamp prt term to be positive
	ravi_mono= max(ravi_mono, 0.01f);									// clamp ravi term to be larger than prt term by a little bit
	float prt_ravi_ratio= prt_mono / ravi_mono;
	prt_ravi_diff.x= prt_ravi_ratio;												// diffuse occlusion % (prt ravi ratio)
	prt_ravi_diff.y= prt_mono;														// unused
	prt_ravi_diff.z= (prt_c0_c3_monochrome.x * 3.1415926535f)/0.886227f;			// specular occlusion % (ambient occlusion)
	prt_ravi_diff.w= min(dot(normal, get_constant_analytical_light_dir_vs()), prt_mono);		// specular (vertex N) dot L (kills backfacing specular)
}

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
static_prt_vsout static_prt_quadratic_vs(
	in vertex_type vertex,
	in float3 prt_c0_c2 : BLENDWEIGHT1,
	in float3 prt_c3_c5 : BLENDWEIGHT2,
	in float3 prt_c6_c8 : BLENDWEIGHT3)
{
	static_prt_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif

	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
	vsout.normal= vertex.normal;
#ifdef APPLY_FIXES
	vsout.texcoord = float3(vertex.texcoord, vsout.position.w);
#else
    vsout.texcoord = vertex.texcoord;
#endif
	vsout.tangent= vertex.tangent;
	vsout.binormal= vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world= Camera_Position-vertex.position;
	
	prt_quadratic(
		prt_c0_c2,
		prt_c3_c5,
		prt_c6_c8,
		vsout.normal,
		local_to_world_transform,
		vsout.prt_ravi_diff);
		
	compute_scattering(Camera_Position, vertex.position, vsout.extinction, vsout.inscatter);

	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

accum_pixel static_prt_ps(
	in static_prt_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal= normalize(vsout.normal);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif
	
	// setup tangent frame
	float3x3 tangent_frame = {vsout.tangent, vsout.binormal, vsout.normal};

	// build sh_lighting_coefficients
	float4 sh_lighting_coefficients[10]=
		{
			p_lighting_constant_0, 
			p_lighting_constant_1, 
			p_lighting_constant_2, 
			p_lighting_constant_3, 
			p_lighting_constant_4, 
			p_lighting_constant_5, 
			p_lighting_constant_6, 
			p_lighting_constant_7, 
			p_lighting_constant_8, 
			p_lighting_constant_9 
		}; 
	
	float4 ssr_color;
#ifdef APPLY_FIXES
	float3 original_texcoord = vsout.texcoord;
#else
    float2 original_texcoord = vsout.texcoord;
#endif
	float4 out_color= calc_output_color_with_explicit_light_quadratic(
		vsout.position.xy,
		tangent_frame,
		sh_lighting_coefficients,
		vsout.fragment_to_camera_world,
		original_texcoord,
		vsout.prt_ravi_diff,
		k_ps_dominant_light_direction.xyz,
		k_ps_dominant_light_intensity.xyz,
		vsout.extinction,
		vsout.inscatter,
		misc,
		ssr_color);
		
	#ifdef NORMAL_DEBUG
    out_color.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif
				
	return CONVERT_TO_RENDER_TARGET_FOR_BLEND(out_color, true, false
#ifdef SSR_ENABLE
		, ssr_color
#endif
	);	
}

struct dynamic_light_vsout
{
	float4 position								: VS_POS_OUTPUT;
	//s_dynamic_light_clip_distance clip_distance : SV_ClipDistance;
#ifdef APPLY_FIXES
	float3 texcoord								: TEXCOORD0;
#else
    float2 texcoord : TEXCOORD0;
#endif
	float3 normal								: TEXCOORD1;
	float3 binormal								: TEXCOORD2;
	float3 tangent								: TEXCOORD3;
	float3 fragment_to_camera_world				: TEXCOORD4;
	float4 fragment_position_shadow				: TEXCOORD5; // homogenous coordinates of the fragment position in projective shadow space
#ifdef misc_attr_define
	float4 misc									: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
dynamic_light_vsout default_dynamic_light_vs(
	in vertex_type vertex)
{
	dynamic_light_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	//output to pixel shader
	float4 local_to_world_transform[3];

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
    vsout.normal = vertex.normal;
#ifdef APPLY_FIXES
	vsout.texcoord = float3(vertex.texcoord, vsout.position.w);
#else
    vsout.texcoord = vertex.texcoord;
#endif
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;

	// world space direction to eye/camera
	vsout.fragment_to_camera_world = Camera_Position - vertex.position;
	
	vsout.fragment_position_shadow = mul(float4(vertex.position, 1.0f), Shadow_Projection);
	
	//vsout.clip_distance = calc_dynamic_light_clip_distance(vsout.position);

	return vsout;
}

dynamic_light_vsout dynamic_light_vs(
	in vertex_type vertex)
{
	return default_dynamic_light_vs(vertex);
}

dynamic_light_vsout dynamic_light_cine_vs(
	in vertex_type vertex)
{
	return default_dynamic_light_vs(vertex);
}

accum_pixel default_dynamic_light_ps(
	in dynamic_light_vsout vsout,
	bool cinematic)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	// normalize interpolated values
#ifndef ALPHA_OPTIMIZATION
	vsout.normal= normalize(vsout.normal);
	vsout.binormal= normalize(vsout.binormal);
	vsout.tangent= normalize(vsout.tangent);
#endif

	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal };

	// convert view direction to tangent space
	float3 view_dir = normalize(vsout.fragment_to_camera_world);
	float3 view_dir_in_tangent_space= mul(tangent_frame, view_dir);
	
	// compute parallax
	float2 texcoord;
	calc_parallax_ps(vsout.texcoord.xy, view_dir_in_tangent_space, texcoord);

	float output_alpha;
	// do alpha test
	calc_alpha_test_ps(texcoord, output_alpha);

	// calculate simple light falloff for expensive light
	float3 fragment_position_world = Camera_Position_PS - vsout.fragment_to_camera_world;
	float3 light_radiance;
	float3 fragment_to_light;
	float light_dist2;
	calculate_simple_light(
		0,
		fragment_position_world,
		light_radiance,
		fragment_to_light);			// return normalized direction to the light

	vsout.fragment_position_shadow.xyz /= vsout.fragment_position_shadow.w; // projective transform on xy coordinates
	
	// apply light gel
	light_radiance *= sample2D(dynamic_light_gel_texture, transform_texcoord(vsout.fragment_position_shadow.xy, p_dynamic_light_gel_xform)).rgb;
	
	// clip if the pixel is too far
//	clip(light_radiance - 0.0000001f);				// ###ctchou $TODO $REVIEW turn this into a dynamic branch?

	// get diffuse albedo, specular mask and bump normal
	float3 bump_normal;
	float4 albedo;	
    float sf_depth = 0.0f;
#if APPLY_FIXES
	sf_depth = vsout.texcoord.z;
#endif
    get_albedo_and_normal(bump_normal, albedo, float3(texcoord,sf_depth), tangent_frame, vsout.fragment_to_camera_world, vsout.position.xy, misc);

	// calculate view reflection direction (in world space of course)
	///  DESC: 18 7 2007   12:50 BUNGIE\yaohhu :
	///    We don't need to normalize view_reflect_dir, as long as bump_normal and view_dir have been normalized
	///    and hlsl reflect can do that directly
	///float3 view_reflect_dir= normalize( (dot(view_dir, bump_normal) * bump_normal - view_dir) * 2 + view_dir );
	float3 view_reflect_dir= -normalize(reflect(view_dir, bump_normal));


	// calculate diffuse lobe
	float3 analytic_diffuse_radiance= light_radiance * dot(fragment_to_light, bump_normal) * albedo.rgb;
	float3 radiance= analytic_diffuse_radiance * GET_MATERIAL_DIFFUSE_MULTIPLIER(material_type)();

	// compute a blended normal attenuation factor from the length squared of the normal vector
	// blended normal pixels are MSAA pixels that contained normal samples from two different polygons, therefore the lerped vector upon resolve does not have a length of 1.0
	float normal_lengthsq= dot(bump_normal.xyz, bump_normal.xyz);
#ifndef pc	
	float blended_normal_attenuate= pow(normal_lengthsq, 8);
#endif	

	// calculate specular lobe
	float3 specular_mask;
	calc_specular_mask_ps(texcoord, albedo.w, specular_mask);

	float3 specular_multiplier= GET_MATERIAL_ANALYTICAL_SPECULAR_MULTIPLIER(material_type)(specular_mask);
	
	if (dot(specular_multiplier, specular_multiplier) > 0.0001f)			// ###ctchou $PERF unproven 'performance' hack
	{
	float3 specular_fresnel_color;
	float3 specular_albedo_color;
	float power_or_roughness;
	float3 analytic_specular_radiance;
	
	float4 spatially_varying_material_parameters;

	CALC_MATERIAL_ANALYTIC_SPECULAR(material_type)(
		view_dir,
		bump_normal,
		view_reflect_dir,
		fragment_to_light,
		light_radiance,
		albedo,									// diffuse reflectance (ignored for cook-torrance)
		texcoord,
		1.0f,
		tangent_frame,
		misc,
		spatially_varying_material_parameters,			// only when use_material_texture is defined
		specular_fresnel_color,							// fresnel(specular_albedo_color)
		specular_albedo_color,							// specular reflectance at normal incidence
		analytic_specular_radiance);					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
	
		radiance += analytic_specular_radiance * specular_multiplier;
	}
	
#ifndef pc	
	radiance*= blended_normal_attenuate;
#endif	
	
	// calculate shadow
	float unshadowed_percentage= 1.0f;
	if (dynamic_light_shadowing)
	{
		if (dot(radiance, radiance) > 0.0f)									// ###ctchou $PERF unproven 'performance' hack
		{
			if (cinematic)
			{
				unshadowed_percentage = sample_percentage_closer_PCF_5x5_block_predicated(vsout.fragment_position_shadow, /*unused*/0.0f);
			}
			else
			{
				unshadowed_percentage = sample_percentage_closer_PCF_3x3_block(vsout.fragment_position_shadow, /*unused*/0.0f);
			}
		}
	}

	float4 out_color;
	
	// set color channels
	out_color.xyz= (radiance) * g_exposure.rrr * unshadowed_percentage;

	// set alpha channel
	out_color.w= ALPHA_CHANNEL_OUTPUT;
	
	#ifdef NORMAL_DEBUG
    out_color.rgb = cross(vsout.binormal.xyz, vsout.tangent.xyz);
	#endif

    return convert_to_render_target(out_color, true, true
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
}

accum_pixel dynamic_light_ps(
	in dynamic_light_vsout vsout)
{
	return default_dynamic_light_ps(vsout, false);
}

accum_pixel dynamic_light_cine_ps(
	in dynamic_light_vsout vsout)
{
	return default_dynamic_light_ps(vsout, true);
}

struct sfx_distort_vsout
{
    float4 position		: VS_POS_OUTPUT;
    float4 texcoord		: TEXCOORD0;
    float1 distortion	: TEXCOORD1;
#ifdef misc_attr_define
    float4 misc			: TEXCOORD9;
#endif
};


sfx_distort_vsout sfx_distort_vs(
	in vertex_type vertex)
{
    sfx_distort_vsout vsout;
#ifdef misc_attr_define
	misc_attr_animation(
		vertex,
		vsout.misc
	);
#endif
	
	//output to pixel shader
    float4 local_to_world_transform[3];

	//output to pixel shader
    always_local_to_view(vertex, local_to_world_transform, vsout.position);
	
    float3 view_dir = normalize(vertex.position.xyz - Camera_Position);
    float n_dot_c = dot(vertex.normal.xyz, view_dir);
    float distortion_factor = min(abs(n_dot_c), 1.0);
    vsout.distortion = distortion_factor * distortion_factor * (3.0 - 2.0 * distortion_factor);
	
    vsout.texcoord = float4(vertex.texcoord, vsout.position.w, 1.0f);
	
    return vsout;
}

accum_pixel sfx_distort_ps(
in sfx_distort_vsout vsout)
{
    accum_pixel out_pixel;
	
    float2 sfx_distort, distort_raw;
    distort_proc_ps(vsout.texcoord.xy, sfx_distort, distort_raw);
        
#if DISTORT_TYPE(distort_proc_ps) == DISTORT_TYPE_distort_on_ps
    out_pixel.color.rg = (sfx_distort * vsout.distortion) * 0.5f + 0.50195998f;
    out_pixel.color.b = 1.0f;
    out_pixel.color.a = saturate(dot(abs(distort_raw * 10.0f), 1.0f)) * vsout.texcoord.w;
#else
    out_pixel.color = 0.0f;
#endif
	
    out_pixel.dark_color = 0.0f;
#ifdef SSR_ENABLE
	out_pixel.ssr_color = 0.0f;
#endif
	
    return out_pixel;
}

//===============================================================
// DEBUG

struct lightmap_debug_mode_vsout
{
	float4 position					: VS_POS_OUTPUT;
	//float clip_distance				: SV_ClipDistance;
	float2 lightmap_texcoord		: TEXCOORD0;
	float3 normal					: TEXCOORD1;
	float2 texcoord					: TEXCOORD2;
	float3 tangent					: TEXCOORD3;
	float3 binormal					: TEXCOORD4;
	float3 fragment_to_camera_world	: TEXCOORD5;
#ifdef misc_attr_define
	float4 misc						: TEXCOORD9;
#endif
};

#ifdef xdk_2907
[noExpressionOptimizations] 
#endif
lightmap_debug_mode_vsout lightmap_debug_mode_vs(
	in vertex_type vertex,
	in s_lightmap_per_pixel lightmap)
{
	lightmap_debug_mode_vsout vsout;
	
	float4 local_to_world_transform[3];
	vsout.fragment_to_camera_world = Camera_Position - vertex.position;

	//output to pixel shader
	always_local_to_view(vertex, local_to_world_transform, vsout.position);
	vsout.lightmap_texcoord = lightmap.texcoord;
	vsout.normal = vertex.normal;
	vsout.texcoord = vertex.texcoord;
	vsout.tangent = vertex.tangent;
	vsout.binormal = vertex.binormal;
	
	//vsout.clip_distance = dot(vsout.position, v_clip_plane);

	return vsout;
}

accum_pixel lightmap_debug_mode_ps(
	in lightmap_debug_mode_vsout vsout)
{
#ifdef misc_attr_define
	float4 misc = vsout.misc;
#else
	float4 misc = { 0.0f, 0.0f, 0.0f, 0.0f };
#endif
	float4 out_color;
	
	// setup tangent frame
	float3x3 tangent_frame = { vsout.tangent, vsout.binormal, vsout.normal };
	float3 bump_normal;
	calc_bumpmap_ps(vsout.texcoord, vsout.fragment_to_camera_world, tangent_frame, bump_normal);

	float3 ambient_only= 0.0f;
	float3 linear_only= 0.0f;
	float3 quadratic= 0.0f;

	out_color= display_debug_modes(
		vsout.lightmap_texcoord,
		vsout.normal,
		vsout.texcoord,
		vsout.tangent,
		vsout.binormal,
		bump_normal,
		ambient_only,
		linear_only,
		quadratic);
		
	return convert_to_render_target(out_color, true, false
#ifdef SSR_ENABLE
		, 0.0f
#endif
	);
	
}
