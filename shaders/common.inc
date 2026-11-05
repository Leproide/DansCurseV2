// SPDX-License-Identifier: GPL-3.0-or-later
//
// Dan's Curse V2 - shader per MediEvilRecomp ITA
// Basato su Dan's Curse di flaffymg (https://github.com/flafmg/DansCurse), modificato con il
// permesso dell'autore. Le modifiche sono rilasciate sotto GPL-3.0-or-later.
// Author (V2): https://github.com/Leproide
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Originale: "the look and lighting model inspired by BSL Shaders, credits should go to the bsl team" (flaffymg)
#pragma parameter DC_GAME_LIGHT "Use game lighting" 0.45 0.0 1.0 0.05
#pragma parameter DC_SUN_YAW "Light direction" 320.0 0.0 360.0 5.0
#pragma parameter DC_SUN_PITCH "Light height" 26.0 5.0 90.0 1.0
#pragma parameter DC_SUN_STRENGTH "Direct light" 0.7 0.0 3.0 0.05
#pragma parameter DC_LIGHT_WARMTH "Light warmth" 0.25 0.0 1.0 0.05
#pragma parameter DC_AMBIENT "Ambient light" 0.2 0.0 1.5 0.05
#pragma parameter DC_SHADOW "Shadows" 0.85 0.0 1.0 0.05
#pragma parameter DC_SHADOW_LENGTH "Shadow length" 210.0 10.0 1000.0 10.0
#pragma parameter DC_SPECULAR "Specular" 0.15 0.0 1.0 0.05
#pragma parameter DC_AO "Ambient occlusion" 1.0 0.0 2.0 0.05
#pragma parameter DC_RELIGHT "Relighting strength" 0.75 0.0 1.0 0.05
#pragma parameter DC_TEMPORAL "Temporal smoothing" 0.85 0.0 0.97 0.01
#pragma parameter DC_AO_RADIUS "AO radius" 75.0 5.0 400.0 5.0
#pragma parameter DC_CURSE "Curse" 0.4 0.0 1.0 0.05
#pragma parameter DC_CAVE "Indoor darkness" 0.6 0.0 1.0 0.05
#pragma parameter DC_DESATURATION "Dark desaturation" 0.4 0.0 1.0 0.05
#pragma parameter DC_SCENE_LIGHTS "Light sources" 1.4 0.0 4.0 0.1
#pragma parameter DC_LIGHT_RANGE "Light source range" 1.15 0.25 4.0 0.05
#pragma parameter DC_LIGHT_SHINE "Light source shine" 0.5 0.0 2.0 0.05
#pragma parameter DC_LIGHT_HOT "Light source heat" 0.7 0.0 2.0 0.05
#pragma parameter DC_FLICKER "Fire flicker" 0.5 0.0 1.0 0.05
#pragma parameter DC_LIGHT_SHADOWS "Light source shadows" 0.6 0.0 1.0 0.05
#pragma parameter DC_GLOW "Emissive glow" 1.6 0.0 4.0 0.1
#pragma parameter DC_GLOW_RADIUS "Emissive glow radius" 1.4 0.5 2.0 0.05
#pragma parameter DC_WATER_DENSITY "Water density" 1.6 0.0 5.0 0.05
#pragma parameter DC_WATER_REFLECT "Water reflections" 0.5 0.0 1.0 0.05
#pragma parameter DC_WATER_WAVES "Water waves" 1.5 0.0 3.0 0.05
#pragma parameter DC_WATER_CAUSTICS "Water caustics" 0.35 0.0 2.0 0.05
#pragma parameter DC_WATER_DEBUG "Water debug" 0.0 0.0 2.0 1.0
#pragma parameter DC_SHAFTS "Moon shafts" 0.2 0.0 3.0 0.05
#pragma parameter DC_SHAFT_LENGTH "Moon shaft length" 0.4 0.1 1.0 0.05
#pragma parameter DC_FOG "Fog" 0.85 0.0 1.0 0.05
#pragma parameter DC_FOG_START "Fog start" 4500.0 0.0 30000.0 100.0
#pragma parameter DC_FOG_END "Fog end" 14000.0 500.0 40000.0 250.0
#pragma parameter DC_FOG_BRIGHT "Fog brightness" 0.08 0.01 0.4 0.01
#pragma parameter DC_HAZE "Base haze" 0.08 0.0 1.0 0.02
#pragma parameter DC_FOG_MOON "Fog moon glow" 0.6 0.0 3.0 0.05
#pragma parameter DC_FOG_LIGHTS "Fog light halos" 0.8 0.0 3.0 0.05
#pragma parameter DC_FOG_EDGE "Draw distance fade" 1.0 0.0 1.0 0.05
#pragma parameter DC_GROUND_FOG "Ground mist" 0.3 0.0 2.0 0.05
#pragma parameter DC_MIST_START "Mist start" 1800.0 0.0 10000.0 100.0
#pragma parameter DC_GROUND_HEIGHT "Ground mist height" 250.0 25.0 2000.0 25.0
#pragma parameter DC_MIST_NOISE "Mist patches" 0.6 0.0 1.0 0.05
#pragma parameter DC_MIST_SPEED "Mist drift" 0.5 0.0 3.0 0.05
#pragma parameter DC_FOG_SKY "Fog over sky" 0.3 0.0 1.0 0.05
#pragma parameter DC_FOG_DEBUG "Draw distance debug" 0.0 0.0 1.0 1.0
#pragma parameter DC_FOG_OFF "Disable fog" 0.0 0.0 1.0 1.0
#pragma parameter DC_FOG_KEEP_DARK "Keep game darkness in fog" 1.0 0.0 1.0 0.05
#pragma parameter DC_BLOOM "Bloom" 0.7 0.0 2.0 0.05
#pragma parameter DC_BLOOM_THRESHOLD "Bloom threshold" 0.7 0.0 1.0 0.05
#pragma parameter DC_EXPOSURE "Exposure" 0.15 -2.0 2.0 0.1
#pragma parameter DC_SATURATION "Saturation" 1.1 0.0 2.0 0.05
#pragma parameter DC_VIBRANCE "Vibrance" 1.1 0.0 2.0 0.05
#pragma parameter DC_VIGNETTE "Vignette" 0.3 0.0 1.0 0.05

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 SourceSize;
    vec4 OutputSize;
    vec4 GeometrySize;
    vec4 DepthSize;
    vec4 Projection;
    vec4 CameraRow0;
    vec4 CameraRow1;
    vec4 CameraRow2;
    vec4 CameraInverseRow0;
    vec4 CameraInverseRow1;
    vec4 CameraInverseRow2;
    vec4 CameraTranslation;
    vec4 PreviousCameraRow0;
    vec4 PreviousCameraRow1;
    vec4 PreviousCameraRow2;
    vec4 PreviousCameraTranslation;
    vec4 SceneSunDirection;
    vec4 SceneSunColor;
    vec4 SceneFillDirection;
    vec4 SceneFillColor;
    vec4 SceneAmbient;
    vec4 SceneFogColor;
    vec4 SceneFogRange;
    vec4 SceneIndoor;
    vec4 SceneWaterPlane;
    vec4 SceneWaterLevel;
    vec4 SceneViewDistance;
    uint FrameCount;
    float Time;
    float PreviousCameraAvailable;
    float DepthAvailable;
    float CameraAvailable;
    float MaterialAvailable;
    float UiLayerAvailable;
    float SceneLightCount;
    float DC_GAME_LIGHT;
    float DC_SUN_YAW;
    float DC_SUN_PITCH;
    float DC_SUN_STRENGTH;
    float DC_LIGHT_WARMTH;
    float DC_AMBIENT;
    float DC_SHADOW;
    float DC_SHADOW_LENGTH;
    float DC_SPECULAR;
    float DC_AO;
    float DC_RELIGHT;
    float DC_TEMPORAL;
    float DC_AO_RADIUS;
    float DC_CURSE;
    float DC_CAVE;
    float DC_DESATURATION;
    float DC_SCENE_LIGHTS;
    float DC_LIGHT_RANGE;
    float DC_LIGHT_SHINE;
    float DC_LIGHT_HOT;
    float DC_FLICKER;
    float DC_LIGHT_SHADOWS;
    float DC_GLOW;
    float DC_GLOW_RADIUS;
    float DC_WATER_DENSITY;
    float DC_WATER_REFLECT;
    float DC_WATER_WAVES;
    float DC_WATER_CAUSTICS;
    float DC_WATER_DEBUG;
    float DC_SHAFTS;
    float DC_SHAFT_LENGTH;
    float DC_FOG;
    float DC_FOG_START;
    float DC_FOG_END;
    float DC_FOG_BRIGHT;
    float DC_HAZE;
    float DC_FOG_MOON;
    float DC_FOG_LIGHTS;
    float DC_FOG_EDGE;
    float DC_GROUND_FOG;
    float DC_GROUND_HEIGHT;
    float DC_MIST_START;
    float DC_MIST_NOISE;
    float DC_MIST_SPEED;
    float DC_FOG_SKY;
    float DC_FOG_DEBUG;
    float DC_FOG_OFF;
    float DC_FOG_KEEP_DARK;
    float DC_BLOOM;
    float DC_BLOOM_THRESHOLD;
    float DC_EXPOSURE;
    float DC_SATURATION;
    float DC_VIBRANCE;
    float DC_VIGNETTE;
} global;

