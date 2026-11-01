#version 450
// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - dati della scena (cielo, apertura, pavimento, colore della nebbia)
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later
//
// Uscita 4x1, ogni texel si aggiorna lentamente rispetto al frame precedente:
//  0: colore medio del cielo visibile, a = apertura (0 interno, 1 esterno)
//  1: x = limite di disegno (dal gioco se disponibile, altrimenti stimato e stabile),
//     y = quota di vuoto sotto l'orizzonte, z = quota di scena
//  2: x = altezza del pavimento nel mondo (Y verso il basso), y = valida
//  3: colore stabile per la nebbia: cambia solo quando si vede abbastanza cielo
// Nella V1 il colore della nebbia veniva dalla media dello schermo (anche dai muri quando il
// cielo non si vedeva) e la foschia a terra era misurata rispetto alla telecamera.

#include "common.inc"

layout(set = 0, binding = 2) uniform sampler2D Original;
layout(set = 0, binding = 3) uniform sampler2D SkyFeedback;
layout(set = 0, binding = 4) uniform sampler2D Geometry;

#include "vertex.inc"

// componente verso il basso del raggio di vista nel mondo (Y verso il basso)
float rayDown(vec2 uv)
{
    vec3 dir = normalize(vec3((uv - global.Projection.zw) * global.Projection.xy, 1.0));
    return global.CameraAvailable > 0.5 ? normalize(toWorldDirection(dir)).y : -dir.y;
}

const int GRID_X = 24;
const int GRID_Y = 16;
const float UPPER = 0.45;
const float SKY_RATE = 0.015;
const float FOG_RATE = 0.01;
const float GROUND_RATE = 0.04;
// stima del limite di disegno senza il dato del gioco: sale in fretta, scende molto piano
// (davanti a un muro la geometria visibile e' vicina, ma il limite di disegno non cambia)
const float FAR_RISE = 0.2;
const float FAR_FALL = 0.002;
// vuoto sotto l'orizzonte: raggio che scende di almeno questa quota (Y verso il basso)
const float BELOW = 0.03;

struct Survey
{
    vec3 sky;
    float skyCount;
    vec3 scene;
    float sceneCount;
    float open;
    float upper;
    float geometry;
    float floorY;
    float floorWeight;
    float far;
    float samples;
    float below;
};

Survey survey()
{
    Survey s;
    s.sky = vec3(0.0);
    s.scene = vec3(0.0);
    s.skyCount = 0.0;
    s.sceneCount = 0.0;
    s.open = 0.0;
    s.upper = 0.0;
    s.geometry = 0.0;
    s.floorY = 0.0;
    s.floorWeight = 0.0;
    s.far = 0.0;
    s.samples = 0.0;
    s.below = 0.0;

    for (int y = 0; y < GRID_Y; y++)
    for (int x = 0; x < GRID_X; x++)
    {
        vec2 uv = (vec2(x, y) + 0.5) / vec2(GRID_X, GRID_Y);
        float d = depthAt(uv);
        if (isOverlay(d)) continue;

        bool geometry = hasGeometry(d);
        vec3 c = toLinear(texture(Original, uv).rgb);
        s.samples += 1.0;
        if (geometry) s.far = max(s.far, viewPos(uv, d).z);

        if (uv.y < UPPER)
        {
            s.upper += 1.0;
            if (!geometry) s.open += 1.0;
        }

        if (global.DepthAvailable > 0.5 && !geometry)
        {
            if (rayDown(uv) > BELOW) s.below += 1.0;
            s.sky += c;
            s.skyCount += 1.0;
            continue;
        }

        s.scene += c;
        s.sceneCount += 1.0;
        if (geometry) s.geometry += 1.0;

        // pavimento: superfici rivolte verso l'alto nella parte bassa dello schermo
        if (geometry && uv.y > 0.3 && global.CameraAvailable > 0.5)
        {
            vec3 n = toWorldDirection(decodeNormal(texture(Geometry, uv).rg));
            if (n.y < -0.75)
            {
                vec3 p = viewPos(uv, d);
                float w = 1.0 / (1.0 + p.z * 0.0005);
                s.floorY += toWorld(p).y * w;
                s.floorWeight += w;
            }
        }
    }

    return s;
}

void main()
{
    vec4 previous = texture(SkyFeedback, vTexCoord);
    bool hasPrevious = previous.a > 0.25;
    Survey s = survey();

    if (vTexCoord.x < 0.25)
    {
        vec3 color = s.skyCount >= 4.0 ? s.sky / s.skyCount
                   : hasPrevious ? previous.rgb
                   : s.sceneCount > 0.0 ? s.scene / s.sceneCount * 0.5 : vec3(0.0);
        float openness = global.DepthAvailable > 0.5 ? smoothstep(0.03, 0.25, s.open / max(s.upper, 1.0)) : 1.0;
        if (global.SceneIndoor.y > 0.5) openness = mix(openness, 1.0 - global.SceneIndoor.x, global.DC_GAME_LIGHT);
        vec4 current = vec4(color, 0.5 + 0.5 * openness);
        FragColor = hasPrevious ? mix(previous, current, SKY_RATE) : current;
        return;
    }

    if (vTexCoord.x < 0.5)
    {
        float presence = s.geometry / float(GRID_X * GRID_Y);
        float below = s.samples > 0.0 ? s.below / s.samples : 0.0;

        // limite di disegno del gioco (patch del fork), accettato solo se la geometria visibile
        // non va molto oltre: se le unita' non tornassero si usa la stima
        float game = global.SceneViewDistance.y > 0.5 ? global.SceneViewDistance.x : 0.0;
        bool useGame = game > 500.0 && s.far < game * 1.25;

        if (!hasPrevious) FragColor = vec4(useGame ? game : s.far, below, presence, 1.0);
        else
        {
            float far = useGame ? mix(previous.x, game, 0.25)
                      : s.far > previous.x ? mix(previous.x, s.far, FAR_RISE)
                      : mix(previous.x, s.far, FAR_FALL);
            FragColor = vec4(far, mix(previous.y, below, 0.05), mix(previous.z, presence, 0.35), 1.0);
        }
        return;
    }

    if (vTexCoord.x < 0.75)
    {
        bool valid = previous.y > 0.5 && hasPrevious;
        if (s.floorWeight < 2.0)
        {
            FragColor = valid ? previous : vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }

        float floorY = s.floorY / s.floorWeight;
        // salto grande (cambio di livello o di zona): si riparte subito dal nuovo valore
        float blended = valid && abs(previous.x - floorY) < 1500.0 ? mix(previous.x, floorY, GROUND_RATE) : floorY;
        FragColor = vec4(blended, 1.0, 0.0, 1.0);
        return;
    }

    if (s.skyCount >= 8.0)
    {
        vec3 target = s.sky / s.skyCount;
        FragColor = hasPrevious ? vec4(mix(previous.rgb, target, FOG_RATE), 1.0) : vec4(target, 1.0);
    }
    else if (hasPrevious) FragColor = previous;
    else FragColor = vec4(s.sceneCount > 0.0 ? s.scene / s.sceneCount * 0.3 : CURSE_FOG, 1.0);
}
