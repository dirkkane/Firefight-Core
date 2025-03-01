#ifndef _DYNAMIC_LIGHT_CLIP_FX_
#define _DYNAMIC_LIGHT_CLIP_FX_

#if DX_VERSION == 11

struct s_dynamic_light_clip_distance
{
	float4 clip_distance_0123 : SV_ClipDistance0;
	float2 clip_distance_45 : SV_ClipDistance1;
};

s_dynamic_light_clip_distance calc_dynamic_light_clip_distance(in float4 position)
{
	s_dynamic_light_clip_distance result;

	[unroll]
	for (int i = 0 ; i < 6; i++)
	{
		float distance = dot(position, v_dynamic_light_clip_plane[i]);
		if (i < 4)
		{
			result.clip_distance_0123[i] = distance;
		} else
		{
			result.clip_distance_45[i - 4] = distance;
		}
	}
	
	return result;
}

#endif

#endif
