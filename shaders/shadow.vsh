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

#include "include/acid.glsl"



	intensity  = sinpowsmooth(clamp01(track, 13882.9, 400.0), 1.0);
//   intensity -= sinpowsmooth(clamp01(track, 9691.7, 10483.7 - 9691.7), 1.0);

	om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
	rotate(position.yz, om / 1.2);


	position.y -= cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);
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
