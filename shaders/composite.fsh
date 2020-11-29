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
This shdaer was orignally made by MiningGodBruce, and modified by RYRY1002.

Most of the work done for this shader was done by MiningGodBruce.
Make sure you give him some love.
https://www.youtube.com/user/MiningGodBruce

And maybe give me some love also.
(Thanks!)
https://links.riley.technology/

*/

#version 450 compatibility


#define SHADOW_MAP_BIAS 0.8
#define SCALE_FACTOR 1.0
#define VERTEX_SCALE 0.5
#define CUSTOM_TIME_CYCLE
#define EXTENDED_SHADOW_DISTANCE
#define GI_BOOST

//////////////////////////////INTERNAL VARIABLES////////////////////////////////////////////////////////////
//////////////////////////////INTERNAL VARIABLES////////////////////////////////////////////////////////////
//Do not change the name of these variables or their type. The Shaders Mod reads these lines and determines values to send to the inner-workings
//of the shaders mod. The shaders mod only reads these lines and doesn't actually know the real value assigned to these variables in GLSL.
//Some of these variables are critical for proper operation. Change at your own risk.

const int   shadowMapResolution = 3072;
const float shadowDistance      = 200.0;

const float sunPathRotation = -40.0;

const int noiseTextureResolution = 64;

#define PI 3.14159265
const float rad = 0.01745329;


uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D gdepthtex;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D noisetex;
uniform sampler2DShadow shadow;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;


uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;
uniform float frameTimeCounter;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#define track cameraPosition.x

in vec2 texcoord;

in vec3 lightVector;

in mat4 shadowView;
in mat4 shadowViewInverse;

in float timeCycle;
in float timeAngle;
in float pathRotationAngle;
in float twistAngle;

/* DRAWBUFFERS:4 */


//////////////////////////////STRUCTS////////////////////////////////////////////////////////////
//////////////////////////////STRUCTS////////////////////////////////////////////////////////////

struct MaskStruct {
	float materialIDs;
	float matIDs;

	float fullbright;
	float bit1;
	float bit2;
	float bit3;

	float sky;

	float grass;
	float leaves;
	float water;
} mask;

//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////

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

vec3 GetNormals(in vec2 texcoord) {
	return texture2DLod(colortex0, texcoord.st, 0).rgb * 2.0 - 1.0;
}

float GetDepth(in vec2 texcoord) {
	return texture2D(gdepthtex, texcoord.st).x;
}


vec4 GetViewSpacePosition(in vec2 texcoord, in float depth) { //Function that calculates the view-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	vec4 fragposition = gbufferProjectionInverse * vec4(vec3(texcoord.st, depth) * 2.0 - 1.0, 1.0);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 ViewSpaceToWorldSpace(in vec4 viewSpacePosition) {
	return gbufferModelViewInverse * viewSpacePosition;
}

vec4 WorldSpaceToShadowSpace(in vec4 worldSpacePosition) {
	return shadowProjection * shadowView * worldSpacePosition;
}

float pow8(in float x) {
	x *= x;
	x *= x;
	return x * x;
}

float root8(in float x) {
	return sqrt(sqrt(sqrt(x)));
}

float length8(in vec2 x) {
	return root8(pow8(x.x) + pow8(x.y));
}

float GetShadowBias(in vec2 shadowProjection) {
	shadowProjection *= 1.165;
	return length8(shadowProjection) * SHADOW_MAP_BIAS + (1.0 - SHADOW_MAP_BIAS);
}

vec2 BiasShadowMap(in vec2 shadowProjection) {
	return shadowProjection / GetShadowBias(shadowProjection);
}

vec3 BiasShadowProjection(in vec3 position) {
	return position / vec3(vec2(GetShadowBias(position.xy)), 4.0);
}

float noise(in vec2 coord) {
    return fract(sin(dot(coord, vec2(12.9898, 4.1414))) * 43758.5453);
}

vec2 CalculateNoisePattern1(const float size) {
	vec2 texcoord = texcoord * VERTEX_SCALE;

	texcoord *= vec2(viewWidth, viewHeight);
	texcoord  = mod(texcoord, vec2(size));
	texcoord /= noiseTextureResolution;

	return texture2D(noisetex, texcoord).xy;
}


float GetMaterialIDs(in vec2 texcoord) {		//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(colortex1, texcoord).r;
}

void ExpandMaterialIDs(inout float matID, inout float bit0, inout float bit1, inout float bit2, inout float bit3) {
	matID *= 255.0;

	if (matID >= 128.0 && matID < 254.5) {
		matID -= 128.0;
		bit0 = 1.0;
	}

	if (matID >= 64.0 && matID < 254.5) {
		matID -= 64.0;
		bit1 = 1.0;
	}

	if (matID >= 32.0 && matID < 254.5) {
		matID -= 32.0;
		bit2 = 1.0;
	}

	if (matID >= 16.0 && matID < 254.5) {
		matID -= 16.0;
		bit3 = 1.0;
	}
}

float GetSkyMask(in float matID) {
	return float(matID < 0.5 || matID > 254.5);
}

float GetMaterialMask(int ID, in float matID) {
	if (matID > 254.5)
		matID = 0.0;

	return float(abs(matID - ID) < 0.1);
}


void CalculateMasks(inout MaskStruct mask, in vec2 texcoord) {
	mask.materialIDs = GetMaterialIDs(texcoord);
	mask.matIDs      = mask.materialIDs;

	ExpandMaterialIDs(mask.matIDs, mask.fullbright, mask.bit1, mask.bit2, mask.bit3);

	mask.sky    = GetSkyMask(mask.matIDs);

	mask.grass  = GetMaterialMask(2, mask.matIDs);
	mask.leaves = GetMaterialMask(3, mask.matIDs);
	mask.water  = GetMaterialMask(4, mask.matIDs);
}


void rotate(inout vec2 vector, float degrees) {
	degrees *= 0.0174533;		//Convert from degrees to radians

	vector *= mat2(cos(degrees), -sin(degrees),
				   sin(degrees),  cos(degrees));
}

float GetNormalShading(in vec3 normal, in MaskStruct mask) {
	float shading = dot(normal, lightVector);
	      shading = shading * (1.0 - mask.grass       ) + mask.grass       ;
	      shading = shading * (1.0 - mask.leaves * 0.5) + mask.leaves * 0.5;

	return shading;
}


float GetLightmapSky(in vec2 coord) {
	return pow(texture2D(colortex1, coord).b, 4.3);
}

vec3 CalculateGIClean(in vec2 texcoord, in vec4 viewSpacePosition, in vec3 normal, const float radius, const float iterations, in vec2 noisePattern, in MaskStruct mask) {
	float lightMult = 1.0;

	vec4 shadowSpaceNormal = shadowView * gbufferModelViewInverse * vec4(normal, 0.0);

	vec4 position = vec4((texture2D(colortex3, texcoord).rgb - 0.5) * 528.0, 1.0);
	     position = WorldSpaceToShadowSpace(position);
	     position = position * 0.5 + 0.5;


	#ifdef GI_BOOST
		float normalShading = GetNormalShading(normal, mask);

		vec4 shadowPos = vec4(BiasShadowProjection(position.xyz * 2.0 - 1.0) * 0.5 + 0.5, position.w);

		float sunlight = shadow2D(shadow, vec3(shadowPos.xyz)).x;
		      sunlight *= sunlight;

		lightMult *= 1.0 - sunlight * normalShading * 4.0 * pow(GetLightmapSky(texcoord), 2.0);

		if (lightMult < 0.01) return vec3(0.0);
	#endif


	const float scale    = 1.0 * radius / 512.0;
	noisePattern.xy     -= 0.5;
	const float interval = 0.5 / iterations;
	float LodCoeff       = clamp(1.0 - length(viewSpacePosition.xyz) / shadowDistance, 0.0, 1.0);
	float depthLOD	     = 2.0 * LodCoeff;
	float sampleLOD	     = 5.0 * LodCoeff;

	vec3 GI              = vec3(0.0);

	for (float x = -1.0; x <= 1.0; x += interval) {
		for (float y = -1.0; y <= 1.0; y += interval) {
			vec2 offset = (vec2(x, y) + noisePattern * interval) * scale;

			vec3 samplePos = vec3(position.xy + offset, 0.0);

			vec2 mapPos = BiasShadowMap(samplePos.xy * 2.0 - 1.0) * 0.5 + 0.5;

			samplePos.z = texture2DLod(shadowtex1, mapPos, depthLOD).x * 4.0 - 1.5;

			vec3 sampleDiff = samplePos.xyz - position.xyz;
			vec3 sampleDir = normalize(sampleDiff);

			vec3 shadowNormal = normalize(texture2DLod(shadowcolor1, mapPos, sampleLOD).xyz * 2.0 - 1.0);

			float viewNormalCoeff = max(0.0, dot(shadowSpaceNormal.xyz, sampleDir * vec3(1.0, 1.0, -1.0)));
			      viewNormalCoeff = viewNormalCoeff * 0.85 + 0.15;
			      viewNormalCoeff = viewNormalCoeff * (1.0 - mask.leaves) + mask.leaves;

			float shadowNormalCoeff = dot(sampleDir, shadowNormal);
			      shadowNormalCoeff = max(shadowNormalCoeff, 0.0);

			float distanceCoeff = clamp(1.0 / dot(sampleDiff, sampleDiff) - 9e-05, 0.0, 1000.0);

			vec3 flux = pow(texture2DLod(shadowcolor, mapPos, sampleLOD).xyz, vec3(2.2));

			GI += flux * shadowNormalCoeff * distanceCoeff * viewNormalCoeff;
		}
	}

	GI /= pow(2.0 / interval + 1.0, 2.0);;

	return GI * 1000.0 / (13600.0 / radius) / (13600.0 / radius) / radius * 16.0 * lightMult;
}

//////////////////////////////MAIN////////////////////////////////////////////////////////////
//////////////////////////////MAIN////////////////////////////////////////////////////////////

void main() {
	CalculateMasks(mask, texcoord);
	if (mask.sky + mask.water > 0.5) discard;

	vec3  normal            = GetNormals(texcoord);
	float depth             = GetDepth(texcoord);
	vec4  viewSpacePosition = GetViewSpacePosition(texcoord, depth);
	vec2  noisePattern      = CalculateNoisePattern1(4);

	vec3 light;
	light.rgb	 = CalculateGIClean(texcoord, viewSpacePosition, normal, 64.0, 3.0, noisePattern, mask);
//	light.rgb	+= CalculateGIClean(texcoord, viewSpacePosition, normal, 32.0, 2.0, noisePattern, mask);
	light.rgb	+= CalculateGIClean(texcoord, viewSpacePosition, normal, 16.0, 3.0, noisePattern, mask) * 0.75;

//	light.rgb = ComputeGlobalIllumination(texcoord, viewSpacePosition, normal, 16.0, 4.0, noisePattern.xy * 2.0 - 1.0);

	gl_FragData[0] = vec4(pow(light.rgb, vec3(1.0 / 2.2)), 1.0);
}
