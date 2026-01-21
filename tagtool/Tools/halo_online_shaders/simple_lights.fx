/*
	simple lights are organized as an array of 16 structs consisting of 4 float4's
	
		position (xyz)		size (w)
		direction (xyz)		spherical % (w)
		color (xyz)			smooth (w)
		falloff scale (xy)	falloff offset (zw)
*/


#ifndef SIMPLE_LIGHT_DATA
#define SIMPLE_LIGHT_DATA simple_lights
#define SIMPLE_LIGHT_COUNT simple_light_count
#endif // !SIMPLE_LIGHT_DATA

#define PI 3.14159265358979323846264338327950

void calculate_simple_light(
		uniform int light_index,
		in float3 fragment_position_world,
		out float3 light_radiance,
		out float3 fragment_to_light)			// return normalized direction to the light
{
#ifdef dynamic_lights_use_array_notation
#define		LIGHT_DATA(offset, registers)	(SIMPLE_LIGHT_DATA[light_index][(offset)].registers)
#elif DX_VERSION == 9
#define		LIGHT_DATA(offset, registers)	(SIMPLE_LIGHT_DATA[(light_index * 5) + (offset)].registers)
#elif DX_VERSION == 11
#define		LIGHT_DATA(offset, registers)	(SIMPLE_LIGHT_DATA[(light_index * 5) + (offset)].registers)
#endif

#define		LIGHT_POSITION			LIGHT_DATA(0, xyz)
#define		LIGHT_DIRECTION			LIGHT_DATA(1, xyz)
#define		LIGHT_COLOR				LIGHT_DATA(2, xyz)
#define		LIGHT_SIZE				LIGHT_DATA(0, w)
#define		LIGHT_SPHERE			LIGHT_DATA(1, w)
#define		LIGHT_SMOOTH			LIGHT_DATA(2, w)
#define		LIGHT_FALLOFF_SCALE		LIGHT_DATA(3, xy)
#define		LIGHT_FALLOFF_OFFSET	LIGHT_DATA(3, zw)
#define		LIGHT_BOUNDING_RADIUS	LIGHT_DATA(4, x)

	// calculate direction to light (4 instructions)
	fragment_to_light= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
	float  light_dist2= dot(fragment_to_light, fragment_to_light);				// distance to the light, squared
	fragment_to_light  *=rsqrt(light_dist2);									// normalized vector pointing to the light
		
	float2 falloff;
	falloff.x= 1 / (LIGHT_SIZE + light_dist2);									// distance based falloff				(2 instructions)
	falloff.y= dot(fragment_to_light, LIGHT_DIRECTION);							// angle based falloff (spot-light)		(1 instruction)
	falloff= max(0.0001f, falloff * LIGHT_FALLOFF_SCALE + LIGHT_FALLOFF_OFFSET);	// scale, offset, clamp result			(2 instructions)
	falloff.y= pow(falloff.y, LIGHT_SMOOTH) + LIGHT_SPHERE;						// smooth and add ambient				(4 instructions)
	float combined_falloff= saturate(falloff.x) * saturate(falloff.y);								//										(1 instruction)

	light_radiance= LIGHT_COLOR * combined_falloff;								//										(1 instruction)
}

#if DX_VERSION == 9

