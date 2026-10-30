#version 450
// SPDX-License-Identifier: GPL-3.0-or-later
// Dan's Curse V2 - composizione: illuminazione, acqua, nebbia
// Basato su Dan's Curse di flaffymg, modificato con il permesso dell'autore.
// Author (V2): https://github.com/Leproide - licenza delle modifiche: GPL-3.0-or-later
//
// Differenze dalla V1:
//  - la luce del gioco (gia' nei colori) viene modulata invece di essere sostituita
//    (DC_RELIGHT), cosi' le zone scure non diventano fango;
//  - ombre e occlusione arrivano dal pass Occlusion, filtrate nel tempo;
//  - in lontananza resta la luce diffusa: sparisce solo il dettaglio (ombre, occlusione);
//  - nebbia: colore stabile, densita' interno/esterno piu' morbida, foschia a terra legata
//    al pavimento con il suo integrale lungo il raggio e banchi in movimento, luce della
//    luna e aloni delle sorgenti di luce dentro la nebbia, nebbia del cielo in base alla
//    direzione di vista e non alla posizione sullo schermo.

#include "common.inc"

layout(set = 0, binding = 2) uniform sampler2D Geometry;
layout(set = 0, binding = 3) uniform sampler2D Sky;
layout(set = 0, binding = 4) uniform sampler2D Glow;
layout(set = 0, binding = 5) uniform sampler2D Original;
layout(set = 0, binding = 6) uniform sampler2D SceneLights;
layout(set = 0, binding = 7) uniform sampler2D Shafts;
layout(set = 0, binding = 8) uniform sampler2D Occlusion;
layout(set = 0, binding = 9) uniform sampler2D LightShadow;

#include "vertex.inc"
#include "lights.inc"

const vec3 WARM_LIGHT = vec3(1.0, 0.86, 0.68);
const vec3 COOL_LIGHT = vec3(0.70, 0.85, 1.0);
const float GLOW_GAIN = 8.0;
const float DETAIL_NEAR = 3000.0;
const float DETAIL_FAR = 9000.0;
const float SPECULAR = 0.15;
const float GLOSS = 24.0;
const vec3 WATER_COLOR = vec3(0.007, 0.024, 0.03);
const vec3 WATER_ABSORB = vec3(1.0, 0.42, 0.3) / 100.0;
const float WATER_DEEP = 2000.0;
const float WAVE_SCALE = 0.018;
const float WAVE_HEIGHT = 0.55;
const float WAVE_DRAG = 0.38;
const int WAVE_ITERATIONS = 10;
const float WATER_TEXTURE_BLEND = 0.4;
const float WATER_REFRACT = 0.035;

struct Surface
{
    vec3 normal;
    float ao;
    float enclosure;
    float shadow;
};

// media 3x3 pesata sulla profondita' di normali e risultati del pass Occlusion
Surface gather(vec2 uv, float z)
{
    vec2 texel = global.GeometrySize.zw;
    vec3 normal = vec3(0.0);
    vec3 occlusion = vec3(0.0);
    float weights = 0.0;
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++)
    {
        vec2 suv = uv + vec2(x, y) * texel * 2.0;
        float sd = depthAt(suv);
        if (!hasGeometry(sd)) continue;
        float w = 1.0 / (1.0 + abs(viewZ(sd) - z) / (z * 0.01));
        normal += decodeNormal(texture(Geometry, suv).rg) * w;
        occlusion += texture(Occlusion, suv).xyz * w;
        weights += w;
    }

    Surface surface;
    if (weights <= 0.0)
    {
        surface.normal = decodeNormal(texture(Geometry, uv).rg);
        surface.ao = 1.0;
        surface.enclosure = 1.0;
        surface.shadow = 1.0;
        return surface;
    }

    occlusion /= weights;
    surface.normal = normalize(normal);
    surface.ao = occlusion.x;
    surface.enclosure = occlusion.y;
    surface.shadow = occlusion.z;
    return surface;
}

// Luci puntiformi: diffusa con il lato rivolto alla luce, riflesso speculare, ombra della
// luce dominante (pass LightShadow) e tremolio del fuoco. Nella V1 e nelle prime V2 la luce
// era un alone piatto (25% fisso, nessun riflesso) compresso verso 1: le zone illuminate
// erano solo un po' piu' chiare.
struct LocalLight
{
    vec3 diffuse;
    vec3 shine;
};

