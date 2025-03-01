#ifndef VMF_UTIL
#define VMF_UTIL

// Utility file for using H3 lighting as VMF

// Dual VMF:
// Direct (vmf0)
// [0] xyz  - light direction vmf0
// [0] w    - analytical mask
// [1] xyz  - color for vmf0
// [1] w    - vmf0 bandwidth
// Indirect (vmf1)
// [2] xyz  - light direction vmf1
// [2] w    - cloud mask
// [3] xyz  - color for vmf1
// [3] w    - vmf1 bandwidth

//
// diffuse_specular.hlsl
//

// need to supply this. extern default texture?
// rasterizer\diffuse_power_specular\diffuse_power.bitmap
sampler g_diffuse_power_specular;

float vmf_diffuse_specular(in float4 Y[2], in float3 vSurfNormal_in,float roughness)
{	
    float3 coord=float3(dot(Y[0].xyz, vSurfNormal_in)*0.5+0.5,
                        Y[1].w,
                        roughness);
                        
    float texture_sample=tex3D(g_diffuse_power_specular,coord).r;

	return texture_sample * 3; // normalized to [0,1], it should be [0,3]
}	

float3 dual_vmf_diffuse_specular(float3 reflected_dir, float4 lighting_constants[4],float roughness)
{	
    float4 dom[2]={lighting_constants[0],lighting_constants[1]};    
    float4 fil[2]={lighting_constants[2],lighting_constants[3]};    
    
    float vmf_specular_dom= vmf_diffuse_specular(dom, reflected_dir, roughness);
    float vmf_specular_fil= 0.25f;
    return  vmf_specular_dom * lighting_constants[1].rgb + 
           vmf_specular_fil * lighting_constants[3].rgb;
}

void dual_vmf_diffuse_specular_with_fresnel(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float4 lighting_constants[4],
	in float3 final_specular_color,							// diffuse reflectance (ignored for cook-torrance)
	in float specular_power,
	out float3 sh_glossy)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{    
    float3 view_reflect_dir=reflect(-view_dir,normal_dir);
    
    float3 vmf_specular= dual_vmf_diffuse_specular(view_reflect_dir, lighting_constants, specular_power);
    
    sh_glossy=final_specular_color*vmf_specular;
}

void dual_vmf_diffuse_specular_with_fresnel_emulated(
    in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 dominant_light_dir,
    in float3 dominant_light_intensity,
	in float3 final_specular_color,							// diffuse reflectance (ignored for cook-torrance)
	in float specular_power,
	out float3 sh_glossy)
{
    // VMF constants used by dual vmf diffuse spec:
    // vmf[0].xyz direct_direction
    // vmf[1].xyzw direct_color direct_bandwidth
    // vmf[3].xyz indirect_color
    
    // fake constants:
    float analytical_mask = 1.0f;                   //todo
    float dominant_bandwidth = 1.0f;                //todo
    float3 indirect_dir = float3(0, 0, 0);          //unneeded
    float cloud_mask = 0.0f;                        //unneeded
    float indirect_bandwidth = 0.0f;                //unneeded
    float3 indirect_color = float3(0.5, 0.5, 0.5);  //todo
    
    float4 vmf_constants[4] =
    {
        float4(dominant_light_dir.xyz, analytical_mask),
        float4(dominant_light_intensity.xyz, dominant_bandwidth),
        float4(indirect_dir.xyz, cloud_mask),
        float4(indirect_color.xyz, indirect_bandwidth)
    };
    
    dual_vmf_diffuse_specular_with_fresnel(
        view_dir,
        normal_dir,
        vmf_constants,
        final_specular_color,
        specular_power,
        sh_glossy
    );
}

#endif