

float3 calc_area_specular_cheap_ps(
	in float3 world_space_view_reflection_direction,
	in float4 sh_red,		// x,y,z,DC
	in float4 sh_green,		// x,y,z,DC
	in float4 sh_blue)		// x,y,z,DC
{
	// x, y, z, DC
   	float4 SH_constants=			// NOTE: these reconstruct the original signal (lighting environment) - NOT the diffuse convolution of it (which is the RAVI_constants)
   	{
   		0.48860251190291992158638462283835,		// c_x=  0.5 sqrt(3/pi)
		0.48860251190291992158638462283835,		// c_y=  0.5 sqrt(3/pi)
		0.48860251190291992158638462283835,		// c_z=  0.5 sqrt(3/pi)
		0.28209479177387814347403972578039		// c_dc= 0.5 sqrt(1/pi)
   	};

	float3 lightprobe_color;
	lightprobe_color.r= dot(sh_red   * SH_constants, world_space_view_reflection_direction);
	lightprobe_color.g= dot(sh_green * SH_constants, world_space_view_reflection_direction);
	lightprobe_color.b= dot(sh_blue  * SH_constants, world_space_view_reflection_direction);
}
