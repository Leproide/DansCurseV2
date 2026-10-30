// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - sorgenti di luce puntiformi
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later
//
// Le luci arrivano da RecompOne: ogni sprite additivo ancorato nello spazio 3D (fiamme,
// scintille, magie) diventa una luce, con il colore medio della sua texture e un raggio
// proporzionale alla dimensione dello sprite. Posizione in coordinate di vista.
// Va incluso dopo la dichiarazione del sampler SceneLights.

const int MAX_LIGHTS = 32;

struct PointLight
{
    vec3 position;
    vec3 color;
    float radius;
};

int lightCount()
{
    return min(int(global.SceneLightCount + 0.5), MAX_LIGHTS);
}

PointLight lightAt(int i)
{
    PointLight light;
    vec4 placement = texelFetch(SceneLights, ivec2(i * 2, 0), 0);
    light.position = placement.xyz;
    light.color = toLinear(texelFetch(SceneLights, ivec2(i * 2 + 1, 0), 0).rgb);
    light.radius = placement.w * global.DC_LIGHT_RANGE;
    return light;
}

// tremolio delle luci color fuoco: rumore lento legato alla posizione nel mondo,
// cosi' ogni fiamma tremola per conto suo e non cambia muovendo la telecamera
float flicker(PointLight light)
{
    if (global.DC_FLICKER <= 0.0) return 1.0;
    float warm = smoothstep(0.08, 0.35, light.color.r - light.color.b);
    if (warm <= 0.0) return 1.0;
    vec3 world = global.CameraAvailable > 0.5 ? toWorld(light.position) : light.position;
    vec2 seed = floor(world.xz / 96.0);
    float t = seconds();
    float n = valueNoise(vec2(t * 7.0, hash(seed) * 97.0)) * 0.65 + valueNoise(vec2(t * 17.0, hash(seed + 3.1) * 53.0)) * 0.35;
    return 1.0 + (n - 0.5) * 0.7 * warm * global.DC_FLICKER;
}

// attenuazione: quasi inversa del quadrato vicino alla luce, che va a zero al raggio
float attenuation(float distance, float radius)
{
    if (radius <= 0.0 || distance >= radius) return 0.0;
    float x = distance / radius;
    float window = 1.0 - x * x * x * x;
    window *= window;
    float core = radius * 0.3;
    return window / (1.0 + (distance * distance) / (core * core));
}

// luce che conta di piu' in un punto (per le ombre delle sorgenti); -1 se nessuna
int dominantLight(vec3 p)
{
    int best = -1;
    float strongest = 0.02;
    int count = lightCount();
    for (int i = 0; i < count; i++)
    {
        PointLight light = lightAt(i);
        float w = attenuation(length(light.position - p), light.radius) * luma(light.color);
        if (w > strongest)
        {
            strongest = w;
            best = i;
        }
    }

    return best;
}
