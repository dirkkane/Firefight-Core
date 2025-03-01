#ifndef _RIPPLE_FX_
#define _RIPPLE_FX_

struct s_ripple
{
	// pos_flow : position0
	float2 position;
	float2 flow;

	// life_height : texcoord0
	float life;	
	float duration;
	float rise_period;	
	float height;

	// shock_spread : texcoord1
	float2 shock;	
	float size;	
	float spread;

	// pendulum : texcoord2
	float pendulum_phase;
	float pendulum_revolution;
	float pendulum_repeat;

	// pattern : texcoord3
	float pattern_start_index;
	float pattern_end_index;

	// foam : texcoord4
	float foam_out_radius;
	float foam_fade_distance;
	float foam_life;
	float foam_duration;	

	// flags : color0
	bool flag_drift;	
	bool flag_pendulum;
	bool flag_foam;
	bool flag_foam_game_unit;

	// funcs : color1
	int func_rise;
	int func_descend;
	int func_pattern;
	int func_foam;	
};

#endif