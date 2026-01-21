// Copyright (c) 2010 NVIDIA Corporation. All rights reserved.
//
// TO  THE MAXIMUM  EXTENT PERMITTED  BY APPLICABLE  LAW, THIS SOFTWARE  IS PROVIDED
// *AS IS*  AND NVIDIA AND  ITS SUPPLIERS DISCLAIM  ALL WARRANTIES,  EITHER  EXPRESS
// OR IMPLIED, INCLUDING, BUT NOT LIMITED  TO, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL  NVIDIA OR ITS SUPPLIERS
// BE  LIABLE  FOR  ANY  SPECIAL,  INCIDENTAL,  INDIRECT,  OR  CONSEQUENTIAL DAMAGES
// WHATSOEVER (INCLUDING, WITHOUT LIMITATION,  DAMAGES FOR LOSS OF BUSINESS PROFITS,
// BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS)
// ARISING OUT OF THE  USE OF OR INABILITY  TO USE THIS SOFTWARE, EVEN IF NVIDIA HAS
// BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

//
// Limited & optimized for X360 GPU version.
//
// Optimizations:
// - use interpolators for offset lookups (save some MADs)
// - more straightforward early out condition (to be always compiled to jmp for Xenos)
// - some hand made vectorization (luma, gradient etc.)
// - search loop rewritten: 
//    - texfetches grouped in separate loop (to avoid deadly tfetch, serialize, tfetch pattern)
//    - misc ALU optimization: some math vectorized, loop logic inverted, no conditional breaks
//
// Limitations:
// - some optimizations rely on fact that FXAA_PRESET == 1 is always used
//   (number of search steps restricted to 4). So, this code will not work
//   with any other presets!
// - no gradient lookups, so no optimization from anisotropic lookups (todo with asm)
// 
// Other changes: 
// - debug code commented out
// - huge comments stripped
//
// See edge_aa_fxaa_orig.fx for original reference.
//
// ---
//
// Estimated timings for both codepaths (X360 FXC ver 2.0.8276.0) :
//
// Original code (preset == 1) :
//
// Shader Timing Estimate, in Cycles/64 pixel vector:
// ALU: 136.00-237.33 (102-178 instructions), vertex: 0, texture: 116-136,
//   sequencer: 100, interpolator: 20;    14 GPRs, 12 threads,
// Performance (if enough threads): ~136-237 cycles per vector
//
//
// Optimized code (preset == 1) :
//
// Shader Timing Estimate, in Cycles/64 pixel vector:
// ALU: 26.67-149.33 (20-112 instructions), vertex: 0, texture: 20-72,
//   sequencer: 52, interpolator: 20;    14 GPRs, 12 threads,
// Performance (if enough threads): ~52-149 cycles per vector
// 
// Real test timings:
// DepthAA   1.178ms (tfetch bound)
// FXAA opt  2.544ms (tfetch bound), 1.902ms (ALU/tfetch bound, no aniso)
// FXAA orig 3.492ms (tfetch/ALU bound)
// ---
//
// DS, 15/02/2011
//
/*============================================================================
 
                                    FXAA                                 
 
============================================================================*/
 
#ifndef     FXAA_HLSL_3
    #define FXAA_HLSL_3 1
#endif
/*--------------------------------------------------------------------------*/
#if FXAA_HLSL_3
    #define int2 float2
    #define FxaaInt2 float2
    #define FxaaFloat2 float2
    #define FxaaFloat3 float3
    #define FxaaFloat4 float4
    #define FxaaBool2Float(a) (a)
    #define FxaaPow3(x, y) pow(x, y)
    #define FxaaSel3(f, t, b) ((f)*(!b) + (t)*(b))
    #define FxaaTex sampler2D
#endif
/*--------------------------------------------------------------------------*/
#if FXAA_HLSL_4
    #define FxaaInt2 int2
    #define FxaaFloat2 float2
    #define FxaaFloat3 float3
    #define FxaaFloat4 float4
    #define FxaaBool2Float(a) (a)
    #define FxaaPow3(x, y) pow(x, y)
    #define FxaaSel3(f, t, b) ((f)*(!b) + (t)*(b))
    struct FxaaTex { SamplerState smpl; Texture2D tex; };
