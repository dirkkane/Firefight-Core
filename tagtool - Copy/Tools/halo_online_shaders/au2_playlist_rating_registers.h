#ifndef _AU2_PLAYLIST_RATING_REGISTERS_H_
#define _AU2_PLAYLIST_RATING_REGISTERS_H_

#if DX_VERSION == 9

#ifndef CONSTANT_NAME
#define CONSTANT_NAME(n) n
#endif

#define k_ps_au2_playlist_rating_uv_coords CONSTANT_NAME(100)

#elif DX_VERSION == 11

#define FX_FILE "rasterizer\\hlsl\\au2_playlist_rating_registers.fx"
#include "rasterizer\dx11\rasterizer_dx11_define_fx_constants.h"
#undef FX_FILE

#endif

#endif
