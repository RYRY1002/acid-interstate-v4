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


float clamp01(in float x) {
	return clamp(x, 0.0, 1.0); }

float clamp01(in float x, in float start, in float length) {
	return clamp((clamp(x, start, start + length) - start) / length, 0.0, 1.0); }

float clamp10(in float x) {
	return 1.0 - clamp(x, 0.0, 1.0); }

float clamp10(in float x, in float start, in float length) {
	return 1.0 - clamp((clamp(x, start, start + length) - start) / length, 0.0, 1.0); }

//These functions are for a linear domain of 0.0-1.0 & have a range of 0.0-1.0
float powslow(in float x, in float power) {	//linear --> exponentially slow
	return pow(x, power); }

float powfast(in float x, in float power) {	//linear --> exponentially fast
	return 1.0 - pow(1.0 - x, power); }

//sinpow functions are just like power functions, but use a mix of exponential and trigonometric interpolation
float sinpowslow(in float x, in float power) {
	return 1.0 - pow(sin(pow(1.0 - x, 1.0 / power) * PI / 2.0), power); }

float sinpowfast(in float x, in float power) {
	return pow(sin(pow(x, 1.0 / power) * PI / 2.0), power); }

float sinpowsharp(in float x, in float power) {
	return sinpowfast(clamp01(x * 2.0), power) * 0.5 + sinpowslow(clamp01(x * 2.0 - 1.0), power) * 0.5; }

float sinpowsmooth(in float x, in float power) {
	return sinpowslow(clamp01(x * 2.0), power) * 0.5 + sinpowfast(clamp01(x * 2.0 - 1.0), power) * 0.5; }

//cubesmooth functions have zero slopes at the start & end of their ranges
float cubesmooth(in float x) {
	return x * x * (3.0 - 2.0 * x); }

float cubesmoothslow(in float x, in float power) {
	return pow(x, power - 1.0) * (power - (power - 1.0) * x); }

float cubesmoothfast(in float x, in float power) {
	return 1.0 - pow(1.0 - x, power - 1.0) * (power - (power - 1.0) * (1.0 - x)); }


//U functions take a linear domain 0.0-1.0 and have a range that goes from 0.0 to 1.0 and back to 0.0
float sinpowsharpU(in float x, in float power) {
	return sinpowfast(clamp01(x * 2.0), power) - sinpowslow(clamp01(x * 2.0 - 1.0), power); }

float sinpowfastU(in float x, in float power) {
	//return cubesmooth(clamp01(x * 2.0 - 1.0)); }
	return sinpowfast(clamp01(x * power), power) - cubesmooth(clamp01(max(x * power * 2.0 - 1.0, 0.0) / power)); }


void rotate(inout vec2 p, in float angle) {
	mat2 rotMat = mat2(cos(angle), -sin(angle),
					   sin(angle),  cos(angle));
	p *= rotMat; }

bool portalCheck(in float x, in vec2 y, in vec2 z, in vec3 worldPosition)
{
	if (worldPosition.x > x - 0.6
	 && worldPosition.x < x + 0.6
	 && worldPosition.y > y.x - 0.6
	 && worldPosition.y < y.y + 0.6
	 && worldPosition.z > z.x - 0.6
	 && worldPosition.z < z.y + 0.6
	 && abs(mc_Entity.x - 4.0) < 0.1) return true;
	else return false;
}

vec2 GetCoord(in vec2 coord)
{
	ivec2 atlasResolution = ivec2(64, 32);
	coord *= atlasResolution;
	coord = mod(coord, vec2(1.0));

	return coord;
}

float landCheck(in vec3 worldPosition, in vec3 minimum, vec3 maximum)
{
	if(worldPosition.x > minimum.x
	&& worldPosition.y > minimum.y
	&& worldPosition.z > minimum.z
	&& worldPosition.x < maximum.x
	&& worldPosition.y < maximum.y
	&& worldPosition.z < maximum.z)
		return 1.0;

	return 0.0;
}

void acid(inout vec3 position, in vec3 worldPosition)
{
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
	y *= sinpowslow(clamp10(track, 68.1, 5.0), 4.0);
	x *= sinpowslow(clamp10(track, 73.7, 15.0), 4.0);
	intensity = x - y;
	intensity *= clamp01(position.x, 0.0, 1.0);
	intensity *= sinpowfast(clamp01(track, 45.2, 5.0), 10.0);
	om = intensity  * sin(position.x / 500.0);
	rotate(position.yz, om);
	rotate(position.xy, 45.0 * rad);
	if (track < 50.5) position.x -= track - 50.5;


	x = 45.0;
	y = 60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	y *= sinpowfast(clamp10(track, 23.0 - 5.0, 5.0), 4.0);
	x *= sinpowfast(clamp10(track, 28.5 - 5.0, 5.0), 4.0);
	intensity = x - y;
	om = intensity * sin(position.x / 500.0);
	rotate(position.yz, om);


	x = position.x;
	if (worldPosition.x >= 50.5) position.x = 50.0 - cameraPosition.x + position.x * 0.05;
	position.x = mix(position.x, x, sinpowfast(clamp01(track, 45.2, 5.0), 10.0));


	Distance = position.x * position.x + position.z * position.z;

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

	x = Distance;

	freq = 1325.0 + 600.0 * clamp01(1.0 - sign(intensity) * sign(x));

	position.y += intensity * 5.0 * sin(x / freq);

//	intensity *= 1.0 - 2.0 * float(track > ( 900.5 +  952.1) / 2.0);
//	intensity *= 1.0 - 2.0 * float(track > (1307.3 + 1358.9) / 2.0);

	position.z += intensity * sin(x / freq);

	intensity  = -1.0 * sinpowfast(clamp01(track, 80.5, 85.5 - 80.5), 3.0);
	intensity += -4.5 * sinpowfast(clamp01(track, 2283.5, 492.5 - 80.5), 3.0); //Set intensity to 0.0 for Terrain Deformation the same as P1
	intensity -= -5.5 * sinpowfast(clamp01(track, 3321.5, 492.5 - 80.5), 3.0);
	intensity -= 1.0 * sinpowslow(clamp01(track, 3734.5, 4034.5 - 3734.5), 3.0);
	intensity += 1.0 * sinpowslow(clamp01(track, 8966.5, 9045.5 - 8966.5), 3.0);
	intensity -= 2.0 * sinpowfast(clamp01(track, 9046.5, 492.5 - 80.5), 3.0);

	om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
	rotate(position.yz, om / 1.5);

	position.y -= cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);
}

void interpolateBounds(inout float x, inout vec2 y, inout vec2 z)
{
	vec3 bottomLeftWorld = vec3(x, y.x, z.x);
	vec3 bottomRightWorld = vec3(x, y.x, z.y);
	vec3 topLeftWorld = vec3(x, y.y, z.x);
	vec3 topRightWorld = vec3(x, y.y, z.y);

	vec3 bottomLeftPlayer = bottomLeftWorld - cameraPosition;
	vec3 bottomRightPlayer = bottomRightWorld - cameraPosition;
	vec3 topLeftPlayer = topLeftWorld - cameraPosition;
	vec3 topRightPlayer = topRightWorld - cameraPosition;

	vec3 bottomLeftPlayer2 = bottomLeftPlayer;
	vec3 bottomRightPlayer2 = bottomRightPlayer;
	vec3 topLeftPlayer2 = topLeftPlayer;
	vec3 topRightPlayer2 = topRightPlayer;

	acid(bottomLeftPlayer, bottomLeftWorld);
	acid(bottomRightPlayer, bottomRightWorld);
	acid(topLeftPlayer, topLeftWorld);
	acid(topRightPlayer, topRightWorld);

	bottomLeftPlayer -= bottomLeftPlayer2;
	bottomRightPlayer -= bottomRightPlayer2;
	topLeftPlayer -= topLeftPlayer2;
	topRightPlayer -= topRightPlayer2;

	vec3 bottomLeftPosition = bottomLeftWorld + bottomLeftPlayer;
	vec3 bottomRightPosition = bottomRightWorld + bottomRightPlayer;
	vec3 topLeftPosition = topLeftWorld + topLeftPlayer;
	vec3 topRightPosition = topRightWorld + topRightPlayer;

	x = (bottomLeftPosition.x + bottomRightPosition.x + topLeftPosition.x + topRightPosition.x) / 4.0;
	y.x = (bottomLeftPosition.y + bottomRightPosition.y) / 2.0;
	y.y = (topLeftPosition.y + topRightPosition.y) / 2.0;
	z.x = (bottomLeftPosition.z + topLeftPosition.z) / 2.0;
	z.y = (bottomRightPosition.z + topRightPosition.z) / 2.0;
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


	vec4 position	= GetWorldSpacePosition();
	//vec4 position	= GetWorldSpacePositionShadow();


	worldPosition	= position.xyz + cameraPosition.xyz;

	float land1 = landCheck(worldPosition, vec3(2248.5, 85.5, -256.5), vec3(2504.5, 256.5,  -0.5));
	float land2 = landCheck(worldPosition, vec3(2248.5, 55.5,    1.5), vec3(2504.5, 256.5, 257.5));

	if (land1 > 0.5) { position.x -= 1.0; position.y -= 86.0; }
	if (land2 > 0.5) { position.x += 1.0; }

	shadowPosition	= position;

	if (land1 > 0.5) { position.z += 129.0; }
	if (land2 > 0.5) { position.z -= 129.0; }

	if (land1 + land2 < 0.5) {
		if (worldPosition.x <= 2248.5)
			shadowPosition.z -= 129.0 * (clamp(worldPosition.x, 2119.0, 2248.0) - 2119.0) / (129.0);
		if (worldPosition.x > 2500.0)
			shadowPosition.z += 129.0 * (1.0 - (clamp(worldPosition.x, 2505.0, 2505.0 + 129.0) - 2505.0) / (129.0));
	}

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
