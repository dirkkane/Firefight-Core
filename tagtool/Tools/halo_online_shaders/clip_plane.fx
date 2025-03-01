#ifndef _CLIP_PLANE_FX_
#define _CLIP_PLANE_FX_

#if DX_VERSION == 9

#define CLIP_OUTPUT
#define CLIP_OUTPUT_PARAM
#define CLIP_INPUT
#define CLIP_INPUT_PARAM
#define CALC_CLIP(_screen_position)

#elif DX_VERSION == 11

#define CLIP_OUTPUT out float clip_distance : SV_ClipDistance,
#define CLIP_OUTPUT_PARAM clip_distance,
#define CLIP_INPUT in float clip_distance : SV_ClipDistance,
#define CLIP_INPUT_PARAM clip_distance,
#define CALC_CLIP(_screen_position) clip_distance = dot(_screen_position, v_clip_plane)

#endif

#endif