void simple_lights_analytical_single(
		in int light_index,
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
		in float specular_power,
		inout float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		inout float3 specularly_reflected_light)						// specularly reflected light (not including specular surface color)
{
	// Compute distance squared to light, to see if we can skip this light.
	// Note: This is also computed in calculate_simple_light below, but the shader
	// compiler will remove the second computation and share the results of this
	// computation.
	float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
	float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
	if( light_dist2_test < LIGHT_BOUNDING_RADIUS )
	{
        float3 fragment_to_light;
        float3 light_radiance;
        calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);
		
		// calculate diffuse cosine lobe (diffuse surface N dot L)
        float cosine_lobe = dot(surface_normal, fragment_to_light);
		
        diffusely_reflected_light += light_radiance * max(0.05f, cosine_lobe); // add light with cosine lobe (add ambient 5% light)
//		diffusely_reflected_light  += light_radiance * saturate(cosine_lobe);			// add light with cosine lobe (clamped positive)
		
		// step(0.0f, cosine_lobe)
        specularly_reflected_light += light_radiance * safe_pow(max(0.0f, dot(fragment_to_light, view_reflect_dir_world)), specular_power);
//		specularly_reflected_light += light_radiance * pow(saturate(dot(fragment_to_light, view_reflect_dir_world)), specular_power);
    }
	else
    {
		// debug: use a strong green tint to highlight area outside of the light's radius
		//diffusely_reflected_light += float3( 0, 1, 0 );
		//specularly_reflected_light += float3( 0, 1, 0 );
    }
}

void calc_simple_lights_analytical(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
		in float specular_power,
		out float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		out float3 specularly_reflected_light)						// specularly reflected light (not including specular surface color)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	specularly_reflected_light= float3(0.0f, 0.0f, 0.0f);

    if (SIMPLE_LIGHT_COUNT > 0)
    {
        simple_lights_analytical_single(0, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
        if (SIMPLE_LIGHT_COUNT > 1)
        {
            simple_lights_analytical_single(1, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
            if (SIMPLE_LIGHT_COUNT > 2)
            {
                simple_lights_analytical_single(2, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
                if (SIMPLE_LIGHT_COUNT > 3)
                {
                    simple_lights_analytical_single(3, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
                    if (SIMPLE_LIGHT_COUNT > 4)
                    {
                        simple_lights_analytical_single(4, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
                        if (SIMPLE_LIGHT_COUNT > 5)
                        {
                            simple_lights_analytical_single(5, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
                            if (SIMPLE_LIGHT_COUNT > 6)
                            {
                                simple_lights_analytical_single(6, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
								[flatten]
                                if (SIMPLE_LIGHT_COUNT > 7)
                                {
                                    simple_lights_analytical_single(7, fragment_position_world, surface_normal, view_reflect_dir_world, specular_power, diffusely_reflected_light, specularly_reflected_light);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
	
    specularly_reflected_light *= specular_power;
}

void calc_simple_lights_analytical_reach(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
		in float specular_power,
		out float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		out float3 specularly_reflected_light)						// specularly reflected light (not including specular surface color)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	specularly_reflected_light= float3(0.0f, 0.0f, 0.0f);
	
	// add in simple lights
#ifndef pc	
	[loop]
#endif
	for (int light_index= 0; light_index < SIMPLE_LIGHT_COUNT; light_index++)
	{
		// Compute distance squared to light, to see if we can skip this light.
		// Note: This is also computed in calculate_simple_light below, but the shader
		// compiler will remove the second computation and share the results of this
		// computation.
		float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
		float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
		if( light_dist2_test >= LIGHT_BOUNDING_RADIUS )
		{
			// debug: use a strong green tint to highlight area outside of the light's radius
			//diffusely_reflected_light += float3( 0, 1, 0 );
			//specularly_reflected_light += float3( 0, 1, 0 );
			continue;
		}
		
		float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);
		
		// calculate diffuse cosine lobe (diffuse surface N dot L)
		float cosine_lobe= dot(surface_normal, fragment_to_light) + 0.06f;  // + 0.05 so that the grenade on the ground can work well.
		
		diffusely_reflected_light  += light_radiance * saturate(cosine_lobe) / 3.14159265358979323846;			// add light with cosine lobe (clamped positive)
		
		// step(0.0f, cosine_lobe)
		//specularly_reflected_light += light_radiance * pow(max(0.0f, dot(fragment_to_light, view_reflect_dir_world)), specular_power);
		float specular_cosine_lobe= saturate(dot(fragment_to_light, view_reflect_dir_world));
		specularly_reflected_light += light_radiance * pow(specular_cosine_lobe, specular_power);
#ifdef pc
		if (light_index >= 7)		// god damn PC compiler likes to unroll these loops - only support 8 lights or so (:P)
		{
			light_index= 100;
		}
#endif // pc
	}
	specularly_reflected_light *= (1+specular_power);
}

void calc_simple_lights_ggx(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
        in float3 view_dir,
        in float3 f0,
		in float3 f1,
		in float fresnel_power,
		in float a,
        in float metallic,
        in float3 albedo,
		out float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		out float3 specularly_reflected_light)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	specularly_reflected_light= float3(0.0f, 0.0f, 0.0f);

#ifndef pc
	[loop]
#endif
	for (int light_index= 0; light_index < SIMPLE_LIGHT_COUNT; light_index++)
	{
		// Compute distance squared to light, to see if we can skip this light.
		// Note: This is also computed in calculate_simple_light below, but the shader
		// compiler will remove the second computation and share the results of this
		// computation.
		float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
		float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
		if( light_dist2_test >= LIGHT_BOUNDING_RADIUS )
		{
			// debug: use a strong green tint to highlight area outside of the light's radius
			//diffusely_reflected_light += float3( 0, 1, 0 );
			//specularly_reflected_light += float3( 0, 1, 0 );
			continue;
		}

		float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);

        float3 H    = normalize(fragment_to_light + view_dir);
        float NdotL = clamp(dot(surface_normal, fragment_to_light), 0.0001, 1);
        float NdotV = clamp(abs(dot(surface_normal, view_dir)), 0.0001, 1.0);
        float LdotH = clamp(dot(fragment_to_light, H), 0.0001, 1.0);
		float VdotH = clamp(dot(view_dir, H), 0.0001, 1.0);
		float VdotL = dot(view_dir, fragment_to_light);
        float NdotH = clamp(dot(surface_normal, H), 0.0001, 1.0);
        float a2_sqrd   = pow(a, 4);
    	float min_dot = min(NdotL, NdotV);
		float3 fresnel = f0 + (f1 - f0) * pow(1.0 - VdotH, fresnel_power);
		
        //Fresnel
        //Self explanitory.

        //Normal Distribution Function
        float NDFdenom = max((NdotH * a2_sqrd - NdotH) * NdotH + 1.0, 0.0001);
        float NDF = a2_sqrd / (PI * NDFdenom * NDFdenom);

        //Geometry
        float L = 2.0 * NdotL / (NdotL + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotL * NdotL)));
        float V = 2.0 * NdotV / (NdotV + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotV * NdotV)));
        float G = L * V;

        //Final GGX
        float3 numerator    = NDF * 
                              G * 
                        	  fresnel;
        float3 denominator  = max(4.0 * NdotV * NdotL, 0.0001);
        specularly_reflected_light += (numerator / denominator) * light_radiance * NdotL;//Light radiance was light irradiance, so keep an eye on that if there's issues.

		//specularly_reflected_light = 0.00001f;

        //Oren-Nayar
		//wfloat3 fresnel = 0.04 + (1 - 0.04) * pow(1.0 - HoV, 5.0);
		/*
		The github this function is pulled from (https://github.com/glslify/glsl-diffuse-oren-nayar) states that values for the float below above 0.96
		will not be energy conserving. This is because the output of this function is intended to be multiplied by albedo afterwards for the final diffuse.

		I may need to use this for more than just diffuse, so this will be left as 1.0 and we can multiply the function's output by the albedo map and
		then (1 - Fresnel) to maintain energy conservation.
		*/

		float albedo_standin = 0.96;

		float s = VdotL - NdotL * NdotV;
		float t = lerp(1.0, max(NdotL, NdotV), step(0.0, s));

		float sigma2 = (1 / sqrt(2)) * atan(a * a);
		float A = 1.0 + sigma2 * (albedo_standin / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
		float B = 0.45 * sigma2 / (sigma2 + 0.09);


		float3 ONdif = (albedo_standin * max(0.0, NdotL) * saturate(A + B * s / t) * light_radiance / PI);

		
		//Halo 3 diffuse
		//float cosine_lobe= dot(surface_normal, fragment_to_light);//Unclamped NdotL
		//diffusely_reflected_light  += light_radiance * max(0.05f, cosine_lobe);
		
		//Oren-Nayar diffuse
		diffusely_reflected_light	+= ONdif * (1 - metallic);
	}
}

void calc_simple_lights_uma(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
        in float3 view_dir,
		in float  spec_mask,
        in float3 albedo,
		out float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		out float3 specularly_reflected_light)
{
	

	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	specularly_reflected_light= float3(0.0f, 0.0f, 0.0f);

#ifndef pc
	[loop]
#endif
	for (int light_index= 0; light_index < SIMPLE_LIGHT_COUNT; light_index++)
	{
		// Compute distance squared to light, to see if we can skip this light.
		// Note: This is also computed in calculate_simple_light below, but the shader
		// compiler will remove the second computation and share the results of this
		// computation.
		float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
		float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
		if( light_dist2_test >= LIGHT_BOUNDING_RADIUS )
		{
			// debug: use a strong green tint to highlight area outside of the light's radius
			//diffusely_reflected_light += float3( 0, 1, 0 );
			//specularly_reflected_light += float3( 0, 1, 0 );
			continue;
		}

		float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);

        float NdotL = smoothstep(0.0, 0.03f, dot(surface_normal, fragment_to_light));
		float NdotV = dot(surface_normal, view_dir);

		specularly_reflected_light += saturate(spec_mask * 50 * (NdotV - 0.6)) * (albedo / PI) * NdotL * light_radiance;
		
		diffusely_reflected_light	+= NdotL * light_radiance * (albedo / PI);
	}
}

void calc_simple_lights_spec_gloss(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
        in float3 view_dir,
        in float3 f0,
		in float3 f1,
		in float fresnel_power,
		in float a,
        in float3 albedo,
		out float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		out float3 specularly_reflected_light)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	specularly_reflected_light= float3(0.0f, 0.0f, 0.0f);

#ifndef pc
	[loop]
#endif
	for (int light_index= 0; light_index < SIMPLE_LIGHT_COUNT; light_index++)
	{
		// Compute distance squared to light, to see if we can skip this light.
		// Note: This is also computed in calculate_simple_light below, but the shader
		// compiler will remove the second computation and share the results of this
		// computation.
		float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
		float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
		if( light_dist2_test >= LIGHT_BOUNDING_RADIUS )
		{
			// debug: use a strong green tint to highlight area outside of the light's radius
			//diffusely_reflected_light += float3( 0, 1, 0 );
			//specularly_reflected_light += float3( 0, 1, 0 );
			continue;
		}

		float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);

        float3 H    = normalize(fragment_to_light + view_dir);
        float NdotL = clamp(dot(surface_normal, fragment_to_light), 0.0001, 1);
        float NdotV = clamp(abs(dot(surface_normal, view_dir)), 0.0001, 1.0);
        float LdotH = clamp(dot(fragment_to_light, H), 0.0001, 1.0);
		float VdotH = clamp(dot(view_dir, H), 0.0001, 1.0);
		float VdotL = dot(view_dir, fragment_to_light);
        float NdotH = clamp(dot(surface_normal, H), 0.0001, 1.0);
        float a2_sqrd   = pow(a, 4);
    	float min_dot = min(NdotL, NdotV);
		float3 fresnel = f0 + (f1 - f0) * pow(1.0 - VdotH, fresnel_power);
		
        //Fresnel
        //Self explanitory.

        //Normal Distribution Function
        float NDFdenom = max((NdotH * a2_sqrd - NdotH) * NdotH + 1.0, 0.0001);
        float NDF = a2_sqrd / (PI * NDFdenom * NDFdenom);

        //Geometry
        float L = 2.0 * NdotL / (NdotL + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotL * NdotL)));
        float V = 2.0 * NdotV / (NdotV + sqrt(a2_sqrd + (1.0 - a2_sqrd) * (NdotV * NdotV)));
        float G = L * V;

        //Final GGX
        float3 numerator    = NDF * 
                              G * 
                        	  fresnel;
        float3 denominator  = max(4.0 * NdotV * NdotL, 0.0001);
        specularly_reflected_light += (numerator / denominator) * light_radiance * NdotL;//Light radiance was light irradiance, so keep an eye on that if there's issues.
		
		//Halo 3 diffuse
		float cosine_lobe= dot(surface_normal, fragment_to_light);//Unclamped NdotL
		diffusely_reflected_light += light_radiance * max(0.0001f, cosine_lobe);
	}
}

#else

void calc_simple_lights_analytical(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 view_reflect_dir_world,							// view direction = fragment to camera,   reflected around fragment normal
		in float specular_power,
		out float3 diffusely_reflected_light,						// diffusely reflected light (not including diffuse surface color)
		out float3 specularly_reflected_light)						// specularly reflected light (not including specular surface color)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	specularly_reflected_light= float3(0.0f, 0.0f, 0.0f);
	
	// add in simple lights
//#ifndef pc	
	[loop]
//#endif
	for (int light_index= 0; light_index < SIMPLE_LIGHT_COUNT; light_index++)
	{
		// Compute distance squared to light, to see if we can skip this light.
		// Note: This is also computed in calculate_simple_light below, but the shader
		// compiler will remove the second computation and share the results of this
		// computation.
		float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
		float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
		if( light_dist2_test >= LIGHT_BOUNDING_RADIUS )
		{
			// debug: use a strong green tint to highlight area outside of the light's radius
			//diffusely_reflected_light += float3( 0, 1, 0 );
			//specularly_reflected_light += float3( 0, 1, 0 );
			continue;
		}
		
		float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);
		
		// calculate diffuse cosine lobe (diffuse surface N dot L)
		float cosine_lobe= dot(surface_normal, fragment_to_light);
		
		diffusely_reflected_light  += light_radiance * max(0.05f, cosine_lobe);			// add light with cosine lobe (add ambient 5% light)
//		diffusely_reflected_light  += light_radiance * saturate(cosine_lobe);			// add light with cosine lobe (clamped positive)
		
		// step(0.0f, cosine_lobe)
		specularly_reflected_light += light_radiance * safe_pow(max(0.0f, dot(fragment_to_light, view_reflect_dir_world)), specular_power);
//		specularly_reflected_light += light_radiance * pow(saturate(dot(fragment_to_light, view_reflect_dir_world)), specular_power);
// #ifdef pc
// 		if (light_index >= 7)		// god damn PC compiler likes to unroll these loops - only support 8 lights or so (:P)
// 		{
// 			light_index= 100;
// 		}
// #endif // pc
	}
	specularly_reflected_light *= specular_power;
}
#endif // DX_VERSION == 9


