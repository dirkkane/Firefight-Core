
// Note: define 'DXT5_NORMALS' to enable DXT5NM bump mapping

#ifndef BUMP_CONVERT
#if defined(pc) && (DX_VERSION == 9)
    #ifdef DXT5_NORMALS
    #define BUMP_GET_CHANNELS(BM)  (BM.ag)
    #define BUMP_CONVERT(BM)  float2((BM).x * (255.0f / 127.0f) - (128.0f / 127.0f), (BM).y * (63.0f / 31.0f) - (32.0f / 31.0f))
    #else // DXN
    #define BUMP_GET_CHANNELS(BM)  (BM.rg)
    #define BUMP_CONVERT(BM)  ((BM) * (255.0f / 127.f) - (128.0f / 127.f))
    #endif
#else
#define BUMP_CONVERT(x)  (x)
#endif
#endif

#ifndef BUMPMAP_UTIL
#define BUMPMAP_UTIL

float bump_reconstruct_z(float2 bump)
{
    float2 bump2 = bump.xy * bump.xy;
    return sqrt(1 - min(bump2.x + bump2.y, 1.0f));
}

float3 bump_sample_unnormalized(in sampler2D tex, in float2 texcoord)
{
    float2 channels = BUMP_GET_CHANNELS(tex2D(tex, texcoord));
    float2 bump = BUMP_CONVERT(channels);
    return float3(bump.xy, bump_reconstruct_z(bump));
}

// this function replicates a h3 content bug. it is only used for certain decals
float3 sample_diffuse_as_bumpmap(in sampler2D tex, in float2 texcoord)
{
    float2 bump = tex2D(tex, texcoord).xy; // match xenon - no sign bias as the texture is a diffuse
    return normalize(float3(bump.xy, bump_reconstruct_z(bump)));
}
#endif
