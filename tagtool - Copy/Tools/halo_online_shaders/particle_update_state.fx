#ifndef _PARTICLE_UPDATE_STATE_FX_
#define _PARTICLE_UPDATE_STATE_FX_

struct s_update_state
{
	PADDED(float, 1, m_gravity)
	PADDED(float, 1, m_air_friction)
	PADDED(float, 1, m_rotational_friction)
};

#endif