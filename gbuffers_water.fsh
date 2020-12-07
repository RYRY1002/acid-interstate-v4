/*
 _______ _________ _______  _______  _
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _
\_______)   )_(   (_______)|/       (_)

This shader is for use with the Optifine Mod. This shader will not work correctly when used with the GLSL Shaders Mod.
This shader was orignally made by MiningGodBruce, and modified heavily by RYRY1002.

Make sure to follow our license when copying, modifying, merging, publishing and/or distributing our work.
(See our license at https://github.com/RYRY1002/acid-interstate-v2/blob/main/LICENSE.md)

This shader is super broken, and should not be used for normal play.
I'm not going to help you if you can't get this shader to work, because I don't care.

If you want to make a video using this shader, go for it!
I'm not going to tell you how, but I'm happy for you to make something with it.

Thanks to [MiningGodBruce](https://www.youtube.com/user/MiningGodBruce) (BruceKnowsHow)
For helping me fix some bugs, and creating the shader that this shader is based on and inspire me to continue developing this video. 

I'd appreciate if you shared the original video, it's cool when people enjoy it.

Also check out my stuff, I'd appreciate it.
https://links.riley.technology/

*/

#version 450 compatibility


#define TILE_RESOLUTION 128

//#define PARALLAX
#define PARALLAX_DISTANCE 10.0

#define WAVE_HEIGHT 0.15


uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float far;

in mat3 tbnMatrix;

in vec4 shadowPosition;
in vec4 vertPosition;
in vec4 color;

in vec3 playerSpacePosition;
in vec3 preAcidWorldPosition;
in vec3 worldPosition;
in vec3 vertNormal;

in vec2 texcoord;
in vec2 mcLightmap;

in float materialIDs;
in float collapsedMaterialIDs;
in float fogEnabled;
in float waterMask;
in float entityID;
in float left;
in float right;

in float topBound;
in float bottomBound;
in float leftBound;
in float rightBound;

const float bump_distance = 78.0;

#define FRAME_TIME 0.0

/* DRAWBUFFERS:21035 */


vec2 textureSmooth(in vec2 coord) {
	vec2 res = vec2(64.0);

	coord *= res;
	coord += 0.5;

	vec2 whole = floor(coord);
	vec2 part  = fract(coord);

	part.x = part.x * part.x * (3.0 - 2.0 * part.x);
	part.y = part.y * part.y * (3.0 - 2.0 * part.y);

	coord = whole + part;

	coord -= 0.5;
	coord /= res;

	return coord;
}

float GetWave(in float weight, inout float weights, in vec2 coord) {
	weights += weight;
	coord = textureSmooth(coord);
	return texture2D(noisetex, coord).x * weight;
}

float GetWaves(vec3 position, in float scale) {
	float speed	= 0.9;

	vec2 p		= position.xz / 20.0;
		 p.xy	-= position.y / 20.0;
		 p.x	*= -1.0;
		 p.x	+= (FRAME_TIME / 40.0) * speed;
		 p.y	-= (FRAME_TIME / 40.0) * speed;

	float waves = 0.0;
	float weights = 0.0;

	waves += GetWave(1.0, weights, p * vec2(2.0, 1.2) + vec2(0.0, p.x * 2.1));

	p /= 2.1;
	p.y -= (FRAME_TIME / 50.0) * speed;
	p.x -= (FRAME_TIME / 30.0) * speed;
	waves += GetWave(2.1, weights, p * vec2(2.0, 1.4) + vec2(0.0, -p.x * 2.1));

	p /= 1.5;
	p.x += (FRAME_TIME / 20.0) * speed;
	waves += abs(GetWave(7.25, weights, p * vec2(1.0, 0.75) + vec2(0.0, p.x * 1.1)));

	p /= 1.3;
	p.x -= (FRAME_TIME / 25.0) * speed;
	waves += GetWave(9.25, weights, p * vec2(1.0, 0.75) + vec2(0.0, -p.x * 1.7));

	waves /= weights;

	float viewAngleFactor = dot(vertNormal, normalize(-(gl_ModelViewMatrix * vertPosition).xyz));
		  viewAngleFactor = pow(viewAngleFactor, 2.0);
		  viewAngleFactor = viewAngleFactor * 20.0 + 0.2;
		  viewAngleFactor = clamp(viewAngleFactor, 0.0, 1.0);

	//waves *= viewAngleFactor;

	return waves;
}

vec3 GetWavesNormal(vec3 position, in float scale, in mat3 tbnMatrix) {
	float waveHeight = WAVE_HEIGHT;

	const float sampleDistance = 3.0;

	position -= vec3(0.005, 0.0, 0.005) * sampleDistance;

	float wavesCenter = GetWaves(position, scale);
	float wavesLeft = GetWaves(position + vec3(0.01 * sampleDistance, 0.0, 0.0), scale);
	float wavesUp   = GetWaves(position + vec3(0.0, 0.0, 0.01 * sampleDistance), scale);

	vec3 wavesNormal;
		 wavesNormal.r = wavesCenter - wavesLeft;
		 wavesNormal.g = wavesCenter - wavesUp;

		 wavesNormal.r *= 30.0 * waveHeight / sampleDistance;
		 wavesNormal.g *= 30.0 * waveHeight / sampleDistance;

		 wavesNormal.b = sqrt(1.0 - wavesNormal.r * wavesNormal.r - wavesNormal.g * wavesNormal.g);
		 wavesNormal.rgb = normalize(wavesNormal.rgb);

	return wavesNormal.rgb;
}

