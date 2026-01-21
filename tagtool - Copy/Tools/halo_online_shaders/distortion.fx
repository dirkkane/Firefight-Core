#include "texture_xform.fx"
#include "bump_mapping_util.fx"

#define DISTORT_TYPE(name) DISTORT_TYPE_##name
#define DISTORT_TYPE_distort_off_ps 0
#define DISTORT_TYPE_distort_on_ps 1

PARAM_SAMPLER_2D(distort_map);
PARAM(float4, distort_map_xform);
PARAM(float, distort_scale);

void distort_off_ps(in float2 texcoord, out float2 sfx_distort, out float2 distort_raw)
{
    distort_raw = 0;
    sfx_distort = 0;
}

void distort_on_ps(in float2 texcoord, out float2 sfx_distort, out float2 distort_raw)
{
    float2 distort = sample2D(distort_map, transform_texcoord(texcoord, distort_map_xform)).yw;
    distort_raw = BUMP_CONVERT(distort);
    sfx_distort = distort_raw * distort_scale;
}