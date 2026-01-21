#ifndef _SHARED_SPECULAR_FX_
#define _SHARED_SPECULAR_FX_

//****************************************************************************
// Two lobe phong material model parameters
//****************************************************************************

float normal_specular_power; // power of the specular lobe at normal incident angle
float glancing_specular_power; // power of the specular lobe at glancing incident angle
float fresnel_curve_steepness; // 
// this should be renamed to albedo_blend
float albedo_specular_tint_blend; // mix albedo color into specular reflectance

#if ALBEDO_TYPE(calc_albedo_ps) != ALBEDO_TYPE_calc_albedo_four_change_color_applying_to_specular_ps

float3	normal_specular_tint;						// specular color of the normal specular lobe
float3	glancing_specular_tint;						// specular color of the glancing specular lobe

#else

#define normal_specular_tint tertiary_change_color
#define glancing_specular_tint quaternary_change_color

#endif


float roughness;
float analytical_power; //point light roughness

//*****************************************************************************
// artist fresnel
//*****************************************************************************

void calculate_fresnel(
	in float3 view_dir,
	in float3 normal_dir,
	in float3 albedo_color,
	out float power,
	out float interpolated_roughness,
	out float3 normal_specular_blend_albedo_color,
	out float3 final_specular_color)
{
	//float n_dot_v = dot( normal_dir, view_dir );
    float n_dot_v = saturate(dot(normal_dir, view_dir));
    float fresnel_blend = pow((1.0f - n_dot_v), fresnel_curve_steepness);
    power = lerp(normal_specular_power, glancing_specular_power, fresnel_blend);
    interpolated_roughness = roughness;
    //float3 normal_tint= lerp(normal_specular_tint, albedo_color, albedo_specular_tint_blend);
    //tint= lerp(normal_tint, glancing_specular_tint, fresnel_blend);

    normal_specular_blend_albedo_color = lerp(normal_specular_tint, albedo_color, albedo_specular_tint_blend);
    final_specular_color = lerp(normal_specular_blend_albedo_color, glancing_specular_tint, fresnel_blend);
}


#endif 