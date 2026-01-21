#line 1 "source\rasterizer\hlsl\overhead_map_geometry.hlsl"

#include "global.fx"
#include "hlsl_constant_mapping.fx"
#include "hlsl_vertex_types.fx"
#include "overhead_map_geometry_registers.fx"

//@generate world
//@generate rigid

struct overhead_map_output
{
	float4 HPosition	:SV_Position;
	float3 PosWorld		:POSITION2;
    float3 Color		:COLOR0;
};

overhead_map_output default_vs(vertex_type IN)
{
	float3 dark_color= {0.004, 0.004, 0.012};
	float3 light_color= {0.072, 0.056, 0.00};
	float3 up= {0.0, 0.0, 1.0};
    overhead_map_output OUT;
    
    float3 transformed_position;
    
    transformed_position.x= dot(float4(IN.position, 1.0f), map_transform1);
    transformed_position.y= dot(float4(IN.position, 1.0f), map_transform2);
    transformed_position.z= dot(float4(IN.position, 1.0f), map_transform3);

    OUT.HPosition= mul(float4(transformed_position, 1.0f), View_Projection);
    OUT.PosWorld= IN.position;
    
    if (map_override.w>0.0)
    {
		OUT.Color= map_override.xyz;
    }
    else
    {
		float dot_result= dot(up, IN.normal);

		if (dot_result>0.8)
		{
			OUT.Color= light_color;
		}
		else
		{
			OUT.Color= dark_color;
		}    
    }

    return OUT;
}

// pixel fragment entry points
float4 default_ps(overhead_map_output IN) : SV_Target
{
	//float pixel_to_center_distance= distance(float3(12.60, 2.17, -6.92), IN.PosWorld);
	float pixel_to_center_distance= distance(map_sphere, IN.PosWorld);
	float4 result= float4(IN.Color, 1.0f);
	
	if (pixel_to_center_distance>map_sphere.w)
	{
		result.xyz= 0.0;
	}
	else
	{
		// get the range from [0.8..1]
		float edge_range= 5.0*((pixel_to_center_distance/map_sphere.w)-0.8);
		edge_range= max(edge_range, 0);
		float power_adjustment= 1.0f + 40.0*pow(edge_range, 2.0);

		result.xyz= result.xyz*power_adjustment*blend_factor.x;
	}
	
	return result;
}
