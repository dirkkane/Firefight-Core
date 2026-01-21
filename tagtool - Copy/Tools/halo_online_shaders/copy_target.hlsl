#line 2 "source\rasterizer\hlsl\copy_target.hlsl"

//#define USE_CUSTOM_POSTPROCESS_CONSTANTS

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "copy_target_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(surface_sampler, 0);
LOCAL_SAMPLER_2D(dark_surface_sampler, 1);

LOCAL_SAMPLER_2D(bloom_sampler, 2);
#ifdef pc
LOCAL_SAMPLER_2D(bling_sampler, 3);
LOCAL_SAMPLER_2D(persist_sampler, 4);
#else
LOCAL_SAMPLER_2D(depth_sampler, 3);
LOCAL_SAMPLER_2D(blur_sampler, 4);
#endif

//sampler3D test_sampler : register(s5);			// ###ctchou $REMOVE $DEBUG


float3 get_pixel_bilinear_bloom(float2 tex_coord)
{
	return tex2D_offset(bloom_sampler, tex_coord, 0, 0);
}

#ifdef pc
float3 get_pixel_bilinear_bling(float2 tex_coord)
{
	return tex2D_offset(bling_sampler, tex_coord, 0, 0);
}

float3 get_pixel_bilinear_persist(float2 tex_coord)
{
	return tex2D_offset(persist_sampler, tex_coord, 0, 0);
}
#else
/*
PIXEL_CONSTANT(float4, depth_constants, c3);		// 1/near,  -(far-near)/(far*near), target_depth, depth_of_field

float4 poisson_DOF_filter(float2 vTexCoord)
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

	float target_depth= depth_constants.z;
	float relative_depth= (fCenterDepth - target_depth);
	
    // Convert depth into blur radius in pixels
//    float fDiscRadius = abs( fCenterDepth * g_vMaxCoC.y - g_vMaxCoC.x );
	float fDiscRadius= min(abs(relative_depth * depth_constants.w * 5.0f), 5.0f);
//	return fDiscRadius * intensity.z;
    
    // Compute disc radius on low-res image
    float fDiscRadiusLow = fDiscRadius * 0.125f; // g_fRadiusScale;						// why does it pull the disc radius in for blurry samples??
    
    // Accumulate output color across all taps
    vOutColor = 0;
    
    for( int t=0; t<NUM_POISSON_TAPS; t++ )
    {
        // Fetch lo-res tap
        float2 vCoordLow = vTexCoord + (pixel_size.xy * g_Poisson[t] * fDiscRadiusLow );
        float4 vTapLow   = tex2D( blur_sampler, vCoordLow );
        
        // Fetch hi-res tap
        float2 vCoordHigh = vTexCoord + (pixel_size.zw * g_Poisson[t] * fDiscRadius );
        float4 vTapHigh   = tex2D( surface_sampler, vCoordHigh );
        float vTapDepth	 = tex2D( depth_sampler, vCoordHigh ).r;
        vTapDepth= 1.0f / (depth_constants.x + vTapDepth * depth_constants.y);		// convert to real depth

        // Put tap bluriness into [0,1] range
        float fTapBlur = min(abs( (vTapDepth-target_depth) * depth_constants.w), 1.0f);
        
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
 
// pixel fragment entry points
float4 default_ps(screen_output IN) : SV_Target
{
#ifdef pc
	float4 accum=		sample2D(surface_sampler, IN.texcoord);
	float4 accum_dark=	sample2D(dark_surface_sampler, IN.texcoord);
	
	float3 combined= max(accum, accum_dark);			// convert_from_render_targets <-- for some reason this isn't optimized very well

	float3 bloom= get_pixel_bilinear_bloom(IN.texcoord);
	float3 bling= get_pixel_bilinear_bling(IN.texcoord);
	float3 persist= get_pixel_bilinear_persist(IN.texcoord);

	float3 blend=	intensity.x * combined +
					intensity.y * bloom +
					intensity.z * bling +
					intensity.w * persist;
#else // xenon
	float4 accum=		sample2D(surface_sampler, IN.texcoord);
	float4 accum_dark=	sample2D(dark_surface_sampler, IN.texcoord);
	float3 combined= max(accum, accum_dark);			// convert_from_render_targets <-- for some reason this isn't optimized very well

//	float4 combined= poisson_DOF_filter(IN.texcoord);
	
	float3 postprocess_result= tex2D_offset(bloom_sampler, IN.texcoord, 0, 0);

	float3 blend= combined * intensity.x + postprocess_result * intensity.y;
#endif

/*	sample0= sample0*2 - 1;
	sample0.y = sample0.y * (720.0/1280.0);
	sample0 *= sample0;
	
	float radius= sqrt(sample0.x + sample0.y);		// vignetting
	radius= max(0.0, radius-0.7);
	radius *= radius;
	radius = 1+15*radius;
	color= color / radius;
*/

// float d= 0.15
// float c= cuberoot(d * 27 / 4) = 1.0041494251232542828239889869599
// float xmax = sqrt(c / (3 * d)) = 1.4938015821857215695824940046795

	float3 clamped  = min(blend, tone_curve_constants.xxx);		// default= 1.4938015821857215695824940046795
	clamped= max(clamped, 0.000000001f);
	float3 clamped2 = clamped * clamped;
	float3 clamped3 = clamped2 * clamped;
	
	float4 result;
	result.rgb= clamped.rgb * tone_curve_constants.y + clamped2.rgb * tone_curve_constants.z + clamped3.rgb * tone_curve_constants.w;		// default linear = 1.0041494251232542828239889869599, quadratic= 0, cubic= - 0.15;
	result.a= 1.0f;

	return result;
}
