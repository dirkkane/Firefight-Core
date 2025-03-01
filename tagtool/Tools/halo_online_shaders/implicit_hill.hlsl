#line 1 "source\rasterizer\hlsl\implicit_hill.hlsl"

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "implicit_hill_registers.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g
#include "render_target.fx"

#include "clip_plane.fx"

//@generate implicit

struct implicit_output
{
	float4 position : SV_Position;
#if DX_VERSION == 11
	float clip_distance : SV_ClipDistance;
#endif
	float3 texcoord_and_vertexNdotL : TEXCOORD0;
	float3 normal : TEXCOORD3;
	float3 binormal : TEXCOORD4;
	float3 tangent : TEXCOORD5;
	float3 fragment_to_camera_world : TEXCOORD6;
	float3 extinction : COLOR0;
	float3 inscatter : COLOR1;
};

implicit_output default_vs(vertex_type IN)
{
    implicit_output OUT;
    float3 pos= IN.position;
    
    if (implicit_use_zscales)
    {
		float offset= implicit_z_scales.x + IN.position.z*implicit_z_scales.z;
		float scale= implicit_z_scales.y + IN.position.z*implicit_z_scales.w;

		pos.xy*=scale;
		pos.z= offset;
	}
	
	float3 transformed_position;
	
    transformed_position.x= dot(float4(pos, 1.0f), implicit_transform1);
    transformed_position.y= dot(float4(pos, 1.0f), implicit_transform2);
    transformed_position.z= dot(float4(pos, 1.0f), implicit_transform3);
        
    OUT.position= mul(float4(transformed_position, 1.0f), View_Projection);
    
   	OUT.normal= float3(0.0f, 0.0f, 1.0f);
   	OUT.tangent= float3(1.0f, 0.0f, 0.0f);
	OUT.binormal= float3(0.0f, 1.0f, 0.0f);

	OUT.texcoord_and_vertexNdotL= float3(IN.texcoord.xy, 1.0f);
	// world space direction to eye/camera
	
	float3 vertex_to_camera= Camera_Position-transformed_position;
	OUT.fragment_to_camera_world.rgb= vertex_to_camera;
	OUT.extinction= implicit_color * (1.0f - exp(-dot(vertex_to_camera, vertex_to_camera * 0.1f)));
	//OUT.extinction= implicit_color;
	OUT.inscatter= float3(0.0f, 0.0f, 0.0f);
		
#if DX_VERSION == 11		
	OUT.clip_distance = dot(OUT.position, v_clip_plane);
#endif
		
    return OUT;
    
}

// pixel fragment entry points
accum_pixel default_ps(implicit_output IN) : SV_Target
{
	return convert_to_render_target(float4(1.0f, 1.0f, 1.0f, 0.0f), false, false
	#ifdef SSR_ENABLE
	, 0
    #endif
    );
}
