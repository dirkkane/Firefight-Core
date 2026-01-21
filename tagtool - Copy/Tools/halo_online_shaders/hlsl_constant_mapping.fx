#ifndef _HLSL_CONSTANT_MAPPING_FX_
#define _HLSL_CONSTANT_MAPPING_FX_

// Shader constants which are off-limits (expected to persist throughout the frame)
#include "hlsl_constant_persist.fx"

// Shader constants which are fair game (set prior to each draw call which uses them)
#include "hlsl_constant_oneshot.fx"

#define _NEW_LIGHTMAP_

#endif //ifndef _HLSL_CONSTANT_MAPPING_HLSL_
