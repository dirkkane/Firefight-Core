
#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "postprocess.fx"
#include "hud_camera_nightvision_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(depth_sampler, 0);
LOCAL_SAMPLER_2D(color_sampler, 1);
LOCAL_SAMPLER_2D(mask_sampler, 2);
LOCAL_SAMPLER_2D(depth_through_walls_sampler, 3);

float4 default_ps(vertex_type IN) : SV_Target
{
    return float4(1, 0, 0, 0);
}