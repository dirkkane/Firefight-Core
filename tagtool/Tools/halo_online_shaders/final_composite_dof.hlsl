#line 2 "source\rasterizer\hlsl\final_composite_DOF.hlsl"
//@generate screen


#if (! defined(pc)) || (DX_VERSION == 11) || (DX_VERSION == 9)
#define COMBINE_HDR_LDR combine_dof
float4 combine_dof(in float2 texcoord);
#endif // !pc


#include "final_composite_base.hlsl"


#if (! defined(pc)) || (DX_VERSION == 11) || (DX_VERSION == 9)


// depth of field
//#define DEPTH_BIAS			depth_constants.x
//#define DEPTH_SCALE			depth_constants.y
#define FOCUS_DISTANCE		depth_constants.z
#define APERTURE			depth_constants.w
#define FOCUS_HALF_WIDTH	depth_constants.x
#define MAX_BLUR_BLEND		depth_constants.y
#include "DOF_filter.fx"


float4 combine_dof(in float2 texcoord)
{
	return simple_DOF_filter(texcoord, surface_sampler, true, blur_sampler, depth_sampler);
}

#endif // !pc
