#ifndef _BEAM_PROPERTY_FX_
#define _BEAM_PROPERTY_FX_

// Match with c_editable_property_base::e_output_modifier
#define _modifier_none			0	//_output_modifier_none
#define _modifier_add			1	//_output_modifier_add
#define _modifier_multiply		2	//_output_modifier_multiply

// Match with s_gpu_property.  
// The s_property struct is implemented internally with bitfields to save constant space.
// The EXTRACT_BITS macro should take 2-5 assembly instructions depending on whether the bits
// lie at the beginning/middle/end of the allowed range.
struct s_property 
{
	float4 m_innards;
};

// Match with e_property in c_beam_gpu.
#define _index_profile_offset				0
#define _index_profile_rotation				1
#define _index_profile_thickness			2
#define _index_profile_color				3
#define _index_profile_alpha				4
#define _index_profile_black_point			5
#define _index_profile_palette				6
#define _index_profile_intensity			7
#define _index_max							8

#endif