LocalLight sceneLights(vec3 p, vec3 n, vec3 v, vec2 uv)
{
    LocalLight result;
    result.diffuse = vec3(0.0);
    result.shine = vec3(0.0);
    int count = lightCount();
    if (count == 0 || global.DC_SCENE_LIGHTS <= 0.0) return result;

    vec4 shadowData = texture(LightShadow, uv);
    int shadowed = global.DC_LIGHT_SHADOWS > 0.0 ? dominantLight(p) : -1;
    float shadow = mix(1.0, shadowData.x, global.DC_LIGHT_SHADOWS);

    for (int i = 0; i < count; i++)
    {
        PointLight light = lightAt(i);
        vec3 toLight = light.position - p;
        float distance = length(toLight);
        float falloff = attenuation(distance, light.radius);
        if (falloff <= 0.0) continue;

        vec3 l = toLight / max(distance, 1e-3);
        float ndl = clamp((dot(n, l) + 0.1) / 1.1, 0.0, 1.0);
        vec3 h = normalize(l + v);
        float spec = pow(max(dot(n, h), 0.0), 28.0) * ndl;
        float energy = falloff * flicker(light) * (i == shadowed ? shadow : 1.0);

        result.diffuse += light.color * energy * ndl;
        result.shine += light.color * energy * spec;
    }

    result.diffuse *= global.DC_SCENE_LIGHTS;
    result.shine *= global.DC_SCENE_LIGHTS * global.DC_LIGHT_SHINE;
    // compressione morbida: molte luci vicine non bruciano, una sola resta forte
    result.diffuse /= 1.0 + luma(result.diffuse) * 0.35;
    return result;
}

bool hasWaterLevel()
{
    return global.SceneWaterLevel.y > 0.5 && global.CameraAvailable > 0.5;
}

float levelThickness(vec3 p)
{
    float level = waterLevelY();
    float target = toWorld(p).y;
    float eye = global.CameraTranslation.y;
    if (target <= level) return 0.0;
    if (eye >= level) return 0.0;
    return length(p) * (target - level) / max(target - eye, 1e-3);
}

float thicknessAt(vec2 uv, vec3 p)
{
    float bottom = rawDepth(uv);
    if (!hasGeometry(bottom)) return WATER_DEEP;
    vec3 b = viewPos(uv, bottom);
    return hasWaterLevel() ? levelThickness(b) : max(length(b) - length(p), 0.0);
}
float waterThickness(vec3 p)
{
    return thicknessAt(vTexCoord, p);
}
bool inWater(vec3 p)
{
    return hasWaterLevel() ? waterThickness(p) > 0.0 : isWater(vTexCoord);
}
// wavedx/getwaves adapted from 'Very fast procedural ocean"
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift)
{
    float x = dot(direction, position) * frequency + timeshift;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

float getwaves(vec2 position)
{
    float wavePhaseShift = length(position) * 0.1;
    float iter = 0.0;
    float frequency = 1.0;
    float timeMultiplier = 2.0;
    float weight = 1.0;
    float sumOfValues = 0.0;
    float sumOfWeights = 0.0;
    for (int i = 0; i < WAVE_ITERATIONS; i++)
    {
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, frequency, seconds() * timeMultiplier + wavePhaseShift);
        position += p * res.y * weight * WAVE_DRAG;
        sumOfValues += res.x * weight;
        sumOfWeights += weight;
        weight = mix(weight, 0.0, 0.2);
        frequency *= 1.18;
        timeMultiplier *= 1.07;
        iter += 1232.399963;
    }

    return sumOfValues / sumOfWeights;
}

vec3 waveNormal(vec2 xz)
{
    vec2 pos = xz * WAVE_SCALE;
    float e = 0.05;
    float depth = WAVE_HEIGHT * global.DC_WATER_WAVES;
    float h = getwaves(pos) * depth;
    vec3 a = vec3(pos.x, h, pos.y);
    vec3 n = normalize(cross(a - vec3(pos.x - e, getwaves(pos - vec2(e, 0.0)) * depth, pos.y),
                             a - vec3(pos.x, getwaves(pos + vec2(0.0, e)) * depth, pos.y + e)));
    return vec3(n.x, -abs(n.y), n.z);
}

