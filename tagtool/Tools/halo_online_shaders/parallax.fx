
PARAM(float, height_scale);
PARAM_SAMPLER_2D(height_map);
PARAM(float4, height_map_xform);


void calc_parallax_off_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	parallax_texcoord= texcoord;
}

void calc_parallax_simple_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	texcoord= transform_texcoord(texcoord, height_map_xform);
	float height= (sample2D(height_map, texcoord).g - 0.5f) * height_scale;		// ###ctchou $PERF can switch height maps to be signed and get rid of this -0.5 bias
	parallax_texcoord= texcoord + height * view_dir.xy;

	parallax_texcoord= (parallax_texcoord - height_map_xform.zw) / height_map_xform.xy;
}

void calc_parallax_two_sample_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	float height= 0.0f;
	
	texcoord= transform_texcoord(texcoord, height_map_xform);
	float height_difference= (sample2D(height_map, texcoord).g - 0.5f) * height_scale - height;
	parallax_texcoord= texcoord + height_difference * view_dir.xy;
	height= height + height_difference * view_dir.z;
	
	height_difference= (sample2D(height_map, parallax_texcoord).g - 0.5f) * height_scale - height;
	parallax_texcoord= parallax_texcoord + height_difference * view_dir.xy;
	
	/// height= height + height_difference * view_dir.z;
	parallax_texcoord= (parallax_texcoord - height_map_xform.zw) / height_map_xform.xy;

}

void calc_parallax_interpolated_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	texcoord= transform_texcoord(texcoord, height_map_xform);
	float cur_height= 0.0f;

	float height_1= (sample2D(height_map, texcoord).g - 0.5f) * height_scale;	
	float height_difference= height_1 - cur_height;
	float2 step_offset= height_difference * view_dir.xy;
	
	parallax_texcoord= texcoord + step_offset;
	cur_height= height_difference * view_dir.z;
	
	float height_2= (sample2D(height_map, parallax_texcoord).g - 0.5f) * height_scale;
	
	height_difference= height_2 - cur_height;
	if (sign(height_difference) != sign(height_1 - cur_height))
	{
		float pct= height_1 / (cur_height - height_2 + height_1);
		parallax_texcoord= texcoord + pct * step_offset;
	}
	else
	{
		parallax_texcoord= parallax_texcoord + height_difference * view_dir.xy;		// view_dir.xy
//		float height_2= height_1 + height_difference * view_dir.z;
	}

	parallax_texcoord= (parallax_texcoord - height_map_xform.zw) / height_map_xform.xy;
}

void calc_parallax_three_sample_ps()
{
/*	
	parallax_texcoord= texcoord * height_map_xform.xy + height_map_xform.zw;

	float height= 0.0f;
	float height_difference= (sample2D(height_map, parallax_texcoord).g - 0.5f) * height_scale - height;
	parallax_texcoord= texcoord + height_difference * view_dir.xy;

	height= height + height_difference * view_dir.z;
	height_difference= (sample2D(height_map, parallax_texcoord).g - 0.5f) * height_scale - height;
	parallax_texcoord= parallax_texcoord + height_difference * view_dir.xy;

	height= height + height_difference * view_dir.z;
	height_difference= (sample2D(height_map, parallax_texcoord).g - 0.5f) * height_scale - height;
	parallax_texcoord= parallax_texcoord + height_difference * view_dir.xy;
*/
}

PARAM_SAMPLER_2D(height_scale_map);
PARAM(float4, height_scale_map_xform);

void calc_parallax_simple_detail_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	parallax_texcoord= transform_texcoord(texcoord, height_map_xform);
	float height= (sample2D(height_map, parallax_texcoord).g - 0.5f) * sample2D(height_scale_map, transform_texcoord(texcoord, height_scale_map_xform)).g * height_scale;
	parallax_texcoord= parallax_texcoord + height * view_dir.xy;

	parallax_texcoord= (parallax_texcoord - height_map_xform.zw) / height_map_xform.xy;
}

PARAM(int, parallax_samples_max);

#define parallax_scale height_scale
#define height_r_max 1.0f
#define height_r_min 0.0f

void calc_parallax_custom_ps(
	in float2 texcoord,
	in float3 view_dir,
	out float2 parallax_texcoord)
{
    float3 viewTS = view_dir;	//The view vector is already multiplied by the tangent frame in entry points.
    //const float samples = parallax_samples_max;

    float sampleInterval = 1.0 / parallax_samples_max;//------------------------If samples is 8, sampleInterval will be 0.125f

    float currentRayDepth = 0.0;//----------------------------------------------We add sampleInterval to this each time we do our ray march to keep track of our ray's current depth.

    float2 p = viewTS.xy / viewTS.z * parallax_scale; 
    float2 deltaUV = p / parallax_samples_max;//--------------------------------Math to set up how much we offset the texture coordinates each time we do our ray march.

	float2 currentUV = texcoord;//--------This starts out as our regular UV coordinates, but will be offset by deltaUV in the loop bellow.
    
	float sampledDepth = 1 - sample2D(height_map, transform_texcoord(currentUV, height_map_xform)).g;//---------------The depth value of the current sampled pixel at the original texcoord.


    float2 uv_transformed = transform_texcoord(currentUV, height_map_xform);
    float2 dx = ddx(uv_transformed);
    float2 dy = ddy(uv_transformed);

    [loop]
    while(currentRayDepth < sampledDepth)//							...if the depth value sampled at the ray's current UV position is greater than the ray's depth below the surface, then...
    {
        currentUV -= deltaUV;//										...offset the UV to the ray's next position, then...

        sampledDepth = 1 - tex2Dgrad(height_map, transform_texcoord(currentUV, height_map_xform), dx, dy).g;//	...sample the depth value at next position, then..

        currentRayDepth  += sampleInterval;//						...update the depth the ray is at, then...(repeat)
    }/*
																	When the current ray's depth is greater than the sampled depth, then our ray has "collided" with the virtual surface represented in
																	our heightmap. That collision tells us that the UV coordinates of current sample is the part of the surface the viewer would see 
																	from their perspective if that surface were displaced to match that virtual surface, and so we sample the material's textures at
																	that offset UV rather than the original one.

																	At least, that's the basic idea but doing this alone wouldn't look great. Because we are checking along our ray's path at fixed
																	intervals, the collision may be detected at a position past the point where the ray would have actually collided with the virtual
																	surface by a deceent margin. This would make the surface look like a bunch of paper thin layers hovering ontop of eachother. 

																	Rather than doing that, we can instead sample at a UV that is interpolated between the current sample's UV and the prior one to 
																	approximate where the collision should have happened. This isn't perfect, but it reduces the amount of samples needed to mitigate
																	that layered look and make the effect convincing.*/

    float2 priorUV = currentUV + deltaUV;//We take the current sample's UV and offset it back to get the UV of the prior sample.

    float afterDepth = sampledDepth - currentRayDepth;//Difference between the current sample's depth and the height value at that sample. 

    float beforeDepth = (1 - sample2D(height_map, transform_texcoord(priorUV, height_map_xform)).g) - currentRayDepth + sampleInterval;//Difference between the prior sample's depth and the height at that sample.

    float weight = afterDepth / (afterDepth - beforeDepth);//We use those last two values to create a coefficient.

    parallax_texcoord = priorUV * weight + currentUV * (1.0 - weight);//We use that coefficient to lerp between the current UV, and the last UV. The resulting value is the final UV value used to sample our material's textures.
}