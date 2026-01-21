#ifndef _MISC_ATTR_ANIMATION_FX_
#define _MISC_ATTR_ANIMATION_FX_

#include "deform.fx"

#define DECOMPRESS_DEFORM_UNROLLED(deform) decompress_##deform
#define decompress_deform DECOMPRESS_DEFORM_UNROLLED(deform)


float3x3 make_rotation_matrix(float angle, float3 axis)
{
	float c, s;
	sincos(angle, s, c);

	float t = 1 - c;
	float x = axis.x;
	float y = axis.y;
	float z = axis.z;

	return float3x3(
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c
	);
}

PARAM(float, scrolling_axis_x);
PARAM(float, scrolling_axis_y);
PARAM(float, scrolling_axis_z);
static float3 scrolling_axis = { scrolling_axis_x, scrolling_axis_y, scrolling_axis_z };
PARAM(float, scrolling_speed);
void calc_misc_scrolling_cube_vs(in vertex_type vertex, out float4 misc)
{
	float3 rotated_normal = mul(vertex.normal.xyz, make_rotation_matrix(vs_total_time * scrolling_speed, scrolling_axis));
	misc = float4(rotated_normal, 0.0f);
}

PARAM(float, object_center_x);
PARAM(float, object_center_y);
PARAM(float, object_center_z);
static float3 object_center = { object_center_x, object_center_y, object_center_z };
PARAM(float, plane_u_x);
PARAM(float, plane_u_y);
PARAM(float, plane_u_z);
static float3 plane_u = { plane_u_x, plane_u_y, plane_u_z };
PARAM(float, plane_v_x);
PARAM(float, plane_v_y);
PARAM(float, plane_v_z);
static float3 plane_v = { plane_v_x, plane_v_y, plane_v_z };
PARAM(float, scale_u);
PARAM(float, scale_v);
static float2 scale = { scale_u, scale_v };
PARAM(float, translate_u);
PARAM(float, translate_v);
static float2 translate = { translate_u, translate_v };
PARAM(float, speed_u);
PARAM(float, speed_v);
static float2 speed = { speed_u, speed_v };
void calc_misc_scrolling_projected_vs(in vertex_type vertex, out float4 misc)
{
	float3 vn = normalize(vertex.position.xyz - object_center);
	float u = dot(vn, plane_u);
	float v = dot(vn, plane_v);
	const float pi = 3.14159265359;
	float2 uv = acos(float2(u, v)) / pi * scale + translate;

	uv += speed * vs_total_time;
	misc = float4(uv, 0.0f, 0.0f);
}

	
PARAM(int, misc_attr_animation_option);
void misc_attr_animation(in vertex_type vertex, out float4 misc)
{
	decompress_deform(vertex);
	[branch]
	switch (misc_attr_animation_option)
	{
		case 2:
			calc_misc_scrolling_projected_vs(vertex, misc);
			break;
		case 1:
			calc_misc_scrolling_cube_vs(vertex, misc);
			break;
		default:
			misc = float4(0, 0, 0, 0);
			break;
	};
}

#endif
