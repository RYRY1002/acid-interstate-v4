/*
 _______ _________ _______  _______  _
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _
\_______)   )_(   (_______)|/       (_)

This shader is for use with the Optifine Mod. This shdaer will not work correctly when used with the GLSL Shaders Mod.
This shdaer was orignally made by MiningGodBruce, and modified heavily by RYRY1002.

This shader is super broken, and should not be used for normal play.
I'm not going to help you if you can't get this shader to work, because I don't care.

If you want to make a video using this shader, go for it!
I'm not going to tell you how, but I'm happy for you to make something with it.

Thanks to MiningGodBruce (BruceKnowsHow)
For helping me fix some bugs, and creating the shader that this shader is based on and inspire me to continue developing this video.

I'd appreciate if you shared the original video, it's cool when people enjoy it.

Also check out my stuff, I'd appreciate it.
https://links.riley.technology/

*/

#version 450 compatibility


#define SHADOW_MAP_BIAS 0.8
#define CUSTOM_TIME_CYCLE

#define gbuffers_shadow true

/*
attribute vec4 mc_Entity
attribute vec4 at_tangent*/ in vec4 mc_Entity; in vec4 at_tangent;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

#define track cameraPosition.x
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float frameTimeCounter;
uniform float sunAngle;
uniform float far;

out vec4 shadowPosition;
out vec4 vertPosition;
out vec4 color;

out vec3 playerSpacePosition;
out vec3 preAcidWorldPosition;
out vec3 worldPosition;
out vec3 vertNormal;
out vec3 shadowNormal;
out vec3 tangent;
out vec3 binormal;

out vec2 texcoord;
out vec2 mcLightmap;

out float vertDistance;
out float materialIDs;
out float collapsedMaterialIDs;
out float fogEnabled;
out float waterMask;
out float entityID;
out float left;
out float right;
out float portal;
out float pre;
out float post;

out vec3 topLeft;
out vec3 topRight;
out vec3 bottomRight;
out vec3 bottomLeft;

mat4 shadowView;
mat4 shadowViewInverse;

float timeCycle;
float timeAngle;
float pathRotationAngle;
float twistAngle;

const float sunPathRotation = -40.0;
const float PI = 3.1415926535;
const float rad = 0.01745329;

const float gateTop		= 129.0;
const float gateBottom	= 127.0;
const float gateLeft	= -0.0;
const float gateRight	= 1.0;


vec2 GetLightmap() {							//Gets the lightmap from the default lighting engine. First channel is torch lightmap, second channel is sky lightmap.
	vec2 lightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
		 lightmap = clamp((lightmap * 33.05 / 32.0) - 1.05 / 32.0, 0.0, 1.0);

	return lightmap;
}

vec4 GetWorldSpacePosition() {
	return shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
}

vec4 WorldSpaceToShadowProjection(in vec4 worldSpacePosition) {
	return shadowProjection * shadowView * worldSpacePosition;
}

vec4 BiasShadowProjection(in vec4 projectedShadowSpacePosition) {
	vec2 pos = abs(projectedShadowSpacePosition.xy * 1.165);
	float dist = pow(pow(pos.x, 8) + pow(pos.y, 8), 1.0 / 8.0);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;

	projectedShadowSpacePosition.xy /= distortFactor;

	projectedShadowSpacePosition.z += pow(max(0.0, 1.0 - dot(shadowNormal, vec3(0.0, 0.0, 1.0))), 4.0) * 0.0125;
	projectedShadowSpacePosition.z += 0.0044 * (dist + 0.1);
	projectedShadowSpacePosition.z /= 4.0;

	return projectedShadowSpacePosition;
}

float GetMaterialIDs() {						//Gather materials
	float materialID;

	switch(int(mc_Entity.x)) {
		case 31:								//Tall Grass
		case 37:								//Dandelion
		case 38:								//Rose
		case 59:								//Wheat
		case 83:								//Sugar Cane
		case 106:								//Vine
		case 175:								//Double Tall Grass
		case 1920:								//Biomes O Plenty: Thorns, barley
		case 1921:								//Biomes O Plenty: Sunflower
		case 1925:								//Biomes O Plenty: Medium Grass
					materialID = 2.0; break;	//Translucent blocks
		case 18:								//Leaves
		case 161:								//Biomes O Plenty: Giant Flower Leaves
		case 1923:								//Biomes O Plenty: Leaves
		case 1924:								//Biomes O Plenty: Leaves
		case 1926:								//Biomes O Plenty: Leaves
		case 1936:								//Biomes O Plenty: Giant Flower Leaves
		case 1962:								//Biomes O Plenty: Leaves
					materialID = 3.0; break;	//Leave
		case 8:
		case 9:
					materialID = 4.0; break;	//Water
		case 79:	materialID = 5.0; break;	//Ice
		case 41:	materialID = 6.0; break;	//Gold block
		case 50:	materialID = 7.0; break;	//Torch
		case 10:
		case 11:	materialID = 8.0; break;	//Lava
		case 89:
		case 124:	materialID = 9.0; break;	//Glowstone and Lamp
		case 51:	materialID = 10.0; break;	//Fire
		case 45:	materialID = 11.0; break;	//Fire
		default:	materialID = 1.0;
	}

	return materialID;
}

void OptifineGlowstoneFix(inout vec3 color) {
	if ((gl_Normal.x < -0.5 || gl_Normal.x > 0.5) && materialIDs == 9.0)
		color *= 1.75;
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

void rotateRad(inout vec2 vector, float degrees) {
	degrees *= rad;

	vector *= mat2(cos(degrees), -sin(degrees),
				   sin(degrees),  cos(degrees));
}

#include "include/animation.glsl"

void rotate(inout vec2 vector, float radians) {
	vector *= mat2(cos(radians), -sin(radians),
				   sin(radians),  cos(radians));
}

#include "include/CalculateShadowView.glsl"


vec2 GetCoord(in vec2 coord)
{
	ivec2 atlasResolution = ivec2(64, 32);
	coord *= atlasResolution;
	coord = mod(coord, vec2(1.0));

	return coord;
}

void acid(inout vec3 position, in vec3 worldPosition) {
	position.y -= clamp(cameraPosition.x, 50.5, 90.5) - 90.5;		//ascent at beginning of video
	position.y += cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);

	const float speed = 20.0 / 80.0;
	float time = track + 8000.0;
	float intensity = 1.0;
	float freq = 1.0;
	float Distance, om, x, y, z;

	if (track < 50.5) position.x += track - 50.5;
	rotate(position.xy, -45.0 * rad);
	x = -45.0;
	y = -60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	// These also control the Intro Terrain Sync
	y *= sinpowslow(clamp10(track, -68.1, 5.0), 4.0);
	x *= sinpowslow(clamp10(track, -73.7, 15.0), 4.0);
	intensity = x - y;
	intensity *= clamp01(position.x, 0.0, 1.0);
	intensity *= sinpowfast(clamp01(track, 45.2, 5.0), 10.0);
	om = intensity  * sin(position.x / 500.0);
	rotate(position.yz, om);
	rotate(position.xy, 45.0 * rad);
	if (track < 50.5) position.x -= track - 50.5;


	x = 45.0;
	y = 60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	// These control the Intro Terrain Sync
	y *= sinpowfast(clamp10(track, 44.5 - 5.0, 5.0), 4.0);
	x *= sinpowfast(clamp10(track, 44.5 - 5.0, 5.0), 4.0);
	intensity = x - y;
	om = intensity * sin(position.x / 500.0);
	rotate(position.yz, om);


	x = position.x;
	if (worldPosition.x >= 50.5) position.x = 50.0 - cameraPosition.x + position.x * 0.05;
	position.x = mix(position.x, x, sinpowfast(clamp01(track, 45.2, 5.0), 10.0));


	Distance = position.x * position.x + position.z * position.z;

	// + or - 52 for middle number in Terrain-Sync

	// These control the Terrain-Sync
	intensity  = 1.0 * sinpowslow (clamp01(track, 818.3 - 35.0, 35.0), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  951.5,  1003.1 -  951.5), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 1135.5, 1187.1 - 1135.5), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 1315.3, 1367.9 - 1315.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 1500.3, 1552.7 - 1500.3), 1.0);

	intensity -= 2.0 * sinpowsharp(clamp01(track, 1682.9, 1734.5 - 1682.9), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 1864.9, 1916.5 - 1864.9), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 2119.7, 2171.3 - 2119.7), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 2232.9, 2284.3 - 2232.9), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 2594.7, 2646.3 - 2594.7), 1.0);

	intensity += 2.0 * sinpowsharp(clamp01(track, 2776.9, 2828.5 - 2776.9), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 2961.7, 3013.5 - 2961.7), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 3141.9, 3194.5 - 3141.9), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 3324.7, 3376.3 - 3324.7), 1.0);

	intensity += 1.0 * sinpowsharp(clamp01(track, 9046.3, 9070.3 - 9046.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9064.3, 9116.3 - 9064.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9178.3, 9230.3 - 9178.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9246.3, 9298.3 - 9246.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9362.3, 9414.3 - 9362.3), 1.0);

	intensity -= 2.0 * sinpowsharp(clamp01(track, 9428.3, 9480.3 - 9428.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9726.3, 9778.3 - 9726.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9794.3, 9846.3 - 9794.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9908.3, 9960.3 - 9908.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9976.3, 10028.3 - 9976.3), 1.0);

	intensity += 2.0 * sinpowsharp(clamp01(track, 10091.3, 10143.3 - 10091.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 10160.3, 10212.3 - 10160.3), 1.0);
	intensity += 1.0 * sinpowfast (clamp01(track, 3527.7, 35.0), 2.0);

	freq = 1325.0 + 700.0 * clamp01(1.0 - sign(intensity) * sign(Distance));

	position.y += intensity * 5.0 * sin(Distance / freq);

//	intensity *= 1.0 - 2.0 * float(track > ( 900.5 +  952.1) / 2.0);
//	intensity *= 1.0 - 2.0 * float(track > (1307.3 + 1358.9) / 2.0);
//	intensity *= 1.0 - 2.0 * float(track > (1511.3 + 1561.7) / 2.0);
//	intensity *= 1.0 - 2.0 * float(track > (1916.9 + 1968.5) / 2.0);

	position.z += intensity * sin(Distance / freq);


// To-do: Change Terrain Deformation (not just invert it or whatever)
// These control the terrain deformation

	om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
	rotate(position.yz, om / 1.5);


	intensity  = sinpowsmooth(clamp01(track, 52255.7 - 800.0, 1100.0), 1.0);
  intensity -= sinpowsmooth(clamp01(track, 53882.5 - 750.0, 750.0), 1.0);

	if (worldPosition.y > 126.9 && worldPosition.y < 131.1 && worldPosition.z > -2.1 && worldPosition.z < 3.1) {
		z = 0.0;
		y = 0.0;

		y -= sinpowslow(clamp01(track, 52255.7 - 35.0, 35.0), 2.0);

		y += (min(sinpowsharp(clamp01(track, 52406.9, 52458.5 - 52406.9), 1.0), 0.5) * 2.0);
		y += (max(sinpowsharp(clamp01(track, 52406.9, 52458.5 - 52406.9), 1.0), 0.5) * 2.0 - 1.0);

		y -= (min(sinpowsharp(clamp01(track, 52610.9, 52662.5 - 52610.9), 1.0), 0.5) * 2.0);
		z -= (max(sinpowsharp(clamp01(track, 52610.9, 52662.5 - 52610.9), 1.0), 0.5) * 2.0 - 1.0);

		z += (min(sinpowsharp(clamp01(track, 52813.7, 52865.3 - 52813.7), 1.0), 0.5) * 2.0);
		z += (max(sinpowsharp(clamp01(track, 52813.7, 52865.3 - 52813.7), 1.0), 0.5) * 2.0 - 1.0) * 0.7;

		z -= (min(sinpowsharp(clamp01(track, 53017.7, 53068.1 - 53017.7), 1.0), 0.5) * 2.0) * 0.7;
		y += (max(sinpowsharp(clamp01(track, 53017.7, 53068.1 - 53017.7), 1.0), 0.5) * 2.0 - 1.0);

		y -= (min(sinpowsharp(clamp01(track, 53221.7, 53272.1 - 53221.7), 1.0), 0.5) * 2.0);
		y -= (max(sinpowsharp(clamp01(track, 53221.7, 53272.1 - 53221.7), 1.0), 0.5) * 2.0 - 1.0);

		y += (min(sinpowsharp(clamp01(track, 53424.5, 53476.1 - 53424.5), 1.0), 0.5) * 2.0);
		z += (max(sinpowsharp(clamp01(track, 53424.5, 53476.1 - 53424.5), 1.0), 0.5) * 2.0 - 1.0) * 0.7;

		z -= (min(sinpowsharp(clamp01(track, 53628.5, 53678.9 - 53628.5), 1.0), 0.5) * 2.0) * 0.7;
		z -= (max(sinpowsharp(clamp01(track, 53628.5, 53678.9 - 53628.5), 1.0), 0.5) * 2.0 - 1.0);

		z += min(sinpowfast(clamp01(track, 53831.3, 35.0), 2.0), 0.5) * 2.0;

		// tl, br, tr, bl, br, tl, tr, bl
		// y+ = br
		// y- = tl
		// z+ = bl
		// z- = tr

		position.y += 2.5 * y;
		position.z += 2.5 * z;

		rotate(position.yz, position.x * intensity * 0.05);

		position.z -= 2.5 * z;
		position.y -= 2.5 * y;
	} else {
		position.y -= cameraPosition.y - 128.0;

		rotateRad(position.xz, 60.0 * intensity);

		om = dot(position.x, position.x) / 4000.0 * intensity;
		rotate(position.yz, om);

		position.y += cameraPosition.y - 128.0;
	}



	intensity  = sinpowsmooth(clamp01(track, 13882.9, 400.0), 1.0);
//   intensity -= sinpowsmooth(clamp01(track, 9691.7, 10483.7 - 9691.7), 1.0);

	om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
	rotate(position.yz, om / 1.2);


	position.y -= cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);
}

float portalCheck(in float x, in vec3 worldPosition) {
	if (worldPosition.x > x - 0.6
	 && worldPosition.x < x + 0.6
	 && worldPosition.y > 126.9
	 && worldPosition.y < 131.1
	 && worldPosition.z > -1.1
	 && worldPosition.z < 2.1
	 && abs(mc_Entity.x - 4.0) < 0.1) return 1.0;
	else return 0.0;
}

float landCheck(in vec3 worldPosition, in vec3 minimum, vec3 maximum) {
	if(worldPosition.x > minimum.x
	&& worldPosition.y > minimum.y
	&& worldPosition.z > minimum.z
	&& worldPosition.x < maximum.x
	&& worldPosition.y < maximum.y
	&& worldPosition.z < maximum.z)
		return 1.0;

	return 0.0;
}

void setPortalBoundaries(in float x, in vec3 playerSpacePosition) {
	topLeft		= vec3(x, gateTop,		gateLeft	) - cameraPosition;
	topRight	= vec3(x, gateTop,		gateRight	) - cameraPosition;
	bottomRight	= vec3(x, gateBottom,	gateRight	) - cameraPosition;
	bottomLeft	= vec3(x, gateBottom,	gateLeft	) - cameraPosition;

	acid(topLeft,		 topLeft		+ cameraPosition);
	acid(topRight,		 topRight		+ cameraPosition);
	acid(bottomRight,	 bottomRight	+ cameraPosition);
	acid(bottomLeft,	 bottomLeft		+ cameraPosition);
}

void doEuclid(in float x, inout vec3 position, in vec3 worldPosition, inout vec3 shadowPosition, const bool leftFirst) {
	if (abs(track - x) > 512.0) return;

	float frontEdge = x - 127.5;
	float backEdge = x + 129.5;

	portal			= portalCheck(x, worldPosition);
	left			= landCheck(worldPosition, vec3(frontEdge + 0.5, -0.5, -256.5), vec3(backEdge - 0.5, 256.5,  -0.5)) * (1.0 - portal);
	right			= landCheck(worldPosition, vec3(frontEdge + 0.5, -0.5,    1.5), vec3(backEdge - 0.5, 256.5, 257.5)) * (1.0 - portal);

	pre = (leftFirst ? left : right);
	post = (leftFirst ? right : left);

	if (left > 0.5) {
		position.xyz		+= vec3(-1.0 * (pre * 2.0 - 1.0), 0.0, 129.0);
		shadowPosition.xyz	+= vec3(-1.0 * (pre * 2.0 - 1.0), 0.0, 0.0);
	} else if (right > 0.5) {
		position.xyz		+= vec3(1.0 * (post * 2.0 - 1.0), 0.0, -129.0);
		shadowPosition.xyz	+= vec3(1.0 * (post * 2.0 - 1.0), 0.0, 0.0);
	} else {
		if (worldPosition.x < x && leftFirst)
			shadowPosition.z -= 129.0 * cubesmooth(clamp01(cameraPosition.x, frontEdge - 256.0, 129.0));
		else if (worldPosition.x < x && !leftFirst)
			shadowPosition.z += 129.0 * cubesmooth(clamp01(cameraPosition.x, frontEdge - 256.0, 129.0));
		else if (worldPosition.x > x && leftFirst)
			shadowPosition.z += 129.0 - (cubesmooth(clamp01(cameraPosition.x, backEdge + 256.0, 129.0)) * 129.0);
		else if (worldPosition.x > x && !leftFirst)
			shadowPosition.z -= 129.0 - cubesmooth(clamp01(cameraPosition.x, backEdge + 256.0, 129.0)) * 129.0;
	}

	setPortalBoundaries(x, position.xyz);
}

void main() {
	CalculateShadowView();

	color			= gl_Color;
	texcoord				= gl_MultiTexCoord0.st;
	mcLightmap		= GetLightmap();
	materialIDs		= GetMaterialIDs();
	fogEnabled		= float(gl_Fog.start / far < 0.65);
	waterMask		= float(abs(mc_Entity.x - 8.5) < 0.6);
	entityID		= mc_Entity.x;
	vertPosition	= gl_Vertex;
	vertNormal		= normalize(gl_NormalMatrix * gl_Normal);

	OptifineGlowstoneFix(color.rgb);


	vec4 position	= GetWorldSpacePosition();

	position.y += 0.0;

	worldPosition = position.xyz + cameraPosition.xyz;

//	position.y += 30.0 * float(worldPosition.x > 6315.5 && (worldPosition.z > 0.5 && worldPosition.z <  257.5 || worldPosition.x > 6571.5));
//	position.y -= 30.0 * float(worldPosition.x > 8755.5 && (worldPosition.z < 0.5 && worldPosition.z > -256.5 || worldPosition.x > 9011.5));

	shadowPosition	= position;
	worldPosition	= position.xyz + cameraPosition.xyz;

	portal			= 0.0;
	left			= 0.0;
	right			= 0.0;

	doEuclid(3734.5, position.xyz, worldPosition.xyz, shadowPosition.xyz, true);
	doEuclid(9046.5, position.xyz, worldPosition.xyz, shadowPosition.xyz, false);
	doEuclid(13242.5, position.xyz, worldPosition.xyz, shadowPosition.xyz, true);
	doEuclid(57000.5, position.xyz, worldPosition.xyz, shadowPosition.xyz, false);

	preAcidWorldPosition = position.xyz + cameraPosition;

//	position.y	-= 56.0 * float(worldPosition.x > 6315.5 && (worldPosition.z > 0.5 && worldPosition.z < 257.5 || worldPosition.x > 6571.5));
	shadowNormal = normalize(gl_NormalMatrix * gl_Normal);

	shadowNormal = normalize((shadowView * shadowModelViewInverse * vec4(gl_NormalMatrix * gl_Normal, 0.0)).xyz);


	gl_Position = BiasShadowProjection(WorldSpaceToShadowProjection(shadowPosition));

	vertNormal		= normalize(gl_NormalMatrix * gl_Normal);

	collapsedMaterialIDs = CollapseMaterialIDs(materialIDs, 0.0, 0.0, 0.0, 0.0);

	if (abs(mc_Entity.x - 173.0) < 0.5) gl_Position.w = -1.0;
	if (abs(mc_Entity.x - 106.0) < 0.5) gl_Position.w = -1.0;
}
