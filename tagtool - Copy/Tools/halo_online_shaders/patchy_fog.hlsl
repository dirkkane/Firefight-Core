#line 2 "source\rasterizer\hlsl\patchy_fog.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"

// Magic stuff we need to define before including render_target.fx in order
// to get HDR output to work
#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

#include "patchy_fog_registers.fx"

// Magic line to couple this to a patchy_fog vertex type
//@generate patchy_fog

struct s_vertex_in
{
	float4 position : POSITION0;
#ifdef pc
	float2 texcoord : TEXCOORD0;
#endif // pc
};

struct s_vertex_out
{
	float4 position : SV_Position;
#ifdef APPLY_FIXES
	float3 texcoord : TEXCOORD0;
#else
    float2 texcoord : TEXCOORD0;
#endif
	float4 world_space : TEXCOORD1;
};

s_vertex_out default_vs(
	s_vertex_in vertex_in
#ifndef pc
	, int vertex_index : SV_VertexID
#endif // pc
	)
{
	s_vertex_out vertex_out;
	
	float2 predefined_texcoords[4]= { {-1, 1}, {-1, -1}, {1, -1}, {1, 1} };
	
	vertex_out.position= mul(vertex_in.position, View_Projection);
	vertex_out.world_space= vertex_in.position;
	vertex_out.world_space/= vertex_out.world_space.w;
#ifndef pc	
	vertex_out.texcoord.xy= predefined_texcoords[vertex_index % 4];
#else
	vertex_out.texcoord.xy= vertex_in.texcoord;
#endif
#ifdef APPLY_FIXES
	vertex_out.texcoord.z = vertex_out.position.w;
#endif
	
	return vertex_out;
}

// Noise texture sampled for fog density
LOCAL_SAMPLER_2D(tex_noise, 0);
// Scene depth texture sampled to fade fog near scene intersections
LOCAL_SAMPLER_2D(tex_scene_depth, 1);

#define SUN_DIR						atmosphere_constant_0.xyz
#define SUN_INTENSITY_OVER_TM		atmosphere_constant_1.xyz  // SUN_INTENSITY / TOTAL_MIE
#define TOTAL_MIE_LOG2E				atmosphere_constant_3.xyz  // TOTAL_MIE * log2(e)
#define MIE_THETA_PREFIX_HGC		atmosphere_constant_5.xyz  // MIE_THETA_PREFIX_HGC = MIE_THETA_PREFIX * (1- HEYEY_GREENSTEIN_CONSTANT * HEYEY_GREENSTEIN_CONSTANT)
#define HEYEY_GREENSTEIN_CONSTANT_PLUS_ONE	atmosphere_constant_2.w
#define HEYEY_GREENSTEIN_CONSTANT_TIMES_TWO	atmosphere_constant_extra.x

//#define SUN_DIR						v_atmosphere_constant_0.xyz
//#define SUN_INTENSITY_OVER_TR_PLUS_TM	v_atmosphere_constant_1.xyz // SUN_INTENSITY_OVER_TR_PLUS_TM = SUN_INTENSITY / ( TOTAL_RAYLEIGH + TOTAL_MIE )
//#define TOTAL_RAYLEIGH_LOG2E		v_atmosphere_constant_2.xyz  // TOTAL_RAYLEIGH_LOG2E = TOTAL_RAYLEIGH * log2(e)
//#define TOTAL_MIE_LOG2E				v_atmosphere_constant_3.xyz  // TOTAL_MIE_LOG2E = TOTAL_MIE * log2(e)
//#define RAYLEIGH_THETA_PREFIX		v_atmosphere_constant_4.xyz
//#define MIE_THETA_PREFIX_HGC		v_atmosphere_constant_5.xyz  // MIE_THETA_PREFIX_HGC = MIE_THETA_PREFIX * (1- HEYEY_GREENSTEIN_CONSTANT * HEYEY_GREENSTEIN_CONSTANT)
//
//#define DIST_BIAS					v_atmosphere_constant_0.w
//#define ATMOSPHERE_ENABLE			v_atmosphere_constant_1.w
//#define MAX_FOG_THICKNESS			v_atmosphere_constant_1.w // we're double-purposing this value
//#define HEYEY_GREENSTEIN_CONSTANT_PLUS_ONE	v_atmosphere_constant_2.w
//#define REFERENCE_DATUM_PLANE		v_atmosphere_constant_3.w
//#define REFERENCE_MIE_HEIGHT_SCALE	v_atmosphere_constant_4.w
//#define REFERENCE_RAY_HEIGHT_SCALE	v_atmosphere_constant_5.w
//#define HEYEY_GREENSTEIN_CONSTANT_TIMES_TWO	v_atmosphere_constant_extra.x

#define k_log2_e	(log2(exp(1)))

// LDR entrypoint
//float4 default_ps(s_vertex_out pixel_in, float2 screen_position : VPOS) : COLOR0

// HDR entrypoint
accum_pixel default_ps(s_vertex_out pixel_in, SCREEN_POSITION_INPUT(screen_position))
{
	int i;
	
	// Screen coordinates with [0,0] in the upper left and [1,1] in the lower right
	float2 screen_normalized_uv= float2(
		window_pixel_bounds.x + pixel_in.texcoord.x * window_pixel_bounds.z,
		window_pixel_bounds.y + pixel_in.texcoord.y * window_pixel_bounds.w);
	float scene_depth= sample2D(tex_scene_depth, screen_normalized_uv).x;
	
#if (! defined(pc)) || (DX_VERSION == 11)
	// Convert the depth from [0,1] to view-space homogenous (.xy = _33 and _43, .zw = _34 and _44 from the projection matrix)
	float2 view_space_scene_depth= inverse_z_transform.xy * scene_depth + inverse_z_transform.zw;
	// Homogenous divide
	view_space_scene_depth.x/= -view_space_scene_depth.y;
#else
	float2 view_space_scene_depth= float2(scene_depth, scene_depth);
#endif
	
	// This value is positive whenever a sheet is visible (e.g. in front of the existing scene)
	// and negative when a sheet is further away than the current scene point.
	float4 view_space_depth_diff0= view_space_scene_depth.xxxx - sheet_depths0.xyzw;
	float4 view_space_depth_diff1= view_space_scene_depth.xxxx - sheet_depths1.xyzw;
	
	float4 fade_factor0= 1.0f;
	float4 fade_factor1= 1.0f;
	
	// The depth fade factor approaches 1.0 the further in front a sheet is from the scene depth.
	// Lower values of attenuation_data.z ("Depth-fade factor" in the tag) cause more gradual fading, while larger values cause sharper boundaries.
	// Clamp the fade factor below 1 so that the sheet doesn't get magnified the further away it is from the scene depth.
	// Clamp it above 0 so that sheets behind the scene don't contribute negatively.
	float4 depth_fade_factor;
	depth_fade_factor= 1.0f - exp(-view_space_depth_diff0.xyzw * attenuation_data.z);
	fade_factor0*= max(float4(0.0f, 0.0f, 0.0f, 0.0f), min(float4(1.0f, 1.0f, 1.0f, 1.0f), depth_fade_factor));	
	depth_fade_factor= 1.0f - exp(-view_space_depth_diff1.xyzw * attenuation_data.z);
	fade_factor1*= max(float4(0.0f, 0.0f, 0.0f, 0.0f), min(float4(1.0f, 1.0f, 1.0f, 1.0f), depth_fade_factor));
	
	// Each sheet has an additional independent fade factor which is the product of: 
	// 1) the first and last sheets' need to be faded-in/faded-out to avoid popping
	// 2) the density multiplier applied to every sheet, controlled by the artist ("Sheet density" in the tag)
	fade_factor0*= sheet_fade_factors0;
	fade_factor1*= sheet_fade_factors1;
	
	// Window coordinates with [0,0] at the center, [1,1] at the upper right, and [-1,-1] at the lower left
	float2 screen_normalized_biased= pixel_in.texcoord;
	
	// Sample 8 sheets worth of data using 8 different texture coordinate sets
	float2 noise_uv;
	float4 noise_values0, noise_values1;
	
	{
		// tex_coord_transform.xy gives us the texture coordinate at the center of the screen
		// tex_coord_transform.zw gives us the [u,v] texture coordinate half-extents for the screen
		// texcoord_basis.xy gives us the rotated u basis vector, texcoord_basis.zw gives us the rotated v basis vector	
		
		noise_uv= tex_coord_transform0.xy 
			+ screen_normalized_biased.x * tex_coord_transform0.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform0.w * texcoord_basis.zw;
		noise_values0.x= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform1.xy 
			+ screen_normalized_biased.x * tex_coord_transform1.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform1.w * texcoord_basis.zw;
		noise_values0.y= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform2.xy 
			+ screen_normalized_biased.x * tex_coord_transform2.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform2.w * texcoord_basis.zw;
		noise_values0.z= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform3.xy 
			+ screen_normalized_biased.x * tex_coord_transform3.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform3.w * texcoord_basis.zw;
		noise_values0.w= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform4.xy 
			+ screen_normalized_biased.x * tex_coord_transform4.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform4.w * texcoord_basis.zw;
		noise_values1.x= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform5.xy 
			+ screen_normalized_biased.x * tex_coord_transform5.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform5.w * texcoord_basis.zw;
		noise_values1.y= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform6.xy 
			+ screen_normalized_biased.x * tex_coord_transform6.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform6.w * texcoord_basis.zw;
		noise_values1.z= sample2D(tex_noise, noise_uv).x;
		
		noise_uv= tex_coord_transform7.xy 
			+ screen_normalized_biased.x * tex_coord_transform7.z * texcoord_basis.xy
			+ screen_normalized_biased.y * tex_coord_transform7.w * texcoord_basis.zw;
		noise_values1.w= sample2D(tex_noise, noise_uv).x;
	}
	noise_values0*= noise_values0;
	noise_values1*= noise_values1;

	// Height-fading
	//
	// Since the post-effect is rendered with a view-space depth of 1.0, we can take the view vector (eye -> sheet)
	// and scale it by the sheet depth to get the vector from the eye to each particular sheet.
	// However, we only need the world-space height coordinate (z) so we can do this with scalar math on 4 sheets at once.
	// We exponentially fade fog so that it decays above a certain height ("Full intensity height" in the tag).
	float3 view_vector= normalize(pixel_in.world_space - eye_position);
	float4 height0= view_vector.zzzz * sheet_depths0.xyzw + eye_position.zzzz;
	float4 height_fade_factor0= min(float4(1.0f, 1.0f, 1.0f, 1.0f), exp(attenuation_data.yyyy * (attenuation_data.xxxx - height0.xyzw)));
	fade_factor0*= height_fade_factor0;	
	float4 height1= view_vector.zzzz * sheet_depths1.xyzw + eye_position.zzzz;
	float4 height_fade_factor1= min(float4(1.0f, 1.0f, 1.0f, 1.0f), exp(attenuation_data.yyyy * (attenuation_data.xxxx - height1.xyzw)));
	fade_factor1*= height_fade_factor1;
	
	// The line integral of fog is simply the sum of the products of fade factors and noise values
	float optical_depth= dot(fade_factor0, noise_values0) + dot(fade_factor1, noise_values1);
	
	// View-dependent scattering calculations
	
	float c_theta= dot(view_vector, SUN_DIR);
	float extinction= 1.0f-exp2(-TOTAL_MIE_LOG2E.x * optical_depth);
	//float extinction= min(1.0f, TOTAL_MIE.x * optical_depth);
	float heyey_term= (HEYEY_GREENSTEIN_CONSTANT_PLUS_ONE - HEYEY_GREENSTEIN_CONSTANT_TIMES_TWO * c_theta);
	float heyey_term_one_pt_five = pow( heyey_term, -1.5f );
	float3 beta_p_theta= MIE_THETA_PREFIX_HGC.xyz * heyey_term_one_pt_five;
	float3 inscatter= SUN_INTENSITY_OVER_TM * beta_p_theta * extinction;

#ifdef APPLY_FIXES
	// the fog have to be faded near opaque surfaces:
	float fog_depth = pixel_in.texcoord.z;
	float depth_diff = view_space_scene_depth.x - fog_depth;
	float full_fade_edge = 0.03; // full fade closer then 0.3 ft.
	float no_fade_edge = 0.3; // no fade beyond the 3 ft. range
	float fog_fade = smoothstep(full_fade_edge, no_fade_edge, depth_diff);

	inscatter *= fog_fade;
#endif

	return convert_to_render_target(float4(inscatter * g_exposure.r, extinction), false, true
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
