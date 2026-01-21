// decorator shader is defined as 'world' vertex type, even though it really doesn't have a vertex type - it does its own custom vertex fetches
//@generate decorator

#ifdef EXPLICIT_COMPILER
#define SSR_ENABLE
#endif

#define DECORATOR_EDIT

#include "decorators.hlsl"
