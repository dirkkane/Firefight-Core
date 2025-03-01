#ifndef _GLOBAL_SYSTEMVALUE_FX_
#define _GLOBAL_SYSTEMVALUE_FX_

// Compatibility macros so that we can use D3D11 style systemvalues everywhere

#if DX_VERSION == 9

#define SV_Target COLOR
#define SV_Target0 COLOR0
#define SV_Target1 COLOR1
#define SV_Target2 COLOR2
#define SV_Target3 COLOR3
#define SV_Depth DEPTH
#define SV_Depth0 DEPTH0
#define SV_Position POSITION
#define SV_Position0 POSITION0
#define SV_VertexID INDEX
#define SCREEN_POSITION_INPUT(_name) float2 _name : VPOS

#elif DX_VERSION == 11

#define SCREEN_POSITION_INPUT(_name) float4 _name : SV_Position

#endif

#endif