layout(set = 0, binding = 1) uniform sampler2D Depth;
layout(set = 0, binding = 15) uniform sampler2D Material;
layout(set = 0, binding = 14) uniform sampler2D UiLayer;

const float SKY_DEPTH = 0.9999995;
const float OVERLAY_DEPTH = 0.999997;

const int MATERIAL_WATER = 1;
const int MATERIAL_TRANSLUCENT = 255;

// pass Sky (4x1): cielo e apertura, presenza della scena, altezza del pavimento, colore stabile della nebbia
const vec2 SKY_TEXEL = vec2(0.125, 0.5);
const vec2 SCENE_TEXEL = vec2(0.375, 0.5);
const vec2 GROUND_TEXEL = vec2(0.625, 0.5);
const vec2 FOG_TEXEL = vec2(0.875, 0.5);

const vec3 CURSE_FOG = vec3(0.020, 0.034, 0.038);
const vec3 CURSE_TINT = vec3(0.60, 0.82, 0.84);

//new ui layer handling so the ui doesnt FUCK IT ALL UP
vec4 uiLayer(vec2 uv)
{
    return global.UiLayerAvailable > 0.5 ? texture(UiLayer, uv) : vec4(0.0, 0.0, 0.0, 1.0);
}

vec3 sceneUnderUi(vec3 color, vec4 ui)
{
    return ui.a > 0.02 ? clamp((color - ui.rgb) / ui.a, 0.0, 1.0) : color;
}