float caustics(vec2 xz)
{
    float t = seconds() * 0.7;
    vec2 p = xz * 0.012;
    float c = 0.0;
    for (int i = 0; i < 3; i++)
    {
        vec2 q = p * (1.0 + float(i) * 0.6) + vec2(t * (0.3 + float(i) * 0.12), -t * 0.21);
        vec2 cell = abs(sin(q + sin(q.yx * 1.7 + t)));
        c += pow(1.0 - min(cell.x, cell.y), 8.0);
    }

    return c / 3.0;
}
vec3 shadeWater(vec3 color, vec3 lighting, vec3 p, vec3 l, vec3 moonlight, vec3 ambient, vec3 fallback)
{
    vec3 original = color;
    vec3 world = global.CameraAvailable > 0.5 ? toWorld(p) : p;
    vec3 normalWorld = waveNormal(world.xz);
    vec3 n = global.CameraAvailable > 0.5 ? normalize(toView(normalWorld)) : normalize(normalWorld);
    vec3 v = -normalize(p);
    if (dot(n, v) < 0.0) n = -n;

    float thickness = waterThickness(p);
    vec2 shift = (n.xy - dot(n, v) * v.xy) * WATER_REFRACT * clamp(thickness / 120.0, 0.0, 1.0) / (1.0 + p.z * 0.0004);
    vec2 refracted = vTexCoord + shift;
    float refractedDepth = rawDepth(refracted);
    if (!onScreen(refracted) || isOverlay(refractedDepth) || (hasGeometry(refractedDepth) && viewZ(refractedDepth) < p.z))
        refracted = vTexCoord;
    else thickness = thicknessAt(refracted, p);

    vec3 bottom = refracted == vTexCoord ? color : toLinear(texture(Original, refracted).rgb) * lighting;
    float bottomDepth = rawDepth(refracted);
    if (hasGeometry(bottomDepth) && global.CameraAvailable > 0.5)
    {
        vec3 floorWorld = toWorld(viewPos(refracted, bottomDepth));
        float below = hasWaterLevel() ? max(floorWorld.y - waterLevelY(), 0.0) : thickness * 0.5;
        bottom += bottom * moonlight * caustics(floorWorld.xz) * exp(-below * 0.012) * global.DC_WATER_CAUSTICS * 2.0;
    }

    vec3 transmit = exp(-thickness * WATER_ABSORB * global.DC_WATER_DENSITY);
    vec3 scatter = WATER_COLOR * (ambient + moonlight * 0.35);
    vec3 volume = bottom * transmit + scatter * (1.0 - transmit);

    float facing = max(dot(n, v), 0.0);
    float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);
    vec3 r = reflect(-v, n);
    vec3 sky = fallback * 0.7 + moonlight * 0.02;
    color = mix(volume, sky, clamp(max(fresnel * 1.4, 0.03), 0.0, 1.0) * global.DC_WATER_REFLECT);
    float glint = max(dot(r, l), 0.0);
    color += moonlight * (pow(glint, 24.0) * 0.06 + pow(glint, 600.0) * 1.6) * global.DC_WATER_REFLECT;
    //rr?
    float shore = 1.0 - smoothstep(0.0, 22.0, thickness);
    float foam = smoothstep(0.55, 0.85, valueNoise(world.xz * 0.06 + vec2(seconds() * 0.2, 0.0)) * (0.6 + 0.4 * shore));
    color += (ambient + moonlight * 0.25) * vec3(0.5, 0.6, 0.6) * foam * shore * 0.25;
    return waterMask(vTexCoord) || translucentAt(vTexCoord) ? mix(color, original, WATER_TEXTURE_BLEND) : color;
}

// ---------------------------------------------------------------- nebbia

// raggio di vista nel mondo (Y verso il basso)
vec3 worldRay(vec3 viewDir)
{
    return global.CameraAvailable > 0.5 ? normalize(toWorldDirection(viewDir)) : vec3(viewDir.x, -viewDir.y, viewDir.z);
}

// quota del pavimento (pass Sky); senza dati si assume un pavimento sotto la telecamera
float floorLevel()
{
    vec4 ground = texture(Sky, GROUND_TEXEL);
    return ground.y > 0.5 ? ground.x : global.CameraTranslation.y + 400.0;
}

// banchi di foschia: rumore sul piano, trascinato lentamente
float mistPatches(vec3 world)
{
    if (global.DC_MIST_NOISE <= 0.0) return 1.0;
    vec2 drift = vec2(seconds() * 18.0, seconds() * 7.0) * global.DC_MIST_SPEED;
    float n = fbm((world.xz + drift) * 0.0011 + world.y * 0.0004);
    return mix(1.0, 0.25 + 1.5 * n, global.DC_MIST_NOISE);
}

// foschia a terra: densita' esponenziale sopra il pavimento, integrata lungo il raggio
// dalla telecamera al punto (forma chiusa), modulata dai banchi.
float mist(vec3 ray, float dist)
{
    if (global.CameraAvailable < 0.5 || global.DC_GROUND_FOG <= 0.0) return 0.0;
    float k = 1.0 / max(global.DC_GROUND_HEIGHT, 1.0);
    float level = floorLevel();
    vec3 eye = global.CameraTranslation.xyz;
    vec3 target = eye + ray * dist;

    float he = max(level - eye.y, 0.0);
    float hp = max(level - target.y, 0.0);
    float fe = exp(-he * k);
    float fp = exp(-hp * k);
    float dh = (hp - he) * k;
    float average = abs(dh) > 1e-3 ? (fe - fp) / dh : fe;

    // la foschia comincia a DC_MIST_START: intorno al personaggio l'aria resta pulita
    float through = max(dist - global.DC_MIST_START, 0.0);
    float patches = 0.5 * (mistPatches(eye + ray * min(dist, 1800.0) * 0.5) + mistPatches(target));
    float optical = average * through * global.DC_GROUND_FOG * 0.0006 * patches;
    return 1.0 - exp(-optical);
}

// aloni delle sorgenti di luce attraversate dal raggio (luci in coordinate di vista)
vec3 lightHalos(vec3 dir, float dist)
{
    if (global.DC_FOG_LIGHTS <= 0.0) return vec3(0.0);
    vec3 sum = vec3(0.0);
    int count = lightCount();
    for (int i = 0; i < count; i++)
    {
        PointLight light = lightAt(i);
        // alone stretto attorno alla luce (un quarto del suo raggio d'azione)
        float radius = light.radius * 0.25;
        if (radius <= 0.0) continue;
        float t = clamp(dot(light.position, dir), 0.0, dist);
        float miss = length(light.position - dir * t);
        float halo = max(1.0 - miss / radius, 0.0);
        sum += light.color * halo * halo * halo * flicker(light);
    }

    sum *= global.DC_FOG_LIGHTS * 0.15;
    return sum / (1.0 + luma(sum));
}

struct Fog
{
    float amount;
    vec3 color;
    vec3 halos;
};

Fog computeFog(vec3 dir, float dist, bool sky, float indoor, vec3 fogColor, vec3 moonlight, vec3 l)
{
    Fog f;
    vec3 ray = worldRay(dir);

    // nebbia di distanza lineare: 0 a DC_FOG_START, DC_FOG (opacita' massima) a DC_FOG_END
    float cave = indoor * global.DC_CAVE;
    float start = global.DC_FOG_START * mix(1.0, 0.85, cave);
    if (global.SceneFogRange.y > global.SceneFogRange.x)
        start = mix(start, min(start, global.SceneFogRange.x), global.DC_GAME_LIGHT);
    float end = max(global.DC_FOG_END * mix(1.0, 0.85, cave), start + 100.0);
    float distanceFog = clamp((dist - start) / (end - start), 0.0, 1.0) * global.DC_FOG;
    float haze = (1.0 - exp(-max(dist - global.DC_MIST_START, 0.0) * 0.00005)) * global.DC_HAZE;
    float amount = max(distanceFog, haze);

    // Limite di disegno: il gioco disegna il terreno a blocchi fino a una certa distanza e
    // nasconde il taglio sfumando al nero. Con una nebbia chiara i bordi dei blocchi e il
    // vuoto dietro diventano figure squadrate: qui la geometria vicina al limite e il vuoto
    // sotto l'orizzonte arrivano allo stesso colore della nebbia. Solo se sullo schermo c'e'
    // del vuoto (scene aperte): in una stanza chiusa i muri in fondo non vanno nascosti.
    vec4 extent = texture(Sky, SCENE_TEXEL);
    float open = smoothstep(0.02, 0.1, extent.y) * global.DC_FOG_EDGE;
    float far = extent.x;
    if (!sky && far > 500.0)
        amount = max(amount, smoothstep(far * 0.82, far * 0.99, dist) * open);

    if (sky)
    {
        // cielo: poca nebbia in alto, piena verso l'orizzonte e nel vuoto sotto di esso
        float up = -ray.y;
        float horizon = 1.0 - smoothstep(-0.02, 0.3, up);
        amount = mix(global.DC_FOG_SKY * 0.3, max(global.DC_FOG_SKY, open), horizon);
    }

    float ground = mist(ray, sky ? 6000.0 : dist);
    f.amount = clamp(amount + ground * (1.0 - amount), 0.0, 1.0);

    // luce nella nebbia: la luna la schiarisce quando la si guarda di fronte
    float toward = phaseToward(dot(dir, l), 0.6);
    f.color = fogColor + moonlight * (0.015 + toward * 0.06) * global.DC_FOG_MOON;
    f.halos = lightHalos(dir, sky ? 6000.0 : dist) * (0.15 + 0.85 * max(f.amount, haze * 2.0));
    return f;
}

