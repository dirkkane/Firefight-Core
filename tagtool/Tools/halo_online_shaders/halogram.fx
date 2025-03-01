// .halogram is basically the same as .shader, except it has several hardcoded categories:
//      albedo                  as .shader
//      bump_mapping            NONE
//      alpha_test              NONE
//      specular_mask           NONE
//      material_model          NONE
//      environment_mapping     NONE
//      self_illumination       as .shader
//      blend_mode              as .shader
//      parallax                NONE
//      misc                    as .shader

#define calc_bumpmap_ps calc_bumpmap_off_ps

#define calc_alpha_test_ps calc_alpha_test_off_ps

#define calc_specular_mask_ps calc_specular_mask_no_specular_mask_ps

#define material_type none

#define envmap_type none

#ifdef disable_register_reorder
// magic pragma given to us by the DX10 team
// to disable the register reordering pass that was
// causing a lot of pain on the PC side of the compiler
// with this pragma we get a massive speedup on compile times
// on the PC side
#pragma ruledisable 0x0a0c0101
#endif // #ifdef disable_register_reorder

#include "global.fx"
#include "hlsl_constant_mapping.fx"

#define LDR_ALPHA_ADJUST g_exposure.w
#define HDR_ALPHA_ADJUST g_exposure.b
#define DARK_COLOR_MULTIPLIER g_exposure.g

#include "utilities.fx"
#include "deform.fx"
#include "texture_xform.fx"

#include "blend.fx"
#include "misc_attr_animation.fx"
#include "albedo.fx"
#include "parallax.fx"
#include "warp.fx"
#include "bump_mapping.fx"
#include "self_illumination.fx"
#include "self_illumination_halogram.fx"
#include "specular_mask.fx"
#include "material_models.fx"
#include "environment_mapping.fx"
#include "atmosphere.fx"
#include "alpha_test.fx"
#include "distortion.fx"

// any bloom overrides must be #defined before #including render_target.fx
#include "render_target.fx"
#include "albedo_pass.fx"

#include "shadow_generate.fx"

#include "debug_modes.fx"

#include "overlays.fx"

#include "entry_points.fx"

