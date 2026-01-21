#ifndef _HLSL_CONSTANT_MAPPING_H_
#define _HLSL_CONSTANT_MAPPING_H_

// Shader constants which are off-limits (expected to persist throughout the frame)
#include "hlsl_constant_persist.h"

// Shader constants which are fair game (set prior to each draw call which uses them)
#include "hlsl_constant_oneshot.h"

#endif //_HLSL_CONSTANT_MAPPING_H_