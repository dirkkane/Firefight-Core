
/*
// returns screenspace velocity in pixels / frame
float2 compute_screenspace_velocity(in float2 fragment_position : VPOS, in float3 fragment_to_camera_world)
{
	// ###ctchou $TODO optimize this by putting all this math into the matrix below
	float3 fragment_position_world= (Camera_Position_PS - fragment_to_camera_world) - object_velocity;

	// calculate pixel coordinate for this pixel in the previous frame
	float4 previous_pixel_coords= mul(float4(fragment_position_world, 1.0f), transpose(combined_screenspace_velocity_matrix));
	previous_pixel_coords.xy /= previous_pixel_coords.w;
	
	float2 pixel_delta= fragment_position.xy - previous_pixel_coords.xy;		
		
	return pixel_delta;
}

float compute_antialias_blur_scalar(in float2 fragment_position : VPOS, in float3 fragment_to_camera_world)
{
	float2 velocity= compute_screenspace_velocity(fragment_position, fragment_to_camera_world);
	
//	float output_alpha= saturate(1.0f - object_velocity.w * dot(velocity.xy, velocity.xy));
//	output_alpha *= output_alpha;

	float output_alpha= saturate(antialias_scalars.x / (antialias_scalars.y + dot(velocity.xy, velocity.xy)));
	
	return output_alpha;
}
*/


float compute_antialias_blur_scalar_from_distance(in float distance)
{
	// ###ctchou $PERF $TODO could either pre-calculate this on the CPU per object, or calculate this per-vertex for per-bone velocities..
	float weighted_speed=	object_velocity.w;
/*
	{
		float3 relative_velocity= camera_velocity.xyz - object_velocity.xyz;
	
		// we want to weight forward/back movement less than side-to-side movement (relative to your camera)
		float3 weighted_velocity= relative_velocity.xyz - p_camera_view_direction_prescaled.xyz * dot(p_camera_view_direction_prescaled.xyz, relative_velocity.xyz);
		weighted_speed= length(weighted_velocity);
	}
*/
	float screen_speed=		weighted_speed / distance;						// approximate
	float output_alpha= saturate(antialias_scalars.z + antialias_scalars.w * saturate(antialias_scalars.x / (antialias_scalars.y + screen_speed)));		// this provides a much smoother falloff than a straight linear scale

	return output_alpha;
}


float compute_antialias_blur_scalar(in float3 fragment_to_camera_world)
{
	float distance= length(fragment_to_camera_world.xyz);
	return compute_antialias_blur_scalar_from_distance(distance);
}


