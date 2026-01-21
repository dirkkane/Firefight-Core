#ifndef __ATMOSPHERE_FX_H__
#define __ATMOSPHERE_FX_H__
#ifdef PC_CPU
#pragma once
#endif
/*
ATMOSPHERE.FX
Copyright (c) Microsoft Corporation, 2006. all rights reserved.
3/22/2006 4:32:45 PM (hao)
	atmosphere related hlsl
*/

#define SUN_DIR						v_atmosphere_constant_0.xyz
#define SUN_INTENSITY_OVER_TR_PLUS_TM	v_atmosphere_constant_1.xyz // SUN_INTENSITY_OVER_TR_PLUS_TM = SUN_INTENSITY / ( TOTAL_RAYLEIGH + TOTAL_MIE )
#define TOTAL_RAYLEIGH_LOG2E		v_atmosphere_constant_2.xyz  // TOTAL_RAYLEIGH_LOG2E = TOTAL_RAYLEIGH * log2(e)
#define TOTAL_MIE_LOG2E				v_atmosphere_constant_3.xyz  // TOTAL_MIE_LOG2E = TOTAL_MIE * log2(e)
#define RAYLEIGH_THETA_PREFIX		v_atmosphere_constant_4.xyz
#define MIE_THETA_PREFIX_HGC		v_atmosphere_constant_5.xyz  // MIE_THETA_PREFIX_HGC = MIE_THETA_PREFIX * (1- HEYEY_GREENSTEIN_CONSTANT * HEYEY_GREENSTEIN_CONSTANT)

#define DIST_BIAS					v_atmosphere_constant_0.w
#define ATMOSPHERE_ENABLE			v_atmosphere_constant_1.w
#define MAX_FOG_THICKNESS			v_atmosphere_constant_1.w // we're double-purposing this value
#define HEYEY_GREENSTEIN_CONSTANT_PLUS_ONE	v_atmosphere_constant_2.w
#define REFERENCE_DATUM_PLANE		v_atmosphere_constant_3.w
#define REFERENCE_MIE_HEIGHT_SCALE	v_atmosphere_constant_4.w
#define REFERENCE_RAY_HEIGHT_SCALE	v_atmosphere_constant_5.w
#define HEYEY_GREENSTEIN_CONSTANT_TIMES_TWO	v_atmosphere_constant_extra.x

#define k_log2_e	(log2(exp(1)))

void compute_scattering(
	in float3 view_point,
	in float3 world_scene_point,
	out float3 extinction,
	out float3 inscatter)
{
	if (ATMOSPHERE_ENABLE < 0.0f)
	{
		extinction= float3(1.0f, 1.0f, 1.0f);
		inscatter= 0.0f;
	}
	else
	{
		float3 view_vector= view_point-world_scene_point;
		float dist= sqrt(dot(view_vector, view_vector));
		view_vector/= dist;
		float c_theta= -dot(view_vector, SUN_DIR);
		//add bias
		dist= max(dist+DIST_BIAS, 0.0f);
		dist= min(dist, MAX_FOG_THICKNESS);
		
		//density at view point
		float view_height= max(view_point.z - REFERENCE_DATUM_PLANE, 0.0f);
		float scene_height= max(world_scene_point.z - REFERENCE_DATUM_PLANE, 0.0f);
		float diff= view_height - scene_height;
		
		// CTchou has identified all kinds of goodness here.
		// 1) use pow(heyey_term, 1.5) instead of the rsqrt followed by 2 muls
		// 2) avoid exp where possible and use exp2 and multiply the exponent by log-base-2(e). This may be a little tricky but can be done with good factoring
		//    of the uses of REFERENCE_MIE_HEIGHT_SCALE, REFERENCE_RAY_HEIGHT_SCALE, TOTAL_MIE, and TOTAL_RAYLEIGH
		// 3) in fact, get rid of TOTAL_RAYLEIGH & TOTAL_MIE and multiply them into the first step where dp & dm are computed.  Where they are needed later, 
		//    use a single const instead that also factors SUN_INTENSITY
		// 4) precompute various sums (1 + HEYEY_GREENSTEIN_CONSTANT), MIE_THETA_PREFIX * (1- HEYEY_GREENSTEIN_CONSTANT * HEYEY_GREENSTEIN_CONSTANT), etc.
		//  
		// I'm sure there's more we can find later too
		
		// mattlee notes:
		// 1. done.
		// 2. done.  note that applying 1/log2(e) to REFERENCE_MIE_HEIGHT_SCALE and REFERENCE_RAY_HEIGHT_SCALE makes no perf difference 
		//			 from applying log2(e) to view_height and scene_height.  It's a tradeoff between extra shader constants (valuable) 
		//			 and co-issued scalar ops (free).
		// 3. done.
		// 4. done.
		
		view_height*= k_log2_e;
		scene_height*= k_log2_e;
		
		if (diff * diff > 0.001f)
		{
			float dp= -(exp2(- view_height / REFERENCE_MIE_HEIGHT_SCALE) - exp2(- scene_height / REFERENCE_MIE_HEIGHT_SCALE)) * dist * REFERENCE_MIE_HEIGHT_SCALE / diff;
			float dm= -(exp2(- view_height / REFERENCE_RAY_HEIGHT_SCALE) - exp2(- scene_height / REFERENCE_RAY_HEIGHT_SCALE)) * dist * REFERENCE_RAY_HEIGHT_SCALE / diff;
			
			//total extinction
			extinction= exp2(-(TOTAL_RAYLEIGH_LOG2E * dm + TOTAL_MIE_LOG2E * dp));
		}
		else
		{
			float dp= exp2(- view_height / REFERENCE_MIE_HEIGHT_SCALE) * dist;
			float dm= exp2(- view_height / REFERENCE_RAY_HEIGHT_SCALE) * dist;
			
			//total extinction
			extinction= exp2(-(TOTAL_RAYLEIGH_LOG2E * dm + TOTAL_MIE_LOG2E * dp));
		}
		
		//rayleigh phase function
		float3 beta_m_theta= RAYLEIGH_THETA_PREFIX * (1.0f + c_theta * c_theta);
		
		//mie phase function
		float heyey_term= (HEYEY_GREENSTEIN_CONSTANT_PLUS_ONE - HEYEY_GREENSTEIN_CONSTANT_TIMES_TWO * c_theta);
		float heyey_term_one_pt_five = pow( heyey_term, -1.5f );
		float3 beta_p_theta= MIE_THETA_PREFIX_HGC * heyey_term_one_pt_five;

		//compute inscattering
		inscatter= SUN_INTENSITY_OVER_TR_PLUS_TM * (beta_m_theta + beta_p_theta) * (1.0f - extinction);
				
	}		
} 


#endif //__ATMOSPHERE_FX_H__
