
#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "utilities.fx"
#include "unknown_101_unknown_102_registers.fx"
//@generate screen

LOCAL_SAMPLER_2D(color_sampler, 0);
LOCAL_SAMPLER_2D(gbuf_sampler, 1);
LOCAL_SAMPLER_2D(depth_sampler, 2);

struct unknown_102_output
{
    float4 position : SV_POSITION;
    float2 unknown_0 : TEXCOORD0;
    float3 unknown_1 : TEXCOORD1;
};

unknown_102_output default_vs(vertex_type IN)
{
    unknown_102_output OUT;

    OUT.unknown_0 = IN.texcoord;

    float2 offset = (IN.texcoord - 0.5f) * vs_ref_reflections_cam_vec_0.xy;
    OUT.unknown_1.x = offset.x;
    OUT.unknown_1.y = -offset.y;
    OUT.unknown_1.z = 1.0f;

    OUT.position.xy = IN.position;
    OUT.position.z = 0.5f;
    OUT.position.w = 1.0f;

    return OUT;
}

float4 default_ps(vertex_type IN) : SV_Target
{
    return float4(1, 0, 0, 0);
}