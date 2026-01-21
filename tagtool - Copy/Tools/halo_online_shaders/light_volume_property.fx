#ifndef _LIGHT_VOLUME_PROPERTY_FX_
#define _LIGHT_VOLUME_PROPERTY_FX_

// Match with s_gpu_property.  
// The s_property struct is implemented internally with bitfields to save constant space.
// The EXTRACT_BITS macro should take 2-5 assembly instructions depending on whether the bits
// lie at the beginning/middle/end of the allowed range.
struct s_property 
{
	float4 m_innards;
};

// Match with e_property in c_light_volume_gpu::set_shader_functions().
#define _index_profile_thickness			0
#define _index_profile_color				1
#define _index_profile_alpha				2
#define _index_profile_intensity			3
#define _index_max							4

#endif
