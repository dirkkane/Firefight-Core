/*
FUNCTION_UTILITIES.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
3/29/2007 2:16:00 PM (davcook)
	
*/

#define _half_pi 1.57079632679f
#define _pi 3.14159265359f
#define _2pi 6.28318530718f

#define _epsilon 0.00001f
#define _1_minus_epsilon (1.0f - _epsilon)

#if DX_VERSION == 9
// Float has around 22 bits of accuracy.
#define power_2_0	1
#define power_2_1	(2 * power_2_0)
#define power_2_2	(2 * power_2_1)	
#define power_2_3	(2 * power_2_2)	
#define power_2_4	(2 * power_2_3)	
#define power_2_5	(2 * power_2_4)	
#define power_2_6	(2 * power_2_5)	
#define power_2_7	(2 * power_2_6)	
#define power_2_8	(2 * power_2_7)	
#define power_2_9	(2 * power_2_8)	
#define power_2_10	(2 * power_2_9)	
#define power_2_11	(2 * power_2_10)	
#define power_2_12	(2 * power_2_11)	
#define power_2_13	(2 * power_2_12)	
#define power_2_14	(2 * power_2_13)	
#define power_2_15	(2 * power_2_14)	
#define power_2_16	(2 * power_2_15)	
#define power_2_17	(2 * power_2_16)	
#define power_2_18	(2 * power_2_17)	
#define power_2_19	(2 * power_2_18)	
#define power_2_20	(2 * power_2_19)	
#define power_2_21	(2 * power_2_20)	
#define power_2_22	(2 * power_2_21)	

// Assumes "bit" "flags" is a float which is equal to a positive integer.
// Compiles to 5 instructions: mul, floors, mulsc, fracs, setp_ne
#define TEST_BIT(flags, bit) (frac(floor((flags)/power_2_##bit)/2))
#define TEST_BITF(flags, bit) (frac(floor((flags)/power_2_##bit)/2))

#define EXTRACT_BITS(bitfield, lo_bit, hi_bit) extract_bits(bitfield, power_2_##lo_bit, power_2_##hi_bit)
float extract_bits(float bitfield, int lo_power /*const power of 2*/, int hi_power /*const power of 2*/)
{
	float result= bitfield;	// calling this an 'int' adds an unnecessary 'truncs'
	if (lo_power!= power_2_0 /*2^0 compile time test*/)
	{
		// Should be 2 instructions: mad, floors
		result/= lo_power;
		result= floor(result);
	}
	if (hi_power!= power_2_22 /*2^22 compile time test*/)
	{
		// Should be 3 instructions: mulsc, frcs, mulsc
		result/= (hi_power/lo_power);
		result= frac(result);
		result*= (hi_power/lo_power);
	}
	return result;
}
#elif DX_VERSION == 11
#define TEST_BIT(flags, bit) ((uint(flags) & (1<<bit)) != 0)
#define EXTRACT_BITS(flags, lo_bit, hi_bit) float((uint(flags) >> lo_bit) & ((1 << (hi_bit - lo_bit))-1))
#endif