float rawDepth(vec2 uv)
{
    return texture(Depth, uv).r;
}

bool waterMask(vec2 uv)
{
    return global.MaterialAvailable > 0.5 && int(texture(Material, uv).r * 255.0 + 0.5) == MATERIAL_WATER;
}

bool translucentAt(vec2 uv)
{
    return global.MaterialAvailable > 0.5 && int(texture(Material, uv).r * 255.0 + 0.5) == MATERIAL_TRANSLUCENT;
}

bool hasWaterPlane()
{
    return dot(global.SceneWaterPlane.xyz, global.SceneWaterPlane.xyz) > 0.5;
}

bool isWater(vec2 uv)
{
    return hasWaterPlane() && waterMask(uv);
}

float surfaceDepth(vec2 uv, float raw)
{
    vec3 ray = vec3((uv - global.Projection.zw) * global.Projection.xy, 1.0);
    float facing = dot(global.SceneWaterPlane.xyz, ray);
    if (abs(facing) < 1e-5) return raw;
    float z = global.SceneWaterPlane.w / facing;
    return z > 1.0 ? 1.0 - 1.0 / z : raw;
}

float levelDepth(vec2 uv, float raw);

float depthAt(vec2 uv)
{
    float raw = rawDepth(uv);
    if (global.SceneWaterLevel.y > 0.5 && global.CameraAvailable > 0.5) return levelDepth(uv, raw);
    return isWater(uv) ? surfaceDepth(uv, raw) : raw;
}

bool hasGeometry(float d)
{
    return global.DepthAvailable > 0.5 && d < OVERLAY_DEPTH;
}

bool isOverlay(float d)
{
    return global.DepthAvailable > 0.5 && d >= OVERLAY_DEPTH && d < SKY_DEPTH;
}

float viewZ(float d)
{
    return 1.0 / max(1.0 - d, 1e-7);
}

vec3 viewPos(vec2 uv, float d)
{
    float z = viewZ(d);
    return vec3((uv - global.Projection.zw) * global.Projection.xy * z, z);
}

vec2 project(vec3 p)
{
    return p.xy / (p.z * global.Projection.xy) + global.Projection.zw;
}

bool onScreen(vec2 uv)
{
    return all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)));
}

// credits to: interleaved gradient noise (by Jorge Jimenez)
float noise(vec2 pixel)
{
    return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// come noise(), ma spostato a ogni frame: con l'accumulo temporale il rumore si media
float frameNoise(vec2 pixel)
{
    return noise(pixel + 5.588238 * float(global.FrameCount % 64u));
}

float seconds()
{
    return global.Time > 0.0 ? global.Time : float(global.FrameCount) / 60.0;
}

vec3 toView(vec3 w)
{
    if (global.CameraAvailable < 0.5) return w;
    return vec3(dot(global.CameraRow0.xyz, w), dot(global.CameraRow1.xyz, w), dot(global.CameraRow2.xyz, w));
}

vec3 toWorldDirection(vec3 v)
{
    if (global.CameraAvailable < 0.5) return v;
    return vec3(dot(global.CameraInverseRow0.xyz, v), dot(global.CameraInverseRow1.xyz, v), dot(global.CameraInverseRow2.xyz, v));
}

vec3 toWorld(vec3 p)
{
    return toWorldDirection(p) + global.CameraTranslation.xyz;
}

float waterLevelY()
{
    return global.SceneWaterLevel.x;
}

// water level flag hadnle
float levelDepth(vec2 uv, float raw)
{
    float eye = global.CameraTranslation.y;
    float level = waterLevelY();
    if (eye >= level || isOverlay(raw)) return raw;
    vec3 ray = toWorldDirection(vec3((uv - global.Projection.zw) * global.Projection.xy, 1.0));
    if (ray.y <= 1e-5) return raw;
    float z = (level - eye) / ray.y;
    if (z <= 1.0) return raw;
    return min(raw, 1.0 - 1.0 / z);
}

vec3 worldAt(vec2 uv, float d)
{
    return toWorld(viewPos(uv, d));
}
vec2 previousUv(vec3 world)
{
    if (global.PreviousCameraAvailable < 0.5) return vec2(-1.0);
    vec3 w = world - global.PreviousCameraTranslation.xyz;
    vec3 v = vec3(dot(global.PreviousCameraRow0.xyz, w), dot(global.PreviousCameraRow1.xyz, w), dot(global.PreviousCameraRow2.xyz, w));
    return v.z > 1.0 ? project(v) : vec2(-1.0);
}

bool gameLight()
{
    return global.SceneSunDirection.w > 0.5 && global.CameraAvailable > 0.5 && global.DC_GAME_LIGHT > 0.0;
}

vec3 sunDir()
{
    float yaw = radians(global.DC_SUN_YAW);
    float pitch = radians(global.DC_SUN_PITCH);
    vec3 w = vec3(cos(pitch) * sin(yaw), -sin(pitch), cos(pitch) * cos(yaw));
    vec3 manual = global.CameraAvailable > 0.5 ? toView(w) : vec3(w.xy, -w.z);
    // il fork ITA passa solo il colore della luce del gioco (direzione nulla): si tiene quella manuale
    if (!gameLight() || dot(global.SceneSunDirection.xyz, global.SceneSunDirection.xyz) < 0.25) return normalize(manual);
    return normalize(mix(manual, toView(global.SceneSunDirection.xyz), global.DC_GAME_LIGHT));
}

vec3 worldUp()
{
    return global.CameraAvailable > 0.5 ? normalize(toView(vec3(0.0, -1.0, 0.0))) : vec3(0.0, -1.0, 0.0);
}

float luma(vec3 c)
{
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec2 signNotZero(vec2 v)
{
    return vec2(v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0);
}

vec2 encodeNormal(vec3 n)
{
    vec2 e = n.xy / (abs(n.x) + abs(n.y) + abs(n.z));
    return n.z >= 0.0 ? e : (1.0 - abs(e.yx)) * signNotZero(e);
}

vec3 decodeNormal(vec2 e)
{
    vec3 n = vec3(e, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * signNotZero(n.xy);
    return normalize(n);
}

vec3 toLinear(vec3 c)
{
    return pow(max(c, vec3(0.0)), vec3(2.2));
}

vec3 toGamma(vec3 c)
{
    return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

// Colore della nebbia: colore stabile del cielo (pass Sky), tinta della maledizione e,
// se il gioco lo fornisce, colore della nebbia del livello. La luminosita' e' limitata
// da DC_FOG_BRIGHT (nella V1 era fissa a 0.045 e la nebbia diventava quasi nera).
vec3 curseFog(vec3 sky)
{
    vec3 fog = mix(sky, CURSE_FOG, global.DC_CURSE);
    if (global.SceneFogColor.w > 0.5 && luma(global.SceneFogColor.rgb) > 0.02)
    {
        vec3 hue = toLinear(global.SceneFogColor.rgb);
        hue /= max(luma(hue), 1e-4);
        fog = mix(fog, luma(fog) * clamp(hue, vec3(0.3), vec3(2.0)), global.DC_GAME_LIGHT * 0.5);
    }

    float brightness = luma(fog);
    float limit = global.DC_FOG_BRIGHT;
    if (brightness > limit) fog *= limit / brightness;
    else if (brightness < limit * 0.15) fog = mix(fog, CURSE_FOG / luma(CURSE_FOG) * limit * 0.15, 0.5);
    return fog;
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// due ottave, valori 0..1
float fbm(vec2 p)
{
    return valueNoise(p) * 0.65 + valueNoise(p * 2.13 + vec2(17.3, 5.1)) * 0.35;
}

// fase di Henyey-Greenstein normalizzata: 1 guardando verso la luce
float phaseToward(float cosTheta, float g)
{
    float g2 = g * g;
    float hg = (1.0 - g2) / pow(max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4), 1.5);
    return hg * (1.0 - g) * (1.0 - g) / (1.0 + g);
}
