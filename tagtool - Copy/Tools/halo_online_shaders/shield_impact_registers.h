#ifndef _SHIELD_IMPACT_REGISTERS_H_
#define _SHIELD_IMPACT_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

// MS23 vertex constants
#define k_vs_shield_impact_vertex_params                CONSTANT_NAME(228)
#define k_vs_shield_impact_vertex_params2               CONSTANT_NAME(229)
#define k_vs_shield_impact_impact0_params               CONSTANT_NAME(230)
#define k_vs_shield_impact_impact1_params               CONSTANT_NAME(231)

// MS23 pixel constants
#define k_ps_shield_impact_impact0_color                CONSTANT_NAME(100)
#define k_ps_shield_impact_plasma_offsets               CONSTANT_NAME(102)
#define k_ps_shield_impact_edge_glow                    CONSTANT_NAME(103)
#define k_ps_shield_impact_plasma_color                 CONSTANT_NAME(104)
#define k_ps_shield_impact_plasma_edge_color            CONSTANT_NAME(105)
#define k_ps_shield_impact_edge_scales                  CONSTANT_NAME(106)
#define k_ps_shield_impact_edge_offsets                 CONSTANT_NAME(107)
#define k_ps_shield_impact_plasma_scales                CONSTANT_NAME(108)
#define k_ps_shield_impact_depth_fade_params            CONSTANT_NAME(109)

#define k_vs_shield_impact_extrusion_distance 			CONSTANT_NAME(228)

#define k_ps_shield_impact_bound_sphere 				CONSTANT_NAME(100)
#define k_ps_shield_impact_shield_dynamic_quantities	CONSTANT_NAME(101)
#define k_ps_shield_impact_texture_quantities 			CONSTANT_NAME(102)
#define k_ps_shield_impact_plasma1_settings				CONSTANT_NAME(103)
#define k_ps_shield_impact_plasma2_settings				CONSTANT_NAME(104)
#define k_ps_shield_impact_overshield_color1			CONSTANT_NAME(105)
#define k_ps_shield_impact_overshield_color2			CONSTANT_NAME(106)
#define k_ps_shield_impact_overshield_ambient_color		CONSTANT_NAME(107)
#define k_ps_shield_impact_color1						CONSTANT_NAME(108)
#define k_ps_shield_impact_color2						CONSTANT_NAME(109)
#define k_ps_shield_impact_ambient_color				CONSTANT_NAME(110)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\shield_impact_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif