// decorator shader is defined as 'world' vertex type, even though it really doesn't have a vertex type - it does its own custom vertex fetches
//@generate decorator

#define DECORATOR_DYNAMIC_LIGHTS
#define DECORATOR_SHADED_LIGHT

#include "decorators.hlsl"
