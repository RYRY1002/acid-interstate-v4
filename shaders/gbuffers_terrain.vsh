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
(See our license at https://github.com/RYRY1002/acid-interstate-v4/blob/main/LICENSE.md)

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


#define SHADOW_MAP_BIAS 0.8
#define CUSTOM_TIME_CYCLE

#define gbuffers_shadow false

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

out mat3 tbnMatrix;

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

const float gateTop		= 130.0;
const float gateBottom	= 126.0;
const float gateLeft	= -1.5;
const float gateRight	= 2.5;


vec2 GetLightmap() {							//Gets the lightmap from the default lighting engine. First channel is torch lightmap, second channel is sky lightmap.
	vec2 lightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
		 lightmap = clamp((lightmap * 33.05 / 32.0) - 1.05 / 32.0, 0.0, 1.0);

	return lightmap;
}

vec4 GetWorldSpacePosition() {
	return gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
}

vec4 GetWorldSpacePositionShadow() {
	return shadowModelViewInverse * shadowProjectionInverse * ftransform();
}

vec4 WorldSpaceToProjectedSpace(in vec4 worldSpacePosition) {
	return gl_ProjectionMatrix * gbufferModelView * worldSpacePosition;
}

vec4 WorldSpaceToShadowProjection(in vec4 worldSpacePosition) {
	return shadowProjection * shadowView * worldSpacePosition;
}

vec4 BiasShadowProjection(in vec4 projectedShadowSpacePosition) {
	vec2 position = abs(projectedShadowSpacePosition.xy * 1.165);
	float dist = pow(pow(position.x, 8) + pow(position.y, 8), 1.0 / 8.0);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;

	projectedShadowSpacePosition.xy /= distortFactor;

	projectedShadowSpacePosition.z += pow(max(0.0, 1.0 - dot(shadowNormal, vec3(0.0, 0.0, 1.0))), 4.0) * 0.0125;
	projectedShadowSpacePosition.z += 0.0044 * (dist + 0.1);
	projectedShadowSpacePosition.z /= 4.0;

	return projectedShadowSpacePosition;
}

#include "include/GetMaterialIDs.glsl"

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

void AdjustTerrainTimeCycle(inout vec4 worldSpacePosition, in float timeAngle, in float pathRotation, in float twist, in float celestialAngle) {
	worldSpacePosition = shadowModelView * worldSpacePosition;

	worldSpacePosition.z += 100.0;
	rotateRad(worldSpacePosition.xz, celestialAngle * 360.0);
	rotateRad(worldSpacePosition.zy, sunPathRotation);
	rotateRad(worldSpacePosition.yz, 180.0);
	worldSpacePosition.yz = worldSpacePosition.zy;


	rotateRad(worldSpacePosition.xz, -twist);
	rotateRad(worldSpacePosition.zy, pathRotation);
	rotateRad(worldSpacePosition.xy, timeAngle);


	worldSpacePosition.yz = worldSpacePosition.zy;
	rotateRad(worldSpacePosition.yz, -180.0);

	worldSpacePosition.z -= 100.0;

	worldSpacePosition = shadowModelViewInverse * worldSpacePosition;
}

void AdjustNormalTimeCycle(inout vec3 shadowSpaceNormal, in float timeAngle, in float pathRotation, in float twist, in float celestialAngle) {
	rotateRad(shadowSpaceNormal.xz, celestialAngle * 360.0);
	rotateRad(shadowSpaceNormal.zy, sunPathRotation);
	rotateRad(shadowSpaceNormal.yz, 180.0);
	shadowSpaceNormal.yz = shadowSpaceNormal.zy;

	rotateRad(shadowSpaceNormal.xz, -twist);
	rotateRad(shadowSpaceNormal.zy, pathRotation);
	rotateRad(shadowSpaceNormal.xy, timeAngle);

	shadowSpaceNormal.yz = shadowSpaceNormal.zy;
	rotateRad(shadowSpaceNormal.yz, -180.0);
}

#include "include/animation.glsl"

void rotate(inout vec2 vector, float radians) {
	vector *= mat2(cos(radians), -sin(radians),
				   sin(radians),  cos(radians));
}

vec2 GetCoord(in vec2 coord)
{
	ivec2 atlasResolution = ivec2(64, 32);
	coord *= atlasResolution;
	coord = mod(coord, vec2(1.0));

	return coord;
}

#include "include/acid.glsl"



//	intensity  = sinpowsmooth(clamp01(track, 8882.9, 400.0), 1.0);
//  intensity -= sinpowsmooth(clamp01(track, 9691.7, 10483.7 - 9691.7), 1.0);

	om = intensity * sin(Distance * sin(time * speed / 258.0) / 5000);
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


	vec4 position	= (!gbuffers_shadow ? GetWorldSpacePosition() : GetWorldSpacePositionShadow());



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
	doEuclid(13207.5, position.xyz, worldPosition.xyz, shadowPosition.xyz, true);
	doEuclid(20503.5, position.xyz, worldPosition.xyz, shadowPosition.xyz, false);

	preAcidWorldPosition = position.xyz + cameraPosition;

	if (!gbuffers_shadow) {
		tangent  = normalize(at_tangent.xyz);
		binormal = normalize(-cross(gl_Normal, at_tangent.xyz));

		vec3 tanPos = position.xyz + tangent;
		vec3 binPos = position.xyz + binormal;

		acid(tanPos, tanPos + cameraPosition);
		acid(binPos, binPos + cameraPosition);
		acid(position.xyz, position.xyz + cameraPosition);

		worldPosition		= position.xyz + cameraPosition.xyz;
		playerSpacePosition	= position.xyz;


		tangent = tanPos - position.xyz;
		binormal = binPos - position.xyz;
		vertNormal = cross(-tangent, binormal);

		tangent    = normalize(gl_NormalMatrix * tangent);
		binormal   = normalize(gl_NormalMatrix * binormal);
		vertNormal = normalize(gl_NormalMatrix * vertNormal);
	}

//	position.y	-= 56.0 * float(worldPosition.x > 6315.5 && (worldPosition.z > 0.5 && worldPosition.z < 257.5 || worldPosition.x > 6571.5));
	shadowNormal = normalize(gl_NormalMatrix * gl_Normal);

	if (gbuffers_shadow) shadowNormal = normalize((shadowView * shadowModelViewInverse * vec4(gl_NormalMatrix * gl_Normal, 0.0)).xyz);
	else {
		position = gbufferModelView * position;
		position.z += 0.1;
		position = gbufferModelViewInverse * position;
	}

	gl_Position		= WorldSpaceToProjectedSpace(position);
//	AdjustTimeCycle(shadowPosition, vertNormal);
	gl_Position			= BiasShadowProjection(WorldSpaceToShadowProjection(shadowPosition) / vec4(1.0, 1.0, 2.5, 1.0));

	gl_Position		= (!gbuffers_shadow ? WorldSpaceToProjectedSpace(position) : BiasShadowProjection(WorldSpaceToShadowProjection(shadowPosition)));


	tbnMatrix		= mat3(tangent.x, binormal.x, vertNormal.x,
						   tangent.y, binormal.y, vertNormal.y,
						   tangent.z, binormal.z, vertNormal.z);

	vertNormal		= normalize(gl_NormalMatrix * gl_Normal);

	collapsedMaterialIDs = CollapseMaterialIDs(materialIDs, 0.0, 0.0, 0.0, 0.0);

	if (abs(mc_Entity.x - 173.0) < 0.5) gl_Position.w = -1.0;
	if (abs(mc_Entity.x - 106.0) < 0.5) gl_Position.w = -1.0;
}
