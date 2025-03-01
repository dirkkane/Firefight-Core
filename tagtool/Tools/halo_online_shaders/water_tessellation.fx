/*
WATER_TESSELLATION.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
04/12/2006 13:36 davcook	
*/

//This comment causes the shader compiler to be invoked for certain types
//@generate s_water_vertex


#ifdef VERTEX_SHADER

static const float MAX_TESS_LEVEL= 15.0f;
static const float ANGLE_TO_TESS_LEVEL_RATIO= 100.0f;
static const float TESS_LEVEL_DISTANCE_DAMP= 40;

float edge_tess_level(
	  float3 camera_position,
	  float3 pos0,
	  float3 pos1,
	  float camera_sin)
{
	float3 center= ( pos0 + pos1 ) * 0.5f;
	float radius= length(pos0 - center);
	float distance= length(center - camera_position);
	distance= max(distance, 0.001f); // avoid to be zero

	if ( distance < 5 / camera_sin )
	{
		return MAX_TESS_LEVEL;
	}
	else if ( radius > distance )
	{
		return MAX_TESS_LEVEL;	// boudning sphere contains eyes, so big ...
	}
	else
	{
		float sin_theta= radius / distance;

		float distance_coefficient= saturate(1.0f - distance / TESS_LEVEL_DISTANCE_DAMP);
		distance_coefficient= distance_coefficient * distance_coefficient;
		float angle_to_tess= ANGLE_TO_TESS_LEVEL_RATIO * distance_coefficient;

		float level= min( sin_theta * angle_to_tess / camera_sin, MAX_TESS_LEVEL);
		return level;
	}	
}

float cone_face_testing(
	   float3 camera_position,
	   float3 camera_forward,
	   float3 camera_diagonal,
	   float3 pos0,
	   float3 pos1,
	   float3 pos2)
{
	float3 face_center= (pos0 + pos1 + pos2 ) * 0.33333f;
	float face_radius= length(pos0 - face_center);
	face_radius= max(face_radius, length(pos1 - face_center));
	face_radius= max(face_radius, length(pos2 - face_center));

	float3 face_dir= face_center - camera_position;
	float face_dis= length( face_dir );
	// sphere contains eye, KEEP
	if (face_radius > face_dis )
	{
		return true;
	}

	// compute face bounding sphere angle to eye position	
	float sph_sin= face_radius / face_dis;
	float sph_cos= sqrt( 1 - sph_sin*sph_sin);

	// compute face center angle to eye position
	face_dir= normalize(face_dir);
	float cent_cos= dot(face_dir, camera_forward);	
	float cent_sin= sqrt( 1 - cent_cos * cent_cos);

	// comput angle to sphere boundary
	float bund_sin= cent_sin*sph_cos - cent_cos*sph_sin;
	float bund_cos= cent_cos*sph_cos + cent_sin*sph_sin;

	// sphere cross the forward line of eye, KEEP
	if ( bund_sin < 0 )
	{
		return true;
	}

	// sphere is on the other side of eye, CULL
	if ( bund_cos < 0 )
	{
		return false;
	}

	//	bund angle larger than view frustrum diagonal sin, CULL
	if ( bund_sin > camera_diagonal.x )
	{
		return false;
	}
	else
	{
		return true;
	}
}

// calculate tessellation level
#ifdef pc
   float4 water_tessellation_vs( s_vertex_type_water_tessellation IN ) : SV_Position
#else
   void water_tessellation_vs( s_vertex_type_water_tessellation IN )
#endif
{
	static float4 x_const01= { 0, 1, 0, 0 };
	float level0, level1, level2;

	// indices of vertices
#ifndef pc
	int index= IN.index + k_water_index_offset.x;
#endif


#ifndef pc
	if ( k_is_under_screenshot ) 
	{
		level0= level1= level2= MAX_TESS_LEVEL;
	}
	else
#endif
	{
		float4 v_index0, v_index1, v_index2;
#ifndef pc
		asm {
			vfetch v_index0, index, color0
			vfetch v_index1, index, color1
			vfetch v_index2, index, color2
		};
#else
      v_index0 = 0;
      v_index1 = 0;
      v_index2 = 0;
#endif

		// positions of vertices in world space
		float4 v_pos0, v_pos1, v_pos2;
#ifndef pc
		asm {
			vfetch v_pos0, v_index0.x, position0
			vfetch v_pos1, v_index1.x, position0
			vfetch v_pos2, v_index2.x, position0
		};
#else
      v_pos0 = 0;
      v_pos1 = 0;
      v_pos2 = 0;
#endif

		level0= edge_tess_level(k_vs_tess_camera_position.xyz, v_pos0.xyz, v_pos1.xyz, k_vs_tess_camera_diagonal.x);
		level1= edge_tess_level(k_vs_tess_camera_position.xyz, v_pos1.xyz, v_pos2.xyz, k_vs_tess_camera_diagonal.x);
		level2= edge_tess_level(k_vs_tess_camera_position.xyz, v_pos2.xyz, v_pos0.xyz, k_vs_tess_camera_diagonal.x);

		float is_visible= cone_face_testing(
							k_vs_tess_camera_position.xyz,
							k_vs_tess_camera_forward.xyz,
							k_vs_tess_camera_diagonal.xyz,
							v_pos0.xyz,
							v_pos1.xyz,
							v_pos2.xyz);

		//level0= 15;
		//level1= 15;
		//level2= 15;

		level0*= is_visible;
		level1*= is_visible;
		level2*= is_visible;
	}

#ifdef pc

   return float4(0,0,0,0);
   
#else
	int out_index_0= index*3;
	int out_index_1= index*3 + 1;
	int out_index_2= index*3 + 2;	

	// export
	asm
    {
		alloc export= 1
		mad eA, out_index_0, x_const01, k_water_memexport_addr
		mov eM0, level0

		alloc export= 1
		mad eA, out_index_1, x_const01, k_water_memexport_addr		
		mov eM0, level1

		alloc export= 1
		mad eA, out_index_2, x_const01, k_water_memexport_addr
		mov eM0, level2
    };

    // This is a workaround for a bug in >=Profile builds.  Without it, we get occasional 
    // bogus memexports from nowhere during effect-heavy scenes.
	asm {
	alloc export=1
		mad eA.xyzw, hidden_from_compiler.y, hidden_from_compiler.yyyy, hidden_from_compiler.yyyy
	};
	asm {
	alloc export=1
		mad eA.xyzw, hidden_from_compiler.z, hidden_from_compiler.zzzz, hidden_from_compiler.zzzz
	};
#endif
	
}

#endif //VERTEX_SHADER

#ifdef PIXEL_SHADER


//	should never been executed
float4 water_tessellation_ps( SCREEN_POSITION_INPUT(screen_position) ) :SV_Target0
{
	return float4(0,1,2,3);
}

#endif //PIXEL_SHADER
