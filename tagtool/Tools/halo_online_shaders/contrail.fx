/*
CONTRAIL.FX
Copyright (c) Microsoft Corporation, 2005. all rights reserved.
04/12/2006 13:36 davcook	
*/

#include "global.fx"

//This comment causes the shader compiler to be invoked for certain types
//@generate s_contrail_vertex

#define CONTRAIL_RENDER_METHOD_DEFINITION 1

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
#ifndef category_albedo
CATEGORY_PARAM(category_albedo);
#endif
#ifndef category_blend_mode
CATEGORY_PARAM(category_blend_mode);
#endif
#ifndef category_fog
CATEGORY_PARAM(category_fog);
#endif

#include "contrail_render.hlsl"
