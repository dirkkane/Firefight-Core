#ifndef __DOF_FILTER_FX
#define __DOF_FILTER_FX


float4 simple_DOF_filter(float2 vTexCoord, texture_sampler_2d original_sampler, bool original_gamma2, texture_sampler_2d blurry_sampler, texture_sampler_2d zbuffer_sampler)
{
	// Fetch high and low resolution taps
	float4 vTapLow=		sample2D( blurry_sampler,	vTexCoord - (pixel_size.zw - pixel_size.xy) * 0.0f);
	float4 vTapHigh=	sample2D( original_sampler, vTexCoord );
	//if (original_gamma2)
	//{
    //    vTapHigh.rgb = pow(sqrt(vTapHigh.rgb), gamma_power);
    //    vTapLow.rgb = pow(sqrt(vTapLow.rgb), gamma_power);
    //}

	// get pixel depth, and calculate blur amount
	float fCenterDepth = sample2D( zbuffer_sampler, vTexCoord ).r;
	//fCenterDepth= 1.0f / (DEPTH_BIAS + fCenterDepth * DEPTH_SCALE);					// convert to real depth
	float fTapBlur = min(max(abs(-FOCUS_DISTANCE + -fCenterDepth)-FOCUS_HALF_WIDTH, 0.0f)*APERTURE, MAX_BLUR_BLEND);

	// blend high and low res based on blur amount
	float4 vOutColor= lerp(vTapHigh, vTapLow, fTapBlur * fTapBlur);							// blurry samples use blurry buffer,  sharp samples use sharp buffer
        
    if (original_gamma2)
    {
#ifdef APPLY_FIXES
        vOutColor.rgb = pow(sqrt(vOutColor.rgb), gamma_power);
#endif
    }
    
    return vOutColor; 
}


/*
float4 poisson8_DOF_filter(float2 vTexCoord)
{
	static const int NUM_POISSON_TAPS = 8;
	static const float2 g_Poisson[8] = 
	{
	    float2( 0.000000f, 0.000000f ),
	    float2( 0.527837f,-0.085868f ),
	    float2(-0.040088f, 0.536087f ),
	    float2(-0.670445f,-0.179949f ),
	    float2(-0.419418f,-0.616039f ),
	    float2( 0.440453f,-0.639399f ),
	    float2(-0.757088f, 0.349334f ),
	    float2( 0.574619f, 0.685879f ),
	};

//	static const float2 g_vMaxCoC = float2( 5.0f, 10.0f );
//	static const float  g_fRadiusScale = 0.4f;

    // Fetch center tap
    float4 vOutColor = tex2D( surface_sampler, vTexCoord );

    // Save depth
    float fCenterDepth = tex2D( depth_sampler, vTexCoord ).r;
    fCenterDepth= 1.0f / (depth_constants.x + fCenterDepth * depth_constants.y);		// convert to real depth
//	return fCenterDepth * intensity.z;

	float relative_depth= max(abs(fCenterDepth - FOCUS_DISTANCE) - FOCUS_HALF_WIDTH, 0.0f);
	
    // Convert depth into blur radius in pixels
//    float fDiscRadius = abs( fCenterDepth * g_vMaxCoC.y - g_vMaxCoC.x );
	float fDiscRadius= min(abs(relative_depth * APERTURE * 5.0f), 5.0f);
//	return fDiscRadius * intensity.z;
    
    // Compute disc radius on low-res image
    float fDiscRadiusLow = fDiscRadius * 0.125f; // g_fRadiusScale;						// why does it pull the disc radius in for blurry samples??
    
    // Accumulate output color across all taps
    vOutColor = 0;
    
    for( int t=0; t<NUM_POISSON_TAPS; t++ )
    {
        // Fetch lo-res tap
        float2 vCoordLow = vTexCoord + (pixel_size.xy * g_Poisson[t] * fDiscRadiusLow );
        float4 vTapLow   = tex2D_offset( blur_sampler, vCoordLow, 0.5f, 0.5f );
        
        // Fetch hi-res tap
        float2 vCoordHigh = vTexCoord + (pixel_size.zw * g_Poisson[t] * fDiscRadius );
        float4 vTapHigh   = tex2D( surface_sampler, vCoordHigh );
        float vTapDepth	 = tex2D( depth_sampler, vCoordHigh ).r;
        vTapDepth= 1.0f / (depth_constants.x + vTapDepth * depth_constants.y);		// convert to real depth

        // Put tap bluriness into [0,1] range
        float fTapBlur = min(max(abs(vTapDepth-FOCUS_DISTANCE)-FOCUS_HALF_WIDTH, 0.0f)*APERTURE, MAX_BLUR_BLEND);
        
        // Mix lo-res and hi-res taps based on bluriness
//        float4 vTap = vTapHigh;
//		vTapHigh.rb= 0.0f;
//		vTapLow.g= 0.0f;
		float4 vTap= lerp( vTapHigh, vTapLow, fTapBlur * fTapBlur );				// blurry samples use blurry buffer,  sharp samples use sharp buffer
        
        // Apply leaking reduction: lower weight for taps that are closer than the
        // center tap and in focus
//        vTap.a = ( vTap.a >= fCenterDepth ) ? 1.0f : abs( vTap.a * 2.0f - 1.0f );
		float vTapWeight = (vTapDepth >= fCenterDepth ) ? 1.0f : fTapBlur;		// reduces weight of sharp samples in front of target pixel (so sharp samples don't blur into background)
        
        // Accumumate
        vOutColor.rgb += vTap.rgb * vTapWeight;
        vOutColor.a   += vTapWeight;
    }
    // Normalize and return result
    return ( vOutColor / vOutColor.a ); 
}
*/   


#endif