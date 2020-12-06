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
(See our license at https://github.com/RYRY1002/acid-interstate-v2/blob/main/LICENSE)

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

/*
attribute vec4 mc_Entity*/ in vec4 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

#define track cameraPosition.x
uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float far;

out mat3 tbnMatrix;

out vec4 shadowPosition;
out vec4 vertPosition;
out vec4 color;

out vec3 worldPosition;
out vec3 vertNormal;
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

const float PI = 3.1415926535;
const float rad = 0.01745329;


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
	return shadowProjection * shadowModelView * worldSpacePosition;
}

vec4 BiasShadowProjection(in vec4 projectedShadowSpacePosition) {
	float dist = length(projectedShadowSpacePosition.xy);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;

	projectedShadowSpacePosition.xy /= distortFactor;

	projectedShadowSpacePosition.z += pow(max(0.0, 1.0 - dot(vertNormal, vec3(0.0, 0.0, 1.0))), 4.0) * 0.01;
	projectedShadowSpacePosition.z += 0.0036 * (dist + 0.1);

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

void GetTangetBinormal(inout vec3 tangent, inout vec3 binormal) {
	if (gl_Normal.x > 0.5) {
		tangent		= normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal	= normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.x < -0.5) {
		tangent		= normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal	= normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.y > 0.5) {
		tangent		= normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal	= normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.y < -0.5) {
		tangent		= normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal	= normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.z > 0.5) {
		tangent		= normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal	= normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.z < -0.5) {
		tangent		= normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal	= normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
}


#include "include/animation.glsl"


void rotate(inout vec2 p, in float angle) {
	mat2 rotMat = mat2(cos(angle), -sin(angle),
					   sin(angle),  cos(angle));
	p *= rotMat; }

vec2 GetCoord(in vec2 coord)
{
	ivec2 atlasResolution = ivec2(64, 32);
	coord *= atlasResolution;
	coord = mod(coord, vec2(1.0));

	return coord;
}

#include "include/acid2.glsl"

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


	vec4 position	= GetWorldSpacePosition();
	//vec4 position	= GetWorldSpacePositionShadow();


	worldPosition	= position.xyz + cameraPosition.xyz;

	acid(position.xyz, worldPosition);


	gl_Position		= WorldSpaceToProjectedSpace(position);
	//gl_Position		= BiasShadowProjection(WorldSpaceToShadowProjection(position));

	GetTangetBinormal(tangent, binormal);

	tbnMatrix		= mat3(tangent.x, binormal.x, vertNormal.x,
						   tangent.y, binormal.y, vertNormal.y,
						   tangent.z, binormal.z, vertNormal.z);

	collapsedMaterialIDs = CollapseMaterialIDs(materialIDs, 0.0, 0.0, 0.0, 0.0);

	if (abs(mc_Entity.x - 173.0) < 0.5) gl_Position.w = -1.0;
}