float calc_diffuse_lobe(
	in float3 fragment_normal,
	in float3 fragment_to_light,
	in float3 translucency)
{
	// calculate diffuse cosine lobe (diffuse surface N dot L)
	float cosine_lobe= dot(fragment_normal, fragment_to_light);
	return saturate(cosine_lobe);
}


float calc_diffuse_translucent_lobe(
	in float3 fragment_normal,
	in float3 fragment_to_light,
	in float3 translucency)
{
	// calculate diffuse cosine lobe (diffuse surface N dot L)
	float cosine_lobe= dot(fragment_normal, fragment_to_light);
	float translucent_cosine_lobe= (cosine_lobe * translucency.x + translucency.y) * cosine_lobe + translucency.z;
	return translucent_cosine_lobe;
}

#if DX_VERSION == 9

void simple_lights_analytical_diffuse_translucent_single(
		in int light_index,
		in float3 fragment_position_world,
		in float3 surface_normal,
		inout float3 diffusely_reflected_light)						// diffusely reflected light (not including diffuse surface color)
{
	// Compute distance squared to light, to see if we can skip this light.
	// Note: This is also computed in calculate_simple_light below, but the shader
	// compiler will remove the second computation and share the results of this
	// computation.
	float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
	float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
	if( light_dist2_test < LIGHT_BOUNDING_RADIUS )
	{
        float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);
				
		diffusely_reflected_light  += light_radiance;
    }
	else
    {
		// debug: use a strong green tint to highlight area outside of the light's radius
		//diffusely_reflected_light += float3( 0, 1, 0 );
    }
}

void calc_simple_lights_analytical_diffuse_translucent(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 translucency,
		out float3 diffusely_reflected_light)						// specularly reflected light (not including specular surface color)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	
	// add in simple lights
	if (SIMPLE_LIGHT_COUNT > 0)
    {
        simple_lights_analytical_diffuse_translucent_single(0, fragment_position_world, surface_normal, diffusely_reflected_light);
        if (SIMPLE_LIGHT_COUNT > 1)
        {
            simple_lights_analytical_diffuse_translucent_single(1, fragment_position_world, surface_normal, diffusely_reflected_light);
            if (SIMPLE_LIGHT_COUNT > 2)
            {
                simple_lights_analytical_diffuse_translucent_single(2, fragment_position_world, surface_normal, diffusely_reflected_light);
                if (SIMPLE_LIGHT_COUNT > 3)
                {
                    simple_lights_analytical_diffuse_translucent_single(3, fragment_position_world, surface_normal, diffusely_reflected_light);
                    if (SIMPLE_LIGHT_COUNT > 4)
                    {
                        simple_lights_analytical_diffuse_translucent_single(4, fragment_position_world, surface_normal, diffusely_reflected_light);
                        if (SIMPLE_LIGHT_COUNT > 5)
                        {
                            simple_lights_analytical_diffuse_translucent_single(5, fragment_position_world, surface_normal, diffusely_reflected_light);
                            if (SIMPLE_LIGHT_COUNT > 6)
                            {
                                simple_lights_analytical_diffuse_translucent_single(6, fragment_position_world, surface_normal, diffusely_reflected_light);
								[flatten]
                                if (SIMPLE_LIGHT_COUNT > 7)
                                {
                                    simple_lights_analytical_diffuse_translucent_single(7, fragment_position_world, surface_normal, diffusely_reflected_light);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#else // DX_VERSION 11 || XENON

void calc_simple_lights_analytical_diffuse_translucent(
		in float3 fragment_position_world,
		in float3 surface_normal,
		in float3 translucency,
		out float3 diffusely_reflected_light)						// specularly reflected light (not including specular surface color)
{
	diffusely_reflected_light= float3(0.0f, 0.0f, 0.0f);
	
	// add in simple lights
//#ifndef pc	
	[loop]
//#endif
	for (int light_index= 0; light_index < SIMPLE_LIGHT_COUNT; light_index++)
	{
		// Compute distance squared to light, to see if we can skip this light.
		// Note: This is also computed in calculate_simple_light below, but the shader
		// compiler will remove the second computation and share the results of this
		// computation.
		float3 fragment_to_light_test= LIGHT_POSITION - fragment_position_world;				// vector from fragment to light
		float  light_dist2_test= dot(fragment_to_light_test, fragment_to_light_test);				// distance to the light, squared
		if( light_dist2_test >= LIGHT_BOUNDING_RADIUS )
		{
			// debug: use a strong green tint to highlight area outside of the light's radius
			//diffusely_reflected_light += float3( 0, 1, 0 );
			//specularly_reflected_light += float3( 0, 1, 0 );
			continue;
		}
		
		float3 fragment_to_light;
		float3 light_radiance;
		calculate_simple_light(
			light_index, fragment_position_world, light_radiance, fragment_to_light);
				
		diffusely_reflected_light  += light_radiance;// * calc_diffuse_translucent_lobe(surface_normal, fragment_to_light, translucency);
		
// #ifdef pc
// 		if (light_index >= 7)		// god damn PC compiler likes to unroll these loops - only support 8 lights or so (:P)
// 		{
// 			light_index= 100;
// 		}
// #endif // pc
	}
}
#endif // DX_VERSION == 9