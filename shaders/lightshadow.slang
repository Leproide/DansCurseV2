#version 450
// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - ombre delle sorgenti di luce puntiformi (fiamme, magie)
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later
//
// Per ogni pixel trova la luce che conta di piu' e marcia nello schermo verso di essa:
// se qualcosa si mette in mezzo, quel pixel e' in ombra rispetto alla luce. Come per le
// ombre della luna, il rumore cambia a ogni frame e il risultato viene accumulato nel
// tempo con la telecamera del frame precedente.
// Uscita: x = luce che arriva (1 = piena, 0 = in ombra), w = distanza.

#include "common.inc"

layout(set = 0, binding = 2) uniform sampler2D Geometry;
layout(set = 0, binding = 3) uniform sampler2D LightShadowFeedback;
layout(set = 0, binding = 4) uniform sampler2D SceneLights;

#include "vertex.inc"
#include "lights.inc"

const int STEPS = 12;

float towardLight(vec3 p, vec3 n, vec3 target, float radius)
{
    vec3 toLight = target - p;
    float distance = length(toLight);
    if (distance < 1.0) return 1.0;
    vec3 l = toLight / distance;
    if (dot(n, l) < -0.05) return 1.0;

    // ci si ferma prima della luce: la fiamma e il suo supporto (torcia, braciere, muro su
    // cui e' appesa) non devono fare ombra, la luce del gioco e' ancorata lo' vicino
    float reach = distance - max(120.0, radius * 0.12);
    if (reach < 20.0) return 1.0;
    float jitter = frameNoise(gl_FragCoord.xy + vec2(31.0, 17.0));
    float bias = max(p.z * 0.002, 1.0);
    float thickness = 60.0 + p.z * 0.01;
    vec3 start = p + n * max(4.0, bias * 2.0);

    for (int i = 1; i <= STEPS; i++)
    {
        float t = (float(i) - jitter) / float(STEPS);
        vec3 s = start + l * reach * t;
        vec2 suv = project(s);
        if (s.z <= 1.0 || !onScreen(suv)) break;

        float sd = depthAt(suv);
        if (!hasGeometry(sd)) continue;

        float diff = s.z - viewZ(sd);
        if (diff > bias && diff < thickness)
        {
            vec2 edge = min(suv, 1.0 - suv);
            return mix(1.0, 0.0, smoothstep(0.0, 0.03, min(edge.x, edge.y)));
        }
    }

    return 1.0;
}

void main()
{
    float d = depthAt(vTexCoord);
    if (!hasGeometry(d) || global.DC_LIGHT_SHADOWS <= 0.0)
    {
        FragColor = vec4(1.0, 0.0, 0.0, 0.0);
        return;
    }

    vec3 p = viewPos(vTexCoord, d);
    float current = 1.0;
    int i = dominantLight(p);
    if (i >= 0) {
        PointLight light = lightAt(i);
        current = towardLight(p, decodeNormal(texture(Geometry, vTexCoord).rg), light.position, light.radius);
    }

    float result = current;
    if (global.CameraAvailable > 0.5 && global.PreviousCameraAvailable > 0.5 && global.DC_TEMPORAL > 0.0)
    {
        vec3 world = toWorld(p);
        vec2 previous = previousUv(world);
        if (onScreen(previous))
        {
            vec4 history = texture(LightShadowFeedback, previous);
            vec3 w = world - global.PreviousCameraTranslation.xyz;
            float previousZ = dot(global.PreviousCameraRow2.xyz, w);
            if (history.w > 1.0 && abs(history.w - previousZ) < max(previousZ * 0.04, 8.0))
                result = mix(history.x, current, 1.0 - global.DC_TEMPORAL);
        }
    }

    FragColor = vec4(result, 0.0, 0.0, p.z);
}
