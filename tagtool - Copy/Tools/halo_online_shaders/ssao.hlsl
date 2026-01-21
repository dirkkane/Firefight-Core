#line 1 "source\rasterizer\hlsl\ssao.hlsl"

#include "global.fx"
#include "hlsl_vertex_types.fx"
#include "ssao_registers.fx"

//@generate screen

LOCAL_SAMPLER_2D(depth_sampler, 0);
LOCAL_SAMPLER_2D(normal_sampler, 1);
LOCAL_SAMPLER_2D(noise_sampler, 2);

#define SSAO_MASK

struct SSAO_VS_OUTPUT
{
	float4 hpos : SV_Position;
	float4 texCoord   : TEXCOORD0;
	float3 viewVec    : TEXCOORD1;
};


SSAO_VS_OUTPUT default_vs(vertex_type IN)
{
   SSAO_VS_OUTPUT   res;

   res.hpos.xy = IN.position;
   res.hpos.z  = 0.5f;
   res.hpos.w  = 1.0f;

   res.viewVec = float3(IN.texcoord.xy, 1.0) - float3(0.5,0.5,0.0);
   res.viewVec *= float3(VS_FRUSTUM_SCALE.xy, 1.0);

  
   // texture coord for full-screen quad;
   res.texCoord.xy = IN.texcoord.xy;

   res.texCoord.zw = IN.texcoord.xy * TEXCOORD_SCALE.xy;

   return res;
}