float CollapseMaterialIDs(in float materialIDs, in float bit0, in float bit1, in float bit2, in float bit3) {
	materialIDs += 128.0 * bit0;
	materialIDs +=  64.0 * bit1;
	materialIDs +=  32.0 * bit2;
	materialIDs +=  16.0 * bit3;

	materialIDs += 0.1;
	materialIDs /= 255.0;

	return materialIDs;
}

float CalculateFogFactor(in vec3 position, in float power) {
	float fogFactor = length(position);
		  fogFactor = max(fogFactor - gl_Fog.start, 0.0);
		  fogFactor = pow(fogFactor / (far - gl_Fog.start), power);
		  fogFactor = clamp(fogFactor, 0.0, 1.0);
		  fogFactor *= fogEnabled;
		  fogFactor = clamp(fogFactor, 0.0, 1.0);

	return fogFactor;
}

void CalculateWaterFragment(in vec4 diffuse) {
	float lum = diffuse.r + diffuse.g + diffuse.b;
		  lum /= 3.0;
		  lum = pow(lum, 1.0) * 1.0;
		  lum += 0.0;

	vec3 waterColor = normalize(color.rgb);

	diffuse = vec4(0.1, 0.7, 1.0, 210.0/255.0);
	diffuse.rgb *= 0.8 * waterColor.rgb;
	diffuse.rgb *= vec3(lum);

	vec3 normal = GetWavesNormal(preAcidWorldPosition, 1.0, tbnMatrix) * tbnMatrix * 0.5 + 0.5;
	vec3 specularity = vec3(1.0);

	gl_FragData[0] = diffuse;
	gl_FragData[1] = vec4(collapsedMaterialIDs, mcLightmap.r, mcLightmap.g, 1.0);
	gl_FragData[2] = vec4(normal, 1.0);
	gl_FragData[3] = vec4(specularity.r + specularity.g, specularity.b, 0.0, 1.0);
	gl_FragData[4] = vec4(shadowPosition.xyz / 400.0 + 0.5, 1.0);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;

    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);

    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


bool euclidCheck(in float x, in vec2 y, in vec2 z) {		//returns true for old terrain
	if (worldPosition.x < x && cameraPosition.x < x)
		return true;

	else if (worldPosition.x > x && cameraPosition.x < x) {
		if((atan(playerSpacePosition.x, playerSpacePosition.z) < atan(worldPosition.x - x, worldPosition.z - leftBound))
		|| (atan(playerSpacePosition.x, playerSpacePosition.z) > atan(worldPosition.x - x, worldPosition.z - rightBound))
		|| (atan(playerSpacePosition.x, playerSpacePosition.y) < atan(worldPosition.x - x, worldPosition.y - bottomBound))
		|| (atan(playerSpacePosition.x, playerSpacePosition.y) > atan(worldPosition.x - x, worldPosition.y - topBound)))
			return true;
	} else {
		if((atan(playerSpacePosition.x, playerSpacePosition.z) < atan(worldPosition.x - x, worldPosition.z - leftBound))
		&& (atan(playerSpacePosition.x, playerSpacePosition.z) > atan(worldPosition.x - x, worldPosition.z - rightBound))
		&& (atan(playerSpacePosition.x, playerSpacePosition.y) < atan(worldPosition.x - x, worldPosition.y - bottomBound))
		&& (atan(playerSpacePosition.x, playerSpacePosition.y) > atan(worldPosition.x - x, worldPosition.y - topBound)))
			return true;
	}

	return false;
}

void main() {
	if (CalculateFogFactor(worldPosition.xyz - cameraPosition, 2.0) == 1.0) discard;

	float isInFrustum = 0.0;

	if (cameraPosition.x < 3000.0) {
		if (!euclidCheck(2375.5, vec2(127.5, 130.5), vec2(-0.5, 1.5))) {
			isInFrustum = 1.0;
			if (left > 0.5)
				discard;
		} else if (right > 0.5) discard;
	}

	vec4 color2 = color;
	color2.rgb = rgb2hsv(color2.rgb);
	if ((materialIDs > 1.5 && materialIDs < 2.5) || (entityID > 1.5 && entityID < 2.5) && (color2.g > 0.0)) color2.r = 104.0 / 360.0;
	if ((materialIDs > 1.5 && materialIDs < 2.5) || (entityID > 1.5 && entityID < 2.5) && (color2.g > 0.0)) color2.g = 0.55;
	if ((materialIDs > 1.5 && materialIDs < 2.5) || (entityID > 1.5 && entityID < 2.5) && (color2.g > 0.0)) color2.b = 0.85;
	color2.rgb = hsv2rgb(color2.rgb);
	vec4 diffuse		= texture2D(texture, texcoord) * color2;
	if (waterMask > 0.5) { CalculateWaterFragment(diffuse); return; }
	vec3 normal			= vertNormal * 0.5 + 0.5;
	vec3 specularity	= vec3(0.0);


	gl_FragData[0] = diffuse;
	gl_FragData[1] = vec4(CollapseMaterialIDs(materialIDs, left, right, isInFrustum, 0.0), mcLightmap.r, mcLightmap.g, 1.0);
	gl_FragData[2] = vec4(normal, 1.0);
	gl_FragData[3] = vec4(specularity.r + specularity.g, specularity.b, 0.0, 1.0);
	gl_FragData[4] = vec4(shadowPosition.xyz / 528.0 + 0.5, 1.0);
}
