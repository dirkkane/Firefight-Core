// EDGE_AA Interpolators


struct EDGE_AA_VS_OUTPUT
{
   float2 uv : TEXCOORD0; // center
   float4 uv1: TEXCOORD1; // left, right
   float4 uv2: TEXCOORD2; // top,  bottom
   float4 uv3: TEXCOORD3; // left-top, right-bottom
   float4 uv4: TEXCOORD4; // left-bottom, right-top
};
