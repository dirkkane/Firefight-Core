#ifndef _CUBEMAP_REGISTERS_H_
#define _CUBEMAP_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_cubemap_source_size 	CONSTANT_NAME(0)
#define k_ps_cubemap_forward 		CONSTANT_NAME(1)
#define k_ps_cubemap_up 			CONSTANT_NAME(2)
#define k_ps_cubemap_left 			CONSTANT_NAME(3)
#define k_ps_cubemap_param 			CONSTANT_NAME(4)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\cubemap_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