#endif
/*--------------------------------------------------------------------------*/
#define FxaaToFloat3(a) FxaaFloat3((a), (a), (a))
/*--------------------------------------------------------------------------*/
float4 FxaaTexLod0(FxaaTex tex, float2 pos) {
    #if FXAA_HLSL_3
        return tex2Dlod(tex, float4(pos.xy, 0.0, 0.0)); 
    #endif
    #if FXAA_HLSL_4
        return tex.tex.SampleLevel(tex.smpl, pos.xy, 0.0);
    #endif
}
/*--------------------------------------------------------------------------*/
float4 FxaaTexGrad(FxaaTex tex, float2 pos, float2 grad) {
    #if FXAA_HLSL_3
        return tex2Dgrad(tex, pos.xy, grad, grad); 
    #endif
    #if FXAA_HLSL_4
        return tex.tex.SampleGrad(tex.smpl, pos.xy, grad, grad);
    #endif
}
/*--------------------------------------------------------------------------*/
float4 FxaaTexOff(FxaaTex tex, float2 pos, int2 off, float2 rcpFrame) {
    #if FXAA_HLSL_3
        return tex2Dlod(tex, float4(pos.xy + (off * rcpFrame), 0, 0)); 
    #endif
    #if FXAA_HLSL_4
        return tex.tex.SampleLevel(tex.smpl, pos.xy, 0.0, off.xy);
    #endif
}


/*============================================================================
                                DEBUG KNOBS
------------------------------------------------------------------------------
All debug knobs draw FXAA-untouched pixels in FXAA computed luma (monochrome).
 
FXAA_DEBUG_PASSTHROUGH - Red for pixels which are filtered by FXAA with a
                         yellow tint on sub-pixel aliasing filtered by FXAA.
FXAA_DEBUG_HORZVERT    - Blue for horizontal edges, gold for vertical edges. 
FXAA_DEBUG_PAIR        - Blue/green for the 2 pixel pair choice. 
FXAA_DEBUG_NEGPOS      - Red/blue for which side of center of span.
FXAA_DEBUG_OFFSET      - Red/blue for -/+ x, gold/skyblue for -/+ y.
============================================================================*/
#ifndef     FXAA_DEBUG_PASSTHROUGH
    #define FXAA_DEBUG_PASSTHROUGH 0
#endif    
#ifndef     FXAA_DEBUG_HORZVERT
    #define FXAA_DEBUG_HORZVERT    0
#endif    
#ifndef     FXAA_DEBUG_PAIR   
    #define FXAA_DEBUG_PAIR        0
#endif    
#ifndef     FXAA_DEBUG_NEGPOS
    #define FXAA_DEBUG_NEGPOS      0
#endif
#ifndef     FXAA_DEBUG_OFFSET
    #define FXAA_DEBUG_OFFSET      0
#endif    
/*--------------------------------------------------------------------------*/
#if FXAA_DEBUG_PASSTHROUGH || FXAA_DEBUG_HORZVERT || FXAA_DEBUG_PAIR
    #define FXAA_DEBUG 1
#endif    
#if FXAA_DEBUG_NEGPOS || FXAA_DEBUG_OFFSET
    #define FXAA_DEBUG 1
#endif
#ifndef FXAA_DEBUG
    #define FXAA_DEBUG 0
#endif
  
/*============================================================================
                              COMPILE-IN KNOBS
------------------------------------------------------------------------------
FXAA_PRESET - Choose compile-in knob preset 0-5.
------------------------------------------------------------------------------
FXAA_EDGE_THRESHOLD - The minimum amount of local contrast required 
                      to apply algorithm.
                      1.0/3.0  - too little
                      1.0/4.0  - good start
                      1.0/8.0  - applies to more edges
                      1.0/16.0 - overkill
------------------------------------------------------------------------------
FXAA_EDGE_THRESHOLD_MIN - Trims the algorithm from processing darks.
                          Perf optimization.
                          1.0/32.0 - visible limit (smaller isn't visible)
                          1.0/16.0 - good compromise
                          1.0/12.0 - upper limit (seeing artifacts)
------------------------------------------------------------------------------
FXAA_SEARCH_STEPS - Maximum number of search steps for end of span.
------------------------------------------------------------------------------
FXAA_SEARCH_ACCELERATION - How much to accelerate search,
                           1 - no acceleration
                           2 - skip by 2 pixels
                           3 - skip by 3 pixels
                           4 - skip by 4 pixels
------------------------------------------------------------------------------
FXAA_SEARCH_THRESHOLD - Controls when to stop searching.
                        1.0/4.0 - seems to be the best quality wise
------------------------------------------------------------------------------
FXAA_SUBPIX_FASTER - Turn on lower quality but faster subpix path.
                     Not recomended, but used in preset 0.
------------------------------------------------------------------------------
FXAA_SUBPIX - Toggle subpix filtering.
              0 - turn off
              1 - turn on
              2 - turn on full (ignores FXAA_SUBPIX_TRIM and CAP)
------------------------------------------------------------------------------
FXAA_SUBPIX_TRIM - Controls sub-pixel aliasing removal.
                   1.0/2.0 - low removal
                   1.0/3.0 - medium removal
                   1.0/4.0 - default removal
                   1.0/8.0 - high removal
                   0.0 - complete removal
------------------------------------------------------------------------------
FXAA_SUBPIX_CAP - Insures fine detail is not completely removed.
                  This is important for the transition of sub-pixel detail,
                  like fences and wires.
                  3.0/4.0 - default (medium amount of filtering)
                  7.0/8.0 - high amount of filtering
                  1.0 - no capping of sub-pixel aliasing removal
============================================================================*/
#ifndef FXAA_PRESET
    #define FXAA_PRESET 1
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_PRESET == 0)
    #define FXAA_EDGE_THRESHOLD      (1.0/4.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/12.0)
    #define FXAA_SEARCH_STEPS        2
    #define FXAA_SEARCH_ACCELERATION 4
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX              1
    #define FXAA_SUBPIX_FASTER       1
    #define FXAA_SUBPIX_CAP          (2.0/3.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_PRESET == 1)
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/16.0)
    #define FXAA_SEARCH_STEPS        4
    #define FXAA_SEARCH_ACCELERATION 3
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX              1
    #define FXAA_SUBPIX_FASTER       0
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_PRESET == 2)
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/24.0)
    #define FXAA_SEARCH_STEPS        8
    #define FXAA_SEARCH_ACCELERATION 2
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX              1
    #define FXAA_SUBPIX_FASTER       0
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_PRESET == 3)
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/24.0)
    #define FXAA_SEARCH_STEPS        16
    #define FXAA_SEARCH_ACCELERATION 1
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX              1
    #define FXAA_SUBPIX_FASTER       0
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_PRESET == 4)
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/24.0)
    #define FXAA_SEARCH_STEPS        24
    #define FXAA_SEARCH_ACCELERATION 1
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX              1
    #define FXAA_SUBPIX_FASTER       0
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_PRESET == 5)
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/24.0)
    #define FXAA_SEARCH_STEPS        32
    #define FXAA_SEARCH_ACCELERATION 1
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX              1
    #define FXAA_SUBPIX_FASTER       0
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
/*--------------------------------------------------------------------------*/
#define FXAA_SUBPIX_TRIM_SCALE (1.0/(1.0 - FXAA_SUBPIX_TRIM))

/*============================================================================
                                   HELPERS
============================================================================*/
// Return the luma, the estimation of luminance from rgb inputs.
// This approximates luma using one FMA instruction,
// skipping normalization and tossing out blue.
// FxaaLuma() will range 0.0 to 2.963210702.
float FxaaLuma(float3 rgb) { return rgb.y * (0.587/0.299) + rgb.x; } 
/*--------------------------------------------------------------------------*/
float3 FxaaLerp3(float3 a, float3 b, float amountOfA) 
{
   return lerp(b, a, amountOfA);
   //return (FxaaToFloat3(-amountOfA) * b) + ((a * FxaaToFloat3(amountOfA)) + b); 
}
/*--------------------------------------------------------------------------*/
// Support any extra filtering before returning color.
float4 FxaaFilterReturn(float3 rgb, float alpha) {
    return float4(rgb.xyz, alpha);
}

float4 FxaaFilterReturn(float3 rgb) 
{
    return float4(rgb.xyz, 0);
}
 
 
 
 
/*============================================================================
 
                                PIXEL SHADER
                                
============================================================================*/
float4 FxaaPixelShader( sampler2D tex, EDGE_AA_VS_OUTPUT input  ) 
{
   float2 C = input.uv.xy; 
   float2 L = input.uv1.xy;
   float2 R = input.uv1.zw;
   float2 T = input.uv2.xy;
   float2 B = input.uv2.zw;
   float2 LT  = input.uv3.xy;
   float2 RB  = input.uv3.zw;
   float2 LB  = input.uv4.xy;
   float2 RT  = input.uv4.zw;
   
   float3 rgbN = FxaaTexLod0(tex, T).xyz;
   float3 rgbW = FxaaTexLod0(tex, L).xyz;
   float4 ccc  = FxaaTexLod0(tex, C);
   float3 rgbM = ccc.xyz;
   float3 rgbE = FxaaTexLod0(tex, R).xyz;
   float3 rgbS = FxaaTexLod0(tex, B).xyz;

   float2 pos = C;
   float2 rcpFrame = float2(SCREEN_WIDTH_RCP, SCREEN_HEIGHT_RCP);
   
// ----------------------------------------------------------------------------
//            EARLY EXIT IF LOCAL CONTRAST BELOW EDGE DETECT LIMIT
// ----------------------------------------------------------------------------
   float4 luma1 = float4( FxaaLuma(rgbN), FxaaLuma(rgbW), FxaaLuma(rgbE), FxaaLuma(rgbS) );   // N, W, E, S
   //    float lumaN = FxaaLuma(rgbN);
   //    float lumaW = FxaaLuma(rgbW);
   //    float lumaE = FxaaLuma(rgbE);
   //    float lumaS = FxaaLuma(rgbS);
   float lumaM = FxaaLuma(rgbM);
   float rangeMin = min(lumaM, min(min(luma1.x, luma1.y), min(luma1.w, luma1.z)));
   float rangeMax = max(lumaM, max(max(luma1.x, luma1.y), max(luma1.w, luma1.z)));
   float range = rangeMax - rangeMin;
//    #if FXAA_DEBUG
//        float lumaO = lumaM / (1.0 + (0.587/0.299));
//    #endif        

    // EARLY OUT
//   HLSL_ATTRIB_BRANCH
   if(range >= max(FXAA_EDGE_THRESHOLD_MIN, rangeMax * FXAA_EDGE_THRESHOLD)) {   
//        #if FXAA_DEBUG
//            return FxaaFilterReturn(FxaaToFloat3(lumaO));
//        #endif
    #if FXAA_SUBPIX > 0
        #if FXAA_SUBPIX_FASTER
            float3 rgbL = (rgbN + rgbW + rgbE + rgbS + rgbM) * FxaaToFloat3(1.0/5.0);
        #else
            float3 rgbL = rgbN + rgbW + rgbM + rgbE + rgbS;
        #endif
    #endif        
    
///*----------------------------------------------------------------------------
//                               COMPUTE LOWPASS
//------------------------------------------------------------------------------
// FXAA computes a local neighborhood lowpass value as follows,
// 
//  (N + W + E + S)/4
//  
// Then uses the ratio of the contrast range of the lowpass 
// and the range found in the early exit check, 
// as a sub-pixel aliasing detection filter. 
// When FXAA detects sub-pixel aliasing (such as single pixel dots), 
// it later blends in "blendL" amount 
// of a lowpass value (computed in the next section) to the final result.
//----------------------------------------------------------------------------*/
    #if FXAA_SUBPIX != 0
//        float lumaL = (lumaN + lumaW + lumaE + lumaS) * 0.25;
        float lumaL = dot( luma1, float4(.25f, .25f, .25f, .25f) );
        float rangeL = abs(lumaL - lumaM);
    #endif        
    #if FXAA_SUBPIX == 1
        float blendL = max(0.0, (rangeL / range) - FXAA_SUBPIX_TRIM) * FXAA_SUBPIX_TRIM_SCALE; 
        blendL = min(FXAA_SUBPIX_CAP, blendL);
    #endif
    #if FXAA_SUBPIX == 2
        float blendL = rangeL / range; 
    #endif
//    #if FXAA_DEBUG_PASSTHROUGH
//        #if FXAA_SUBPIX == 0
//            float blendL = 0.0;
//        #endif
//        return FxaaFilterReturn(
//            FxaaFloat3(1.0, blendL/FXAA_SUBPIX_CAP, 0.0));
//    #endif    
    
// ----------------------------------------------------------------------------
//                    CHOOSE VERTICAL OR HORIZONTAL SEARCH
// ----------------------------------------------------------------------------
   float3 rgbNW = FxaaTexLod0(tex, LT).xyz;
   float3 rgbNE = FxaaTexLod0(tex, RT).xyz;
   float3 rgbSW = FxaaTexLod0(tex, LB).xyz;
   float3 rgbSE = FxaaTexLod0(tex, RB).xyz;
    #if (FXAA_SUBPIX_FASTER == 0) && (FXAA_SUBPIX > 0)
        rgbL += (rgbNW + rgbNE + rgbSW + rgbSE);
        rgbL *= FxaaToFloat3(1.0/9.0);
    #endif
    float lumaNW = FxaaLuma(rgbNW);
    float lumaNE = FxaaLuma(rgbNE);
    float lumaSW = FxaaLuma(rgbSW);
    float lumaSE = FxaaLuma(rgbSE);
    float edgeVert = 
        abs((0.25 * lumaNW) + (-0.5 * luma1.x) + (0.25 * lumaNE)) +
        abs((0.50 * luma1.y ) + (-1.0 * lumaM) + (0.50 * luma1.z )) +
        abs((0.25 * lumaSW) + (-0.5 * luma1.w) + (0.25 * lumaSE));
    float edgeHorz = 
        abs((0.25 * lumaNW) + (-0.5 * luma1.y) + (0.25 * lumaSW)) +
        abs((0.50 * luma1.x ) + (-1.0 * lumaM) + (0.50 * luma1.w )) +
        abs((0.25 * lumaNE) + (-0.5 * luma1.z) + (0.25 * lumaSE));
    
    float horzSpan = (edgeHorz >= edgeVert) ? 1 : 0;
//    #if FXAA_DEBUG_HORZVERT
//        if(horzSpan) return FxaaFilterReturn(FxaaFloat3(1.0, 0.75, 0.0));
//        else         return FxaaFilterReturn(FxaaFloat3(0.0, 0.50, 1.0));
//    #endif
   float lengthSign = (horzSpan > 0) ? -rcpFrame.y : -rcpFrame.x;
   luma1.xw = (horzSpan > 0) ? luma1.xw : luma1.yz;
   
   float2 gradient = abs(luma1.xw - float2(lumaM, lumaM)); // gradientN, gradientS
//   float gradientN = abs(luma1.x - lumaM);
//   float gradientS = abs(luma1.w - lumaM);
//   luma1.x = (luma1.x + lumaM) * 0.5;
//   luma1.w = (luma1.w + lumaM) * 0.5;
   luma1.xw = (luma1.xw + float2(lumaM, lumaM)) * 0.5f;
    
///*----------------------------------------------------------------------------
//                CHOOSE SIDE OF PIXEL WHERE GRADIENT IS HIGHEST
//------------------------------------------------------------------------------
   float pairN = gradient.x >= gradient.y ? 1 : 0;
//    #if FXAA_DEBUG_PAIR
//        if(pairN) return FxaaFilterReturn(FxaaFloat3(0.0, 0.0, 1.0));
//        else      return FxaaFilterReturn(FxaaFloat3(0.0, 1.0, 0.0));
//    #endif
   luma1.x    = (pairN == 0) ? luma1.w : luma1.x;
   gradient.x = (pairN == 0) ? gradient.y : gradient.x;
   lengthSign = (pairN == 0) ? -lengthSign : lengthSign;
   
   float2 posN;
   posN.x = pos.x + (horzSpan > 0 ? 0.0 : lengthSign * 0.5);
   posN.y = pos.y + (horzSpan > 0 ? lengthSign * 0.5 : 0.0);
    
///*----------------------------------------------------------------------------
//                         CHOOSE SEARCH LIMITING VALUES
//------------------------------------------------------------------------------
// Search limit (+/- gradientN) is a function of local gradient.
//----------------------------------------------------------------------------*/
    gradient.x *= FXAA_SEARCH_THRESHOLD;
    
///*----------------------------------------------------------------------------
//    SEARCH IN BOTH DIRECTIONS UNTIL FIND LUMA PAIR AVERAGE IS OUT OF RANGE
//------------------------------------------------------------------------------
// This loop searches either in vertical or horizontal directions,
// and in both the negative and positive direction in parallel.
// This loop fusion is faster than searching separately.
// 
// The search is accelerated using FXAA_SEARCH_ACCELERATION length box filter
// via anisotropic filtering with specified texture gradients.
//----------------------------------------------------------------------------*/
    float2 posP = posN;
    float2 offNP = (horzSpan > 0) ?
        FxaaFloat2(rcpFrame.x, 0.0) :
        FxaaFloat2(0.0f, rcpFrame.y); 
    float lumaEndN = luma1.x;
    float lumaEndP = luma1.x;
    #if FXAA_SEARCH_ACCELERATION == 1
        posN += offNP * FxaaFloat2(-1.0, -1.0);
        posP += offNP * FxaaFloat2( 1.0,  1.0);
    #endif
    #if FXAA_SEARCH_ACCELERATION == 2
        posN += offNP * FxaaFloat2(-1.5, -1.5);
        posP += offNP * FxaaFloat2( 1.5,  1.5);
        offNP *= FxaaFloat2(2.0, 2.0);
    #endif
    #if FXAA_SEARCH_ACCELERATION == 3
        posN += offNP * FxaaFloat2(-2.0, -2.0);
        posP += offNP * FxaaFloat2( 2.0,  2.0);
        offNP *= FxaaFloat2(3.0, 3.0);
    #endif
    #if FXAA_SEARCH_ACCELERATION == 4
        posN += offNP * FxaaFloat2(-2.5, -2.5);
        posP += offNP * FxaaFloat2( 2.5,  2.5);
        offNP *= FxaaFloat2(4.0, 4.0);  
    #endif

    float4 lumaEndN_buf;
    float4 lumaEndP_buf;
    HLSL_ATTRIB_ISOLATE
    {
      float3 uvN[FXAA_SEARCH_STEPS];
      float3 uvP[FXAA_SEARCH_STEPS];
      HLSL_ATTRIB_UNROLL 
      for(int i = 0; i < FXAA_SEARCH_STEPS; i++) {
         uvN[i].xy = posN.xy - offNP * i;
         uvP[i].xy = posP.xy + offNP * i;
      }
      HLSL_ATTRIB_UNROLL 
      for(int i = 0; i < FXAA_SEARCH_STEPS; i++) {
         uvN[i].xyz = tex2D(tex, uvN[i].xy).xyz;//, offNP).xyz;
         uvP[i].xyz = tex2D(tex, uvP[i].xy).xyz;//, offNP).xyz;
      }
      HLSL_ATTRIB_UNROLL 
      for(int i = 0; i < FXAA_SEARCH_STEPS; i++) {
         lumaEndN_buf[i] = FxaaLuma(uvN[i].xyz);
         lumaEndP_buf[i] = FxaaLuma(uvP[i].xyz);
      }
    }
    
    // --- original loop --- 
    posP += offNP * 3;
    posN -= offNP * 3;
    
    float3 crN = (abs(lumaEndN_buf.xyz - luma1.xxx) >= gradient.xxx) ? 1 : 0;
    float3 crP = (abs(lumaEndP_buf.xyz - luma1.xxx) >= gradient.xxx) ? 1 : 0;

    lumaEndN = lumaEndN_buf[0];
    lumaEndP = lumaEndP_buf[0]; 

    HLSL_ATTRIB_UNROLL 
    for(int i = FXAA_SEARCH_STEPS - 1; i >= 1; i--) {
//       if(crP[i-1] > 0) {
//      posP -= offNP;
//      lumaEndP = lumaEndP_buf[i];
//       }
//       if(crN[i-1] > 0) {
//      posN += offNP;
//      lumaEndN = lumaEndN_buf[i];
//       }
      posP -= offNP * crP[i-1];
      lumaEndP = (crP[i-1] > 0) ? lumaEndP_buf[i] : lumaEndP;
      posN += offNP * crN[i-1];
      lumaEndN = (crN[i-1] > 0) ? lumaEndN_buf[i] : lumaEndN;
    }
    
//    float doneN = 0;
//    float doneP = 0;
//    HLSL_ATTRIB_UNROLL
//    for(int i = 1; i < FXAA_SEARCH_STEPS; i++) {
//      //        #if FXAA_SEARCH_ACCELERATION == 1
//      //            if(doneN == 0) lumaEndN = 
//      //                FxaaLuma(FxaaTexLod0(tex, posN.xy).xyz);
//      //            if(doneP == 0) lumaEndP = 
//      //                FxaaLuma(FxaaTexLod0(tex, posP.xy).xyz);
//      //        #else
//      //            if(doneN == 0) lumaEndN = 
//      //                FxaaLuma(FxaaTexGrad(tex, posN.xy, offNP).xyz);
//      //            if(doneP == 0) lumaEndP = 
//      //                FxaaLuma(FxaaTexGrad(tex, posP.xy, offNP).xyz);
//      //        #endif
//      doneN += (abs(lumaEndN - lumaN) >= gradientN) ? 1 : 0;
//      doneP += (abs(lumaEndP - lumaN) >= gradientN) ? 1 : 0;
//      if(doneN * doneP > 0) break;
//      if(doneP == 0) { 
//         posP += offNP;
//         lumaEndP = lumaEndP_buf[i];
//      }
//      if(doneN == 0) {
//         posN -= offNP;
//         lumaEndN = lumaEndN_buf[i];
//      }
//    }
     
// ----------------------------------------------------------------------------
//               HANDLE IF CENTER IS ON POSITIVE OR NEGATIVE SIDE 
// ----------------------------------------------------------------------------
    float dstN = horzSpan ? pos.x - posN.x : pos.y - posN.y;
    float dstP = horzSpan ? posP.x - pos.x : posP.y - pos.y;
    bool directionN = dstN < dstP;
//    #if FXAA_DEBUG_NEGPOS
//        if(directionN) return FxaaFilterReturn(FxaaFloat3(1.0, 0.0, 0.0));
//        else           return FxaaFilterReturn(FxaaFloat3(0.0, 0.0, 1.0));
//    #endif
    lumaEndN = directionN ? lumaEndN : lumaEndP;
    
// ----------------------------------------------------------------------------
//         CHECK IF PIXEL IS IN SECTION OF SPAN WHICH GETS NO FILTERING
// ----------------------------------------------------------------------------
    if(((lumaM - luma1.x) < 0.0) == ((lumaEndN - luma1.x) < 0.0)) 
        lengthSign = 0.0;
 
// ----------------------------------------------------------------------------
//                COMPUTE SUB-PIXEL OFFSET AND FILTER SPAN
// ----------------------------------------------------------------------------

float spanLength = (dstP + dstN);
    dstN = directionN ? dstN : dstP;
    float subPixelOffset = (0.5 + (dstN * (-1.0/spanLength))) * lengthSign;
//    #if FXAA_DEBUG_OFFSET
//        float ox = horzSpan ? 0.0 : subPixelOffset*2.0/rcpFrame.x;
//        float oy = horzSpan ? subPixelOffset*2.0/rcpFrame.y : 0.0;
//        if(ox < 0.0) return FxaaFilterReturn(
//            FxaaLerp3(FxaaToFloat3(lumaO), 
//                      FxaaFloat3(1.0, 0.0, 0.0), -ox));
//        if(ox > 0.0) return FxaaFilterReturn(
//            FxaaLerp3(FxaaToFloat3(lumaO), 
//                      FxaaFloat3(0.0, 0.0, 1.0),  ox));
//        if(oy < 0.0) return FxaaFilterReturn(
//            FxaaLerp3(FxaaToFloat3(lumaO), 
//                      FxaaFloat3(1.0, 0.6, 0.2), -oy));
//        if(oy > 0.0) return FxaaFilterReturn(
//            FxaaLerp3(FxaaToFloat3(lumaO), 
//                      FxaaFloat3(0.2, 0.6, 1.0),  oy));
//        return FxaaFilterReturn(FxaaFloat3(lumaO, lumaO, lumaO));
//    #endif
    float3 rgbF = FxaaTexLod0(tex, FxaaFloat2(
        pos.x + (horzSpan ? 0.0 : subPixelOffset),
        pos.y + (horzSpan ? subPixelOffset : 0.0))).xyz;
    #if FXAA_SUBPIX == 0
      rgbM = rgbF;
    #else        
      rgbM = FxaaLerp3(rgbL, rgbF, blendL);
    #endif
   }  // EARLY OUT
   
   return FxaaFilterReturn(rgbM, ccc.a); 
}
