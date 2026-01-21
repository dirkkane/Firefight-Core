//#line 2 "source\rasterizer\hlsl\shield_effect.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "deform.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "render_target.fx"
#include "shield_impact_registers.fx"

// noise textures
LOCAL_SAMPLER_2D(shield_impact_noise_texture1, 0);
LOCAL_SAMPLER_2D(shield_impact_noise_texture2, 1);
LOCAL_SAMPLER_2D(shield_impact_depth_texture, 2);


// Magic line to compile this for various needed vertex types
//@generate world
//@generate rigid
//@generate skinned
// INSERT EXTRA VERTEX TYPE HERE (CURSE YOU DUAL_QUAT!!!)


struct s_vertex_out
{
	float4 position : SV_POSITION;
	float4 world_space_pos : TEXCOORD1;
	float4 texcoord : TEXCOORD2;
};

float2 compute_depth_fade2(float2 screen_coords, float depth, float2 inverse_range)
{
    float4 depth_value;

    depth_value= sample2D(shield_impact_depth_texture, (0.5f + screen_coords) / texture_size);
    
    float scene_depth= depth_value.x;
	float delta_depth= scene_depth - depth;

	return saturate(delta_depth * inverse_range);
}


#define EXTRUSION_DISTANCE		(vertex_params.x)
#define OSCILLATION_AMPLITUDE	(vertex_params.z)
#define OSCILLATION_SCALE		(vertex_params.w)
#define OSCILLATION_OFFSET0		(vertex_params2.xy)
#define OSCILLATION_OFFSET1		(vertex_params2.zw)

s_vertex_out default_vs(vertex_type IN)
{
	float4 local_to_world_transform[3];
	deform(IN, local_to_world_transform);

	float3	impact_delta=				IN.position -	impact0_params.xyz;
	float	impact_distance=			length(impact_delta) /	impact0_params.w;
	
	float3	world_position=				IN.position.xyz + IN.normal * EXTRUSION_DISTANCE;

	float noise_value1=			sample2Dlod(shield_impact_noise_texture1, float4(world_position.xy * OSCILLATION_SCALE + OSCILLATION_OFFSET0, 0.0f, 0.0f), 0.0f);
	float noise_value2=			sample2Dlod(shield_impact_noise_texture2, float4(world_position.yz * OSCILLATION_SCALE + OSCILLATION_OFFSET1, 0.0f, 0.0f), 0.0f);

	float noise=				(noise_value1 + noise_value2 - 1.0f) * OSCILLATION_AMPLITUDE;
		
	world_position		+=		IN.normal * noise;
	
	float3 camera_to_vertex=	world_position - Camera_Position.xyz;
		
	float cosine_view=		-dot(normalize(camera_to_vertex), IN.normal);

	s_vertex_out OUT;

	OUT.world_space_pos=		float4(world_position, cosine_view);

	OUT.position=				mul(float4(world_position, 1.0f), View_Projection);	
	OUT.texcoord.xy=			IN.texcoord.xy;
	OUT.texcoord.z=				dot(camera_to_vertex, Camera_Forward.xyz);
	OUT.texcoord.w=				impact_distance;

	return OUT;
}


#define OUTER_SCALE			(edge_scales.x)
#define INNER_SCALE			(edge_scales.y)
#define OUTER_SCALE2		(edge_scales.z)
#define INNER_SCALE2		(edge_scales.w)

#define OUTER_OFFSET		(edge_offsets.x)
#define INNER_OFFSET		(edge_offsets.y)
#define OUTER_OFFSET2		(edge_offsets.z)
#define INNER_OFFSET2		(edge_offsets.w)

#define PLASMA_TILE_SCALE1	(plasma_scales.x)
#define PLASMA_TILE_SCALE2	(plasma_scales.y)

#define PLASMA_TILE_OFFSET1	(plasma_offsets.xy)
#define PLASMA_TILE_OFFSET2	(plasma_offsets.zw)

#define PLASMA_POWER_SCALE	(plasma_scales.z)
#define PLASMA_POWER_OFFSET	(plasma_scales.w)

#define EDGE_GLOW_COLOR		(edge_glow.rgba)
#define PLASMA_COLOR		(plasma_color.rgba)
#define PLASMA_EDGE_COLOR	(plasma_edge_color.rgba)

#define INVERSE_DEPTH_FADE_RANGE	(depth_fade_params.xy)


accum_pixel default_ps(s_vertex_out IN)
{
	float edge_fade=			IN.world_space_pos.w;
	float depth=				IN.texcoord.z;

	float2 depth_fades=			compute_depth_fade2(IN.position, depth, INVERSE_DEPTH_FADE_RANGE);

	float	edge_linear=		saturate(min(edge_fade * OUTER_SCALE + OUTER_OFFSET, edge_fade * INNER_SCALE + INNER_OFFSET));
	float	edge_plasma_linear=	saturate(min(edge_fade * OUTER_SCALE2 + OUTER_OFFSET2, edge_fade * INNER_SCALE2 + INNER_OFFSET2));
	float	edge_quartic=		pow(edge_linear, 4);
	float	edge=				edge_quartic * depth_fades.x;
	float	edge_plasma=		edge_plasma_linear * depth_fades.y;

	float	plasma_noise1=		sample2D(shield_impact_noise_texture1, IN.texcoord.xy * PLASMA_TILE_SCALE1 + PLASMA_TILE_OFFSET1);
	float	plasma_noise2=		sample2D(shield_impact_noise_texture2, IN.texcoord.xy * PLASMA_TILE_SCALE2 - PLASMA_TILE_OFFSET2);		// Do not change the '-' ...   it makes it compile magically (yay for the xbox shader compiler)
	float	plasma_base=		saturate(1.0f - abs(plasma_noise1 - plasma_noise2));
	float	plasma_power=		edge_plasma * PLASMA_POWER_SCALE + PLASMA_POWER_OFFSET;
	float	plasma=				pow(plasma_base, plasma_power);

	float4	hit_color=			impact0_color * saturate(1.0f - IN.texcoord.w);

	float4	final_color=		edge * EDGE_GLOW_COLOR + (PLASMA_EDGE_COLOR * edge_plasma + PLASMA_COLOR + hit_color) * plasma;

	final_color.rgb	*=			g_exposure.r;

	return	convert_to_render_target(final_color, false, false
    #ifdef SSR_ENABLE
    , 0
    #endif
    );
}