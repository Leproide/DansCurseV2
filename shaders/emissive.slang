#version 450
// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - sorgenti luminose (bagliore)
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later
//
// Nella V1 tutto cio' che era arancione e luminoso diventava una luce (oro, zucche).
// Ora conta solo cio' che e' molto piu' luminoso di quello che ha intorno: fiamme e lampade
// sono punti piccoli e brillanti, le superfici colorate grandi no.

#include "common.inc"

layout(set = 0, binding = 2) uniform sampler2D Original;

#include "vertex.inc"

const int TAPS = 4;

float emission(vec3 c)
{
    float peak = max(c.r, max(c.g, c.b));
    float low = min(c.r, min(c.g, c.b));
    float saturation = (peak - low) / max(peak, 1e-4);
    float warm = smoothstep(0.0, 0.25, c.r - c.b) * step(c.b, c.g + 0.05);
    float fire = smoothstep(0.6, 0.9, peak) * smoothstep(0.3, 0.6, saturation) * warm;
    float hot = smoothstep(0.85, 1.0, low) * step(c.b + 0.02, c.r);
    return max(fire, hot);
}

void main()
{
    vec2 footprint = global.OutputSize.zw;
    vec3 glow = vec3(0.0);
    float center = 0.0;
    for (int y = 0; y < TAPS; y++)
    for (int x = 0; x < TAPS; x++)
    {
        vec2 uv = vTexCoord + ((vec2(x, y) + 0.5) / float(TAPS) - 0.5) * footprint;
        if (isOverlay(depthAt(uv))) continue;
        vec3 c = texture(Original, uv).rgb;
        glow += toLinear(c) * emission(c);
        center += luma(c);
    }

    // anello di 8 campioni a 4 volte l'area del texel:
    // il campione piu' luminoso dell'anello: se e' luminoso quanto il centro la zona
    // chiara continua (superficie grande o bordo di un oggetto), quindi non e' una sorgente
    float ring = 0.0;
    for (int i = 0; i < 8; i++)
    {
        float a = float(i) * 0.7853982;
        ring = max(ring, luma(texture(Original, vTexCoord + vec2(cos(a), sin(a)) * footprint * 4.0).rgb));
    }

    float contrast = center / float(TAPS * TAPS) - ring;
    FragColor = vec4(glow / float(TAPS * TAPS) * smoothstep(0.04, 0.2, contrast), 1.0);
}