void main()
{
    vec3 color = toLinear(sceneUnderUi(texture(Original, vTexCoord).rgb, uiLayer(vTexCoord)));
    float d = depthAt(vTexCoord);
    vec4 extent = texture(Sky, SCENE_TEXEL);
    if (isOverlay(d) || extent.z < 0.01)
    {
        FragColor = vec4(color, 0.0);
        return;
    }

    vec4 skyData = texture(Sky, SKY_TEXEL);
    vec3 sky = skyData.rgb;
    float indoor = 1.0 - clamp(skyData.a * 2.0 - 1.0, 0.0, 1.0);
    vec3 fogColor = curseFog(texture(Sky, FOG_TEXEL).rgb) * mix(1.0, 0.6, indoor * global.DC_CAVE);
    vec3 glow = texture(Glow, vTexCoord).rgb * global.DC_GLOW * GLOW_GAIN;
    glow /= 1.0 + luma(glow);

    vec3 moonlight = mix(COOL_LIGHT, WARM_LIGHT, global.DC_LIGHT_WARMTH) * global.DC_SUN_STRENGTH;
    float dust = (0.4 + 0.6 * indoor) * (0.6 + min(global.DC_FOG, 1.5));
    vec3 beams = texture(Shafts, vTexCoord).r * moonlight * global.DC_SHAFTS * dust * 0.5;
    vec3 l = sunDir();

    if (!hasGeometry(d))
    {
        vec3 dir = normalize(vec3((vTexCoord - global.Projection.zw) * global.Projection.xy, 1.0));
        Fog f = computeFog(dir, 6000.0, true, indoor, fogColor, moonlight, l);
        float toward = max(dot(dir, l), 0.0);
        float scatter = pow(toward, 6.0) * 0.35 + pow(toward, 48.0) * 0.6;
        color = mix(color, f.color + glow * 0.03, f.amount) + f.halos;
        FragColor = vec4(color + moonlight * scatter * global.DC_SHAFTS * 0.12 + beams * 0.55, 1.0);
        return;
    }

    vec3 tint = clamp(sky / max(luma(sky), 1e-4), vec3(0.5), vec3(1.6));
    tint = mix(vec3(1.0), tint / max(luma(tint), 1e-4), 0.25);
    if (global.SceneAmbient.w > 0.5 && luma(global.SceneAmbient.rgb) > 0.0)
    {
        vec3 ambientTint = global.SceneAmbient.rgb / max(luma(global.SceneAmbient.rgb), 1e-4);
        tint = mix(tint, clamp(ambientTint, vec3(0.4), vec3(1.8)), global.DC_GAME_LIGHT * 0.4);
    }

    tint = mix(tint, CURSE_TINT / luma(CURSE_TINT), global.DC_CURSE * 0.35);

    vec3 albedo = color;
    vec3 p = viewPos(vTexCoord, d);
    vec3 v = -normalize(p);
    Surface surface = gather(vTexCoord, p.z);
    vec3 n = surface.normal;
    float detail = 1.0 - smoothstep(DETAIL_NEAR, DETAIL_FAR, p.z);

    float ao = clamp(mix(1.0, surface.ao, global.DC_AO * detail), 0.0, 1.0);
    float enclosure = clamp(mix(1.0, surface.enclosure, global.DC_AO * detail), 0.0, 1.0);
    float skylight = clamp(mix(1.0, enclosure, 0.7) * (1.0 - indoor * global.DC_CAVE), 0.0, 1.0);
    float skylightSqr = skylight * skylight;

    // in lontananza si perdono solo ombre e occlusione, non la luce diffusa
    float diffuse = smoothstep(-0.1, 0.7, dot(n, l));
    float shadow = mix(1.0, surface.shadow, global.DC_SHADOW * detail);
    float sunlit = diffuse * shadow;

    vec3 lightColor = mix(COOL_LIGHT, WARM_LIGHT, global.DC_LIGHT_WARMTH);
    if (gameLight())
    {
        vec3 game = global.SceneSunColor.rgb / max(luma(global.SceneSunColor.rgb), 1e-4);
        lightColor = mix(lightColor, clamp(game, vec3(0.3), vec3(2.0)), global.DC_GAME_LIGHT * 0.5);
    }

    float facing = dot(n, worldUp()) * 0.5 + 0.5;
    vec3 ambient = global.DC_AMBIENT * tint * mix(0.6, 1.0, facing);
    vec3 sun = global.DC_SUN_STRENGTH * mix(lightColor, lightColor * tint, 0.3);
    vec3 scene = mix(ambient, sun, sunlit) * skylightSqr;

    if (global.SceneFillDirection.w > 0.5 && global.CameraAvailable > 0.5)
    {
        vec3 fill = normalize(toView(global.SceneFillDirection.xyz));
        vec3 fillColor = global.SceneFillColor.rgb / max(luma(global.SceneFillColor.rgb), 1e-4);
        scene += clamp(fillColor, vec3(0.0), vec3(2.0)) * max(dot(n, fill), 0.0) * 0.25 * global.DC_AMBIENT * global.DC_GAME_LIGHT * skylightSqr;
    }

    vec3 interior = mix(vec3(1.0), CURSE_TINT, global.DC_CURSE * 0.5) * mix(1.0, 0.4, global.DC_CAVE) * (1.0 - skylightSqr);
    LocalLight lamps = sceneLights(p, n, v, vTexCoord);
    vec3 local = lamps.diffuse + glow * mix(1.0, 1.6, indoor);
    vec3 lighting = (scene + interior) * ao + local * mix(1.0, ao, 0.5);

    // modulazione: 1 = luce media della scena. 0.5 tiene la stessa esposizione della V1.
    float neutral = max(luma(mix(vec3(global.DC_AMBIENT), global.DC_SUN_STRENGTH * lightColor, 0.55)), 0.05);
    vec3 relight = mix(vec3(1.0), lighting / neutral, global.DC_RELIGHT) * 0.5;
    color *= relight;

    vec3 h = normalize(l + v);
    float specular = pow(max(dot(n, h), 0.0), GLOSS) * SPECULAR * global.DC_SPECULAR * 4.0;
    color += sun * specular * sunlit * skylightSqr * luma(color);

    // luci puntiformi: riflesso e una parte additiva oltre la modulazione, cosi' vicino
    // alle fiamme le superfici si scaldano davvero e il bloom si accende
    color += lamps.shine * (0.25 + luma(albedo)) * ao;
    color += lamps.diffuse * albedo * global.DC_LIGHT_HOT * 0.6 * ao;

    if (inWater(p)) color = shadeWater(color, relight, p, l, moonlight, ambient, fogColor + sky * 0.5);

    float darkness = 1.0 - smoothstep(0.0, 0.35, luma(relight - local / neutral * 0.5 * global.DC_RELIGHT));
    color = mix(color, luma(color) * CURSE_TINT / luma(CURSE_TINT),
                darkness * global.DC_DESATURATION * 0.6);

    float dist = length(p);
    Fog f = computeFog(-v, dist, false, indoor, fogColor, moonlight, l);
    color = mix(color, f.color + glow * 0.08, f.amount) + f.halos;
    color += beams * (0.3 + 0.7 * f.amount);

    if (global.DC_WATER_DEBUG > 0.5)
    {
        if (global.DC_WATER_DEBUG < 1.5) color = waterMask(vTexCoord) ? (isWater(vTexCoord) ? vec3(1.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0)) : color * 0.3;
        else color = inWater(p) ? vec3(1.0 - exp(-waterThickness(p) / 300.0)) : color * 0.1;
    }

    FragColor = vec4(color, 1.0);
}
