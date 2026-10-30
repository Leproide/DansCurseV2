#version 450
// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - ombre di contatto e accumulo temporale di ombre e occlusione
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later
//
// Nella V1 ombre e occlusione erano calcolate con pochi campioni e un rumore fisso, senza
// alcun filtro nel tempo: restava un motivo a puntini. Qui il rumore cambia a ogni frame e il
// risultato viene fuso con quello del frame precedente, riproiettato con la telecamera
// precedente (stessa posizione nel mondo). Se la profondita' non corrisponde (oggetto mosso,
// zona appena scoperta) la storia viene scartata.
// Uscita: x = occlusione ambientale, y = chiusura (luce del cielo), z = ombra, w = distanza.

#include "common.inc"

layout(set = 0, binding = 2) uniform sampler2D Geometry;
layout(set = 0, binding = 3) uniform sampler2D OcclusionFeedback;

#include "vertex.inc"

const int SHADOW_STEPS = 16;
const float SHADOW_FAR = 9000.0;

// ombra di contatto: marcia nello schermo verso la luce (come nella V1, con rumore per frame)
float contactShadow(vec3 p, vec3 n, vec3 l)
{
    float reach = global.DC_SHADOW_LENGTH;
    float jitter = frameNoise(gl_FragCoord.xy + vec2(13.0, 7.0));
    float bias = max(p.z * 0.002, 1.0);
    float thickness = reach * 0.25 + p.z * 0.01;
    vec3 start = p + n * max(reach * 0.03, bias * 2.0);

    for (int i = 1; i <= SHADOW_STEPS; i++)
    {
        float t = (float(i) - jitter) / float(SHADOW_STEPS);
        vec3 s = start + l * reach * t * t;
        vec2 suv = project(s);
        if (s.z <= 1.0 || !onScreen(suv)) break;

        float sd = depthAt(suv);
        if (!hasGeometry(sd)) continue;

        float diff = s.z - viewZ(sd);
        if (diff > bias && diff < thickness)
        {
            vec2 edge = min(suv, 1.0 - suv);
            float fade = smoothstep(0.0, 0.03, min(edge.x, edge.y));
            return mix(1.0, t * t * 0.5, fade);
        }
    }

    return 1.0;
}

void main()
{
    float d = depthAt(vTexCoord);
    if (!hasGeometry(d))
    {
        FragColor = vec4(1.0, 1.0, 1.0, 0.0);
        return;
    }

    vec3 p = viewPos(vTexCoord, d);
    vec4 g = texture(Geometry, vTexCoord);
    vec3 n = decodeNormal(g.rg);
    vec3 l = sunDir();

    float shadow = 1.0;
    if (global.DC_SHADOW > 0.0 && p.z < SHADOW_FAR && dot(n, l) > -0.1)
        shadow = contactShadow(p, n, l);

    vec3 current = vec3(g.b, g.a, shadow);
    vec3 result = current;

    if (global.CameraAvailable > 0.5 && global.PreviousCameraAvailable > 0.5 && global.DC_TEMPORAL > 0.0)
    {
        vec3 world = toWorld(p);
        vec2 previous = previousUv(world);
        if (onScreen(previous))
        {
            vec4 history = texture(OcclusionFeedback, previous);
            vec3 w = world - global.PreviousCameraTranslation.xyz;
            float previousZ = dot(global.PreviousCameraRow2.xyz, w);
            bool valid = history.w > 1.0 && abs(history.w - previousZ) < max(previousZ * 0.04, 8.0);
            if (valid) result = mix(history.xyz, current, 1.0 - global.DC_TEMPORAL);
        }
    }

    FragColor = vec4(result, p.z);
}
