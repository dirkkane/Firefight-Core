/*
PARTICLE.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
04/12/2006 13:36 davcook	
*/

#include "global.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_particle_vertex
//@generate s_particle_model_vertex

#define PARTICLE_RENDER_METHOD_DEFINITION 1

// The strings in this test should be external preprocessor defines
#define TEST_CATEGORY_OPTION(cat, opt) (category_##cat== category_##cat##_option_##opt)
#define IF_CATEGORY_OPTION(cat, opt) if (TEST_CATEGORY_OPTION(cat, opt))
#define IF_NOT_CATEGORY_OPTION(cat, opt) if (!TEST_CATEGORY_OPTION(cat, opt))

#if DX_VERSION == 9
#define CATEGORY_PARAM(_name) PARAM(int, _name)
#elif DX_VERSION == 11
#define CATEGORY_PARAM(_name) PARAM(float, _name)
#endif

// If the categories are not defined by the preprocessor, treat them as shader constants set by the game.
// We could automatically prepend this to the shader file when doing generate-templates, hmmm...
#ifndef category_albedo
CATEGORY_PARAM(category_albedo);
#endif
#ifndef category_blend_mode
CATEGORY_PARAM(category_blend_mode);
#endif
#ifndef category_depth_fade
CATEGORY_PARAM(category_depth_fade);
#endif
#ifndef category_lighting
CATEGORY_PARAM(category_lighting);
#endif
#ifndef category_fog
CATEGORY_PARAM(category_fog);
#endif
#ifndef category_specialized_rendering
CATEGORY_PARAM(category_specialized_rendering);
#endif
#ifndef category_frame_blend
CATEGORY_PARAM(category_frame_blend);
#endif
#ifndef category_self_illumination
CATEGORY_PARAM(category_self_illumination);
#endif

PARAM(float, depth_fade_range);

#include "particle_render.hlsl"