float4 default_ps(SSAO_VS_OUTPUT input) : SV_Target
{
   //return PS_TEXTURES_2D[PS_SSAO_FIRST_TEX+1].Sample(PS_SAMPLERS[PS_SMP_WRAP_POINT], input.texCoord.zw);
   // constants
   //float nearPlane = 0.078125;
   //float farPlane = 10240.0;

   //return sample2D(normal_sampler, input.texCoord.xy);

   float linDepth = sample2D(depth_sampler, input.texCoord.xy).r;

   // disable for far distance
   if (linDepth > 2000.0f) {
      return 1.0f;
   }

   // define kernel
   const half3 arrKernelConst[8] =
   {
      normalize(half3( 1,-1,.5))*0.1,
      normalize(half3(-1,-1,.5))*0.09,
      normalize(half3( 1, 1,.5))*0.08,
      normalize(half3(-1, 1,.5))*0.07,
      normalize(half3(-1, 0, 1))*0.06,
      normalize(half3( 1, 0, 1))*0.05,
      normalize(half3( 0,-1, 1))*0.045,
      normalize(half3( 0, 1, 1))*0.04,
   };
   half3 arrKernel[8];
      
   float3 N2 = sample2D(normal_sampler, input.texCoord.xy);
   //return float4(N2, 1);
   N2 = N2 * 2.0f - 1.0f;

   //return N2.z;

   float3 N;
   N.x = dot(N2.xyz, PS_REG_SSAO_MV_1.xyz);
   N.y = dot(N2.xyz, PS_REG_SSAO_MV_2.xyz);
   N.z = dot(N2.xyz, PS_REG_SSAO_MV_3.xyz);

   // Convert normal to view-space
   //N.xyz = float3(dot(N2.xyz, float3(PS_REG_SSAO_MV_1.x, PS_REG_SSAO_MV_2.x, PS_REG_SSAO_MV_3.x)),
   //              -dot(N2.xyz, float3(PS_REG_SSAO_MV_1.y, PS_REG_SSAO_MV_2.y, PS_REG_SSAO_MV_3.y)),
   //              -dot(N2.xyz, float3(PS_REG_SSAO_MV_1.z, PS_REG_SSAO_MV_2.z, PS_REG_SSAO_MV_3.z)));

   //return N.z * 0.5 + 0.5;
   //return abs(PS_REG_SSAO_MV_1.r);

   //return float4(N.y, 1.0f);


   //return sample2D(noise_sampler, input.texCoord.zw).g;

   // create random rot matrix
   float4 rot = sample2D(noise_sampler, input.texCoord.zw);
   //rotSample.z = 0.5;
   // TODO: we can remove this normalize if we store normalized 2D vectors in
   // texture
   //rotSample = normalize(rotSample*2.0-1.0);
   //float3 rotSample = float3(0.0f, 0.0f, 0.0f);

   //return float4(rotSample, 1);

   for (int i=0; i<8; i++) {
      arrKernel[i].z = arrKernelConst[i].z;
      //arrKernel[i].xy = arrKernelConst[i].xy;
      //arrKernel[i].xy = reflect(arrKernelConst[i].xy, rotSample.xy);
      arrKernel[i].x = dot(arrKernelConst[i].xy, rot.xy);
      arrKernel[i].y = dot(arrKernelConst[i].xy, rot.zw);

      arrKernel[i] = reflect(arrKernel[i], normalize(N + half3(0, 0, -1.0f)));
   }

   //float fSceneDepth = linDepth / (farPlane - nearPlane);// [0,1] depth
   half fSceneDepthM = linDepth;// [zNear,zFar] depth

   float3 vSampleScale = SSAO_PARAMS.xxx;
   // make area bigger if distance more than 32 meters
   vSampleScale *= (1.4h + fSceneDepthM / 10.h );
   // clamp area at close distance (< 2M)
   vSampleScale *= saturate(fSceneDepthM * 0.5h);
   
   float fDepthRangeScale = SSAO_PARAMS.z / vSampleScale.z;

   float fDepthTestSoftness = 64.f/vSampleScale.z;


   float3 eyePosition = fSceneDepthM * input.viewVec / input.viewVec.z;

   // sample
   half4 vSkyAccess = 0.0f;
   half3 vIrrSample;
   half4 vDistance;
   float4 fRangeIsValid;
   float sum = 0.0f;//sum of weights

   float fHQScale = 0.5f;//scale of additional samples

   #define perspK PS_FRUSTUM_SCALE.zw

   for(int i=0; i<2; i++) {
      vIrrSample = arrKernel[i*4+0] * vSampleScale + eyePosition;
      vIrrSample.xy /= vIrrSample.z;
      vIrrSample.xy *= perspK;
      vIrrSample.xy += float2(0.5,0.5);
      vDistance.x = sample2D(depth_sampler, vIrrSample.xy).r - vIrrSample.z;

      vIrrSample = arrKernel[i*4+1] * vSampleScale + eyePosition;
      vIrrSample.xy /= vIrrSample.z;
      vIrrSample.xy *= perspK;
      vIrrSample.xy += float2(0.5,0.5);
      vDistance.y = sample2D(depth_sampler, vIrrSample.xy).r - vIrrSample.z;

      vIrrSample = arrKernel[i*4+2] * vSampleScale + eyePosition;
      vIrrSample.xy /= vIrrSample.z;
      vIrrSample.xy *= perspK;
      vIrrSample.xy += float2(0.5,0.5);
      vDistance.z = sample2D(depth_sampler, vIrrSample.xy).r - vIrrSample.z;

      vIrrSample = arrKernel[i*4+3] * vSampleScale + eyePosition;
      vIrrSample.xy /= vIrrSample.z;
      vIrrSample.xy *= perspK;
      vIrrSample.xy += float2(0.5,0.5);
      vDistance.w = sample2D(depth_sampler, vIrrSample.xy).r - vIrrSample.z;

      float4 vDistanceScaled = vDistance * fDepthRangeScale;
      fRangeIsValid = 1 - (saturate( -vDistanceScaled ) + saturate( abs(vDistanceScaled) )) * 0.5;

      float4 w = max(fRangeIsValid,0.5);
      vSkyAccess += lerp(1.0f, saturate(vDistance*fDepthTestSoftness + 1.0f),saturate(fRangeIsValid*2.0)) * w;
      sum += dot(w,1.0);
   }

   float Color;
   Color = dot( vSkyAccess, 1.0/sum ); //SSAO_params.y; // 0.075f
   Color = saturate(Color);//SSAO_params.x ));

   float intensity = SSAO_PARAMS.w;
   // disable for far distance 1000...2000 meters
   intensity *= saturate( 2.0f - linDepth / 1000.0f );

   float ssao = Color * Color;

   return lerp(1.0f, ssao, intensity);
}



/*
float4 default_ps(float4 hpos : POSITION, SSAO_VS_OUTPUT input) : COLOR
{
   //return PS_TEXTURES_2D[PS_SSAO_FIRST_TEX+1].Sample(PS_SAMPLERS[PS_SMP_WRAP_POINT], input.texCoord.zw);
   // constants
   float nearPlane = 0.078125;
   float farPlane = 10240.0;

   // define kernel
   const half3 arrKernelConst[8] =
   {
         normalize(half3( 1,-1, -1))*0.05,
         normalize(half3(-1,-1, -1))*0.05,
         normalize(half3(-1,-1, -1 ))*0.1,
         normalize(half3( 1,-1, -1 ))*0.1,
         normalize(half3( 1, 1, -1))*0.05,
         normalize(half3(-1, 1, -1))*0.05,
         normalize(half3(-1, 1, -1 ))*0.1,
         normalize(half3( 1, 1, -1 ))*0.1,      
   };
   half3 arrKernel[8];

   float linDepth = sample2D(depth_sampler, input.texCoord.xy).r;

   //return ddx(linDepth)*0.5 + ddy(linDepth)+0.5;
   // Restore normal from z-buffer
   // this is project-space normal
   float3 N;
   //N.xy = half2(ddx(sample_z(_TEX_SAMP(SSAO_FIRST), input.texCoord)-0.1)*1024.0, ddy(sample_z(_TEX_SAMP(SSAO_FIRST), input.texCoord)-0.1)*1024.0);

//#ifdef _AP_XENON



   float d1,d2,d3,d4;
   //float2 offset = input.texCoord2.xy;
   float2 offset = float2(1.0f/ 1152.0f, 1.0f/ 640.0f);
   d1 = sample2D(depth_sampler, input.texCoord.xy - offset).r;
   d2 = sample2D(depth_sampler, input.texCoord.xy + offset).r;
   offset.x = -offset.x;
   d3 = sample2D(depth_sampler, input.texCoord.xy - offset).r;
   d4 = sample2D(depth_sampler, input.texCoord.xy + offset).r;   
   //  d4 | d2
   //  -------
   //  d1 | d3

   //N.xy = half2(min(min(d3-d1),min(d2-d4))
   N.xy = float2((d2+d3-d1-d4)*0.5,(d4+d2-d1-d3)*0.5);

   // Where is this multiplier from???
   N.z = (linDepth/farPlane)*64.0;


   //N.xy = half2(ddx(linDepth), ddy(linDepth));
   if (N.x*N.x+N.y*N.y > SSAO_PARAMS.y*N.z) {
      return 1.0;
   }

   N = normalize(N);
   N = normalize(N + half3(0, 0, 1.0f));
   //return N.xyzz*0.5 + 0.5;

//return float4(N, 1);
   
   
   #if SSAO_USE_NOISE == 1
      // create random rot matrix
      half3 rotSample = PS_TEXTURES_2D[PS_SSAO_FIRST_TEX+1].Sample(PS_SAMPLERS[PS_SMP_WRAP_POINT], input.texCoord.zw);
      rotSample = normalize(rotSample*2.0-1.0);
   #endif

   for (int i=0; i<8; i++) {
      #if SSAO_USE_NOISE == 1
         arrKernel[i].z = arrKernelConst[i].z;
         arrKernel[i].xy = reflect_2D(arrKernelConst[i].xy, rotSample.xy);
         arrKernel[i] = reflect(arrKernel[i],N);
      #else
         arrKernel[i] = reflect(arrKernelConst[i],N);
      #endif
   }


   half fSceneDepth = linDepth / (farPlane - nearPlane);// [0,1] depth
   half fSceneDepthM = linDepth;// [zNear,zFar] depth

   half3 vSampleScale = SSAO_PARAMS.xxx * (2.0f + fSceneDepthM / 20.f ) * saturate(fSceneDepthM*0.5); // make area bigger if distance more than 32 meters

   float fDepthRangeScale = 1.0 / vSampleScale.z * 1.85f;

   vSampleScale.xy *= 1.0/fSceneDepthM;
   
   float fDepthTestSoftness = 64.f/vSampleScale.z;

   // sample
   half4 vSkyAccess = 0.0f;
   half4 arrSceneDepth2[2];
   half3 vIrrSample;
   half4 vDistance;
   float4 fRangeIsValid;
   float sum = 0.0f;//sum of weights

   float fHQScale = 0.5f;//scale of additional samples

   for(int i=0; i<2; i++)
   {
      vIrrSample = arrKernel[i*4+0] * vSampleScale;
      arrSceneDepth2[0].x = sample2D(depth_sampler, vIrrSample.xy + input.texCoord.xy).r + vIrrSample.z;
         

      vIrrSample = arrKernel[i*4+1] * vSampleScale;
      arrSceneDepth2[0].y = sample2D(depth_sampler, vIrrSample.xy + input.texCoord.xy).r + vIrrSample.z;

      vIrrSample = arrKernel[i*4+2] * vSampleScale;
      arrSceneDepth2[0].z = sample2D(depth_sampler, vIrrSample.xy + input.texCoord.xy).r + vIrrSample.z;

      vIrrSample = arrKernel[i*4+3] * vSampleScale;
      arrSceneDepth2[0].w = sample2D(depth_sampler, vIrrSample.xy + input.texCoord.xy).r + vIrrSample.z;

      vDistance = arrSceneDepth2[0] - linDepth;
      float4 vDistanceScaled = vDistance * fDepthRangeScale;
      //fRangeIsValid = 1 - (saturate( -vDistanceScaled ) + saturate( abs(vDistanceScaled) ))*0.5;
      fRangeIsValid = 1 - saturate(abs(vDistanceScaled));

      vSkyAccess += lerp(1.0f,saturate(vDistance*fDepthTestSoftness),saturate(fRangeIsValid*2.0))*max(fRangeIsValid,0.5);
      sum += dot(max(fRangeIsValid,0.5),1.0);
  }

#if 0
   for (int i=0; i<8; i++) {
      #if SSAO_USE_NOISE == 1
         arrKernel[i].z = arrKernelConst[i].z;
         arrKernel[i].xy = reflect_2D(arrKernelConst[i].xy, rotSample.xy);
         arrKernel[i].xy = reflect_2D(arrKernel[i].xy, float2(-0.43294, 0.90143));
         arrKernel[i] = reflect(arrKernel[i],N);
      #else
         arrKernel[i].z = arrKernelConst[i].z;
         arrKernel[i].xy = reflect(arrKernelConst[i].xy, float2(-0.43294, 0.90143));
         arrKernel[i] = reflect(arrKernel[i],N);
      #endif
   }
   
   for(int i=0; i<2; i++)
   {
      vIrrSample = arrKernel[i*4+0] * vSampleScale;
      arrSceneDepth2[0].x = sample_w(_TEX_SAMP(SSAO_FIRST), vIrrSample.xy + input.texCoord.xy) + vIrrSample.z;

      vIrrSample = arrKernel[i*4+1] * vSampleScale;
      arrSceneDepth2[0].y = sample_w(_TEX_SAMP(SSAO_FIRST), vIrrSample.xy + input.texCoord.xy) + vIrrSample.z;

      vIrrSample = arrKernel[i*4+2] * vSampleScale;
      arrSceneDepth2[0].z = sample_w(_TEX_SAMP(SSAO_FIRST), vIrrSample.xy + input.texCoord.xy) + vIrrSample.z;

      vIrrSample = arrKernel[i*4+3] * vSampleScale;
      arrSceneDepth2[0].w = sample_w(_TEX_SAMP(SSAO_FIRST), vIrrSample.xy + input.texCoord.xy) + vIrrSample.z;

      vDistance = arrSceneDepth2[0] - linDepth;
      float4 vDistanceScaled = vDistance * fDepthRangeScale;
      //fRangeIsValid = 1 - (saturate( -vDistanceScaled ) + saturate( abs(vDistanceScaled) ))*0.5;
      fRangeIsValid = 1 - saturate(abs(vDistanceScaled));
      
      vSkyAccess += lerp(1.0f,saturate(vDistance*fDepthTestSoftness),saturate(fRangeIsValid*2.0))*max(fRangeIsValid,0.5);
      sum += dot(max(fRangeIsValid,0.5),1.0);
  }
#endif
   
   float Color;
   //Color = dot( vSkyAccess+0.1, 1.0/16.0 ); //SSAO_params.y; // 0.075f
   Color = dot( vSkyAccess, 1.0/sum ); //SSAO_params.y; // 0.075f
   Color = saturate(Color);//SSAO_params.x ));

   return Color;
}
*/