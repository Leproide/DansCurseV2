#version 450
// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - bloom_blur_h.slang
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later


#include "common.inc"

#define BLUR_AXIS vec2(1.0, 0.0)
#define BLUR_SPREAD 1.5
#include "blur.inc"
