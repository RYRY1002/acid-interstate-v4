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

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D gdepthtex;
uniform sampler2D noisetex;
uniform sampler2D gcolor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float near;
uniform float far;
uniform float sunAngle;

uniform vec3 cameraPosition;
#define track cameraPosition.x

uniform vec3 upPosition;

in vec3 lightVector;
in vec3 colorSunlight;
in vec3 colorSkylight;
in vec3 colorSunglow;
in vec3 colorBouncedSunlight;
in vec3 colorWaterMurk;
in vec3 colorWaterBlue;

in vec2 texcoord;

uniform float viewWidth;
uniform float viewHeight;

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;
in float horizonTime;
in float timeSun;
in float timeMoon;
in float fogEnabled;


//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////

//#define texture2D(a, b) texelFetch(a, ivec2(b * vec2(viewWidth, viewHeight)), 0)

vec3 GetNormals(in vec2 coord) {
	return texture2D(colortex0, coord.st).rgb * 2.0 - 1.0;
}

float GetDepth(in vec2 coord) {
	return texture2D(gdepthtex, coord).r;
}

float ExpToLinearDepth(in float depth) {
	return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 GetViewSpacePosition(in vec2 coord) {
	vec4 fragposition = gbufferProjectionInverse * vec4(vec3(coord, texture2D(gdepthtex, coord).r) * 2.0 - 1.0, 1.0);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 GetViewSpacePosition(in vec2 coord, in float depth) {
	vec4 fragposition = gbufferProjectionInverse * vec4(vec3(coord, depth) * 2.0 - 1.0, 1.0);
		 fragposition /= fragposition.w;

	return fragposition;
}

float GetSunlightVisibility(in vec2 coord) {
	return texture2D(colortex1, coord).g;
}

float cubicPulse(float c, float w, float x) {
	x = abs(x - c);
	if (x > w) return 0.0;
	x /= w;
	return 1.0 - x * x * (3.0 - 2.0 * x);
}


float GetMaterialIDs(in vec2 coord) {		//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(colortex1, coord).r;
}

void ExpandMaterialIDs(inout float matID, inout float bit1, inout float bit2, inout float bit3, inout float bit4) {
	matID *= 255.0;

	if (matID >= 128.0 && matID < 254.5) {
		matID -= 128.0;
		bit1 = 1.0;
	}

	if (matID >= 64.0 && matID < 254.5) {
		matID -= 64.0;
		bit2 = 1.0;
	}

	if (matID >= 32.0 && matID < 254.5) {
		matID -= 32.0;
		bit3 = 1.0;
	}

	if (matID >= 16.0 && matID < 254.5) {
		matID -= 16.0;
		bit4 = 1.0;
	}
}

float GetSkyMask(in float matID) {
	if (matID < 0.5 || matID > 254.5)
		return 1.0;
	else
		return 0.0;
}

float GetMaterialMask(int ID, in float matID) {
	//Catch last part of sky
	if (matID > 254.5)
		matID = 0.0;

	if (abs(matID - ID) < 0.1)
		return 1.0;
	else
		return 0.0;
}


float GetLightmapSky(in vec2 coord) {
	return texture2D(colortex1, texcoord).b;
}


vec3 ViewSpaceToScreenSpace(vec3 viewSpacePosition) {
    vec4 screenSpace = gbufferProjection * vec4(viewSpacePosition, 1.0);

    return (screenSpace.xyz / screenSpace.w) * 0.5 + 0.5;
}

vec3 cubesmooth(in vec3 x) {
	return x * x * (3.0 - 2.0 * x);
}

float Get3DNoise(in vec3 pos) {
	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f = f * f * (3.0 - 2.0 * f);

	vec2 uv =  (p.xy +  p.z        * 17.0) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0) * 17.0) + f.xy;

	float xy1 = texture2D(noisetex, uv  / 64.0).x;
	float xy2 = texture2D(noisetex, uv2 / 64.0).x;

	return mix(xy1, xy2, f.z);
}

float CalculateFogFactor(in vec3 position, in float power) {
	float fogFactor = length(position);
		  fogFactor = max(fogFactor - gl_Fog.start, 0.0);
		  fogFactor /= far - gl_Fog.start;
		  fogFactor = pow(fogFactor, power);
		  fogFactor *= fogEnabled;
		  fogFactor = clamp(fogFactor, 0.0, 1.0);

	return fogFactor;
}

void FixNormals(inout vec3 normal, in vec3 viewSpacePosition, in float amount) {
	vec3 V = normalize(viewSpacePosition.xyz);
	vec3 N = normal;

	float NdotV = dot(N, V);

	N = normalize(mix(normal, -V, clamp(NdotV, 0.0, 1.0)));
	N = normalize(N + -V * amount * clamp(NdotV + 0.3, 0.0, 1.0));

	normal = N;
}

void TonemapReinhard05(inout vec3 color) {
	vec3 averageLuminance = vec3(0.0001);

	vec3 value = color.rgb / (color.rgb + averageLuminance);

	color.rgb = value;
	color.rgb = min(color.rgb, vec3(1.0));
	color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
}

#include "include/animation.glsl"

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct MaskStruct {
	float materialIDs;
	float matIDs;

	float left;
	float right;
	float bit3;
	float bit4;

	float sky;

	float water;
	float goldBlock;
	float brick;
} mask;

struct ReflectionStruct {
	vec4 viewSpacePosition;

	float skyMask;
	float fogFactor;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct SpecularityStruct {
	float specularity;
	float roughness;
	float fresnelPower;
	float baseSpecularity;

	float skylightVisibility;
	float sunlightVisibility;
} spec;

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};

/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void CalculateMasks(inout MaskStruct mask) {
	mask.materialIDs	= texture2D(colortex1, texcoord).r;
	mask.matIDs			= mask.materialIDs;

	ExpandMaterialIDs(mask.matIDs, mask.left, mask.right, mask.bit3, mask.bit4);

	mask.sky 			= GetSkyMask(mask.matIDs);

	mask.water 			= GetMaterialMask(4, mask.matIDs);
	mask.goldBlock 		= GetMaterialMask(6, mask.matIDs);
	mask.brick 			= GetMaterialMask(11, mask.matIDs);
}

void adjustFog(in float x, inout vec3 position) {
	position.z *= 1.0 + cubesmooth(clamp01(cameraPosition.x, (x - 127.5) - 256.0, 128.0))
	- cubesmooth(clamp01(cameraPosition.x, (x + 129.5) + 256.0, 128.0));

	position.x *= 1.0 + (clamp01(cameraPosition.x, (x + 129.5) - 256.0, 128.0)
	- clamp01(cameraPosition.x, (x + 129.5) + 128.0, 128.0)) * mix(1.0, float(position.x < 0.0), mask.bit3);
}

float CalculateFogFactor(in vec3 position, in float power, in MaskStruct mask) {
	position = (gbufferModelViewInverse * vec4(position, 0.0)).xyz;

//	adjustFog(-90.5,	position.xyz);
	adjustFog(3731.5, position.xyz);
	adjustFog(9048.5, position.xyz);
	adjustFog(13207.5, position.xyz);

	float fogFactor = length(position);
		  fogFactor = max(fogFactor - gl_Fog.start, 0.0);
		  fogFactor /= far - gl_Fog.start;
		  fogFactor = pow(fogFactor, power);
		  fogFactor *= fogEnabled;
		  fogFactor = clamp(fogFactor, 0.0, 1.0);

			fogFactor * 2.0;
	return fogFactor;
}

vec4 ComputeRaytraceReflection(in vec4 viewSpacePosition, in vec3 viewSpaceNormal, out ReflectionStruct ref, in MaskStruct mask) {
	float initialStepAmount = 10.0;

	FixNormals(viewSpaceNormal, viewSpacePosition.xyz, 0.1 - 0.07 * mask.water);

    vec3 viewSpaceViewDir = normalize(viewSpacePosition.xyz);
    vec3 viewSpaceVector = initialStepAmount * normalize(reflect(viewSpaceViewDir, viewSpaceNormal));
    vec3 viewSpaceVectorPosition = viewSpacePosition.xyz + viewSpaceVector;
    vec3 currentPosition = ViewSpaceToScreenSpace(viewSpaceVectorPosition);

    vec4 color = vec4(1.0);

    const int maxRefinements = 3;
	int numRefinements = 0;

	vec3 finalSamplePos, finalViewPos;

	int numSteps = 0;

	float sampleDepth, sampleViewDepth, currentDepth, diff, error;

	ref.skyMask = 0.0;

	for (int i = 0; i < 40; i++) {
		if(	currentPosition.x < 0.0 || currentPosition.x > 1.0 ||
			currentPosition.y < 0.0 || currentPosition.y > 1.0 ||
			currentPosition.z < 0.0 || currentPosition.z > 1.0 ||
			-viewSpaceVectorPosition.z > far * 1.6 + 16.0 ||
			-viewSpaceVectorPosition.z < 0.0)
		{
			ref.skyMask = 1.0;
			break;
		}

		sampleDepth = GetDepth(currentPosition.xy);

		sampleViewDepth = GetViewSpacePosition(currentPosition.xy).z;

		currentDepth = viewSpaceVectorPosition.z;
		diff = sampleViewDepth - currentDepth;
		error = length(viewSpaceVector / exp2(numRefinements));

		if (diff >= 0) {
			//If a collision was detected, refine raymarch
			if (diff <= error * 2.0 && numRefinements <= maxRefinements) {
				//Step back
				viewSpaceVectorPosition -= viewSpaceVector / exp2(numRefinements);
				++numRefinements;
			}
			//If refinements run out
			else if (diff <= error * 4.0 && numRefinements > maxRefinements) {
				finalSamplePos = vec3(currentPosition.xy, sampleDepth);
				finalViewPos = viewSpaceVectorPosition;
				break;
			}
		}

		viewSpaceVectorPosition += viewSpaceVector / exp2(numRefinements);

		if (numSteps > 1)
		viewSpaceVector *= 1.375;	//Each step gets bigger

		currentPosition = ViewSpaceToScreenSpace(viewSpaceVectorPosition);
		numSteps++;
	}

	color.rgb = texture2D(colortex2, finalSamplePos.xy).rgb;
	color.rgb = pow(color.rgb, vec3(2.2));

	float matID = GetMaterialIDs(finalSamplePos.xy);

	if (abs(matID * 255.0 - 4.0) < 0.1)
		color.a = 0.0;

	if (finalSamplePos.x == 0.0 || finalSamplePos.y == 0.0)
		color.a = 0.0;

	float edge = clamp(1.0 - pow(distance(vec2(0.5), finalSamplePos.xy) * 2.0, 2.0), 0.0, 1.0);
	color.a *= 1.0 - pow(1.0 - edge, 10.1);

	ref.viewSpacePosition = GetViewSpacePosition(finalSamplePos.xy, finalSamplePos.z);

	if (ref.skyMask > 0.5) ref.viewSpacePosition.xyz = normalize(vec3(1.0)) * max(far * 2.0, 128.0);
	ref.fogFactor = (fogEnabled > 0.5) ? CalculateFogFactor(ref.viewSpacePosition.xyz, 5.0, mask) : ref.skyMask;
	color.a *= 1.0 - ref.fogFactor;

	ref.fogFactor = 1.0 - color.a;

    return color;
}


float CalculateLuminance(in vec3 color) {
	return (color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722);
}

float CalculateSunglow(in vec4 viewSpacePosition) {
	float curve = 4.0;

	vec3 npos = normalize(viewSpacePosition.xyz);
	vec3 halfvec2 = normalize(-lightVector + npos);
	float factor = 1.0 - dot(halfvec2, npos);

	return pow(factor, curve);
}

float CalculateAntiSunglow(in vec4 viewSpacePosition) {
	float curve = 4.0;

	vec3 npos = normalize(viewSpacePosition.xyz);
	vec3 halfvec2 = normalize(lightVector + npos);
	float factor = 1.0 - dot(halfvec2, npos);

	return factor * factor * factor * factor;
}

vec3 CalculateSunspot(in vec4 viewSpacePosition, in SpecularityStruct spec) {
	vec3 npos = normalize(viewSpacePosition.xyz);
	vec3 halfvec2 = normalize(-lightVector + npos);

	float sunProximity = abs(1.0 - dot(halfvec2, npos));

	float sizeFactor = 0.959;

	float sunSpot = (clamp(sunProximity, sizeFactor, 0.96) - sizeFactor) / (0.96 - sizeFactor);
		  sunSpot = pow(cubicPulse(1.0, 1.0, sunSpot), 5000.0);
		  sunSpot *= spec.sunlightVisibility;
		  sunSpot *= 0.001;
		  sunSpot *= 1.0 - timeMoon;
		  sunSpot *= 1.0 - timeMidnight;
		  sunSpot *= 1.0 - pow(horizonTime, 0.1);

	return vec3(sunSpot) * colorSunglow;
}

Intersection RayPlaneIntersectionWorld(in vec3 ray, in Plane plane) {
	float rayPlaneAngle = dot(ray, plane.normal);

	float planeRayDist = 100000000.0;
	vec3 intersectionPos = ray * planeRayDist;

	if (rayPlaneAngle > 0.0001 || rayPlaneAngle < -0.0001) {
		planeRayDist = dot((plane.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray * planeRayDist;
		intersectionPos = -intersectionPos;

		intersectionPos += cameraPosition.zyx ;// + vec3(6000.0, 0.0, 0.0);
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}


float GetCoverage(in float coverage, in float density, in float clouds) {
	clouds = clamp(clouds - (1.0 - coverage), 0.0, 1.0 - density) / (1.0 - density);
	clouds = max(0.0, clouds * 1.1 - 0.1);

	return clouds;
}

vec4 CloudColor2(in vec4 worldPosition, in float sunglow, in float altitude, in float thickness) {
	float cloudHeight = altitude;
	float cloudDepth  = thickness;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0);

	vec3 p = worldPosition.xyz / 100.0;

	float t = cameraPosition.x * -0.075;// frameTimeCounter * 0.4;

	p += (Get3DNoise(p * 2.0 + vec3(0.0, t * 0.01, 0.0)) * 2.0 - 1.0) * 0.10;

	p.x -= (Get3DNoise(p * 0.125 + vec3(0.0, t * 0.01, 0.0)) * 2.0 - 1.0) * 1.2;


	p.x *= 0.25;
	p.x -= t * 0.01;

	vec3 p1 = p * vec3(1.0, 0.5, 1.0)  + vec3(0.0, t * 0.01, 0.0);
	float noise;
	      noise = Get3DNoise(p * vec3(1.0, 0.5, 1.0) + vec3(0.0, t * 0.01, 0.0));

	p *= 2.0;
	p.x -= t * 0.017;
	p.z += noise * 1.35;
	p.x += noise * 0.5;
	vec3 p2 = p;
	noise += (2.0 - abs(Get3DNoise(p) * 2.0 - 0.0)) * (0.25);

	p *= 3.0;
	p.xz -= t * 0.005;
	p.z += noise * 1.35;
	p.x += noise * 0.5;
	p.x *= 3.0;
	p.z *= 0.55;
	vec3 p3 = p;

	p.z -= (Get3DNoise(p * 0.25 + vec3(0.0, t * 0.01, 0.0)) * 2.0 - 1.0) * 0.4;
	noise += (3.0 - abs(Get3DNoise(p) * 3.0 - 0.0)) * (0.045);
	p *= 3.0;
	p.xz -= t * 0.005;
	vec3 p4 = p;
	noise += (3.0 - abs(Get3DNoise(p) * 3.0 - 0.0)) * (0.025);

	p *= 3.0;
	p.xz -= t * 0.005;
	noise += ((Get3DNoise(p))) * (0.022);
	p *= 3.0;
	noise += ((Get3DNoise(p))) * (0.014);
	noise /= 1.575;

	float coverage = 0.55;

	float dist = length(worldPosition.xz - cameraPosition.xz);
//	coverage *= max(0.0, 1.0 - dist / 10000.0);
	float density = 0.0;

	noise = GetCoverage(coverage, density, noise);
	noise = noise * noise * (3.0 - 2.0 * noise);

	const float lightOffset = 0.2;

	vec3 worldLightVector = (gbufferModelViewInverse * vec4(lightVector, 0.0)).xyz;

	float sundiff = Get3DNoise(p1 + worldLightVector * lightOffset);
		  sundiff += (2.0 - abs(Get3DNoise(p2 + worldLightVector * lightOffset / 2.0) * 2.0 - 0.0)) * (0.55);

	float largeSundiff = sundiff;
	      largeSundiff = -GetCoverage(coverage, 0.0, largeSundiff * 1.3);

	sundiff += (3.0 - abs(Get3DNoise(p3 + worldLightVector * lightOffset / 5.0) * 3.0 - 0.0)) * (0.065);
	sundiff += (3.0 - abs(Get3DNoise(p4 + worldLightVector * lightOffset / 8.0) * 3.0 - 0.0)) * (0.025);
	sundiff /= 1.5;
	sundiff  = -GetCoverage(coverage, 0.0, sundiff);

	float secondOrder 	= pow(clamp(sundiff + 1.35, 0.0, 1.0), 7.0);


	float directLightFalloff = secondOrder;
	float anisoBackFactor = mix(clamp(pow(noise, 1.6) * 2.5, 0.0, 1.0), 1.0, pow(sunglow, 1.0));

	directLightFalloff *= anisoBackFactor;
	directLightFalloff *= mix(10.0, 0.5, pow(sunglow, 0.5));


	vec3 colorDirect = colorSunlight * 1.915;
		 colorDirect = mix(colorDirect, colorDirect * vec3(0.2, 0.5, 1.0), timeMidnight);
		 colorDirect *= 1.0 + pow(sunglow, 2.0) * 100.0 * pow(directLightFalloff, 1.1);


	vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0, vec3(0.15)) * 0.04;
		 colorAmbient *= mix(1.0, 0.3, timeMidnight);


	vec3 color = mix(colorAmbient, colorDirect, min(1.0, directLightFalloff));

	vec4 result = vec4(color, noise * 0.5);

	return result;
}

vec3 CloudPlane(in vec4 viewSpacePosition, in float fogFactor) {
	vec4 worldVector = gbufferModelViewInverse * (-viewSpacePosition);
		 worldVector = worldVector.zyxw;

	vec3 viewRay = normalize(worldVector.xyz);

	float sunglow = CalculateSunglow(viewSpacePosition);


	float cloudsAltitude = 410.0 + 129.0 + 64.0;
	float cloudsThickness = 150.0;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5;

	float density = fogFactor;

	float planeHeight = cloudsUpperLimit;
	float stepSize = 25.5;
	planeHeight -= cloudsThickness * 0.85;


	Plane pl;
	pl.origin = vec3(0.0, cameraPosition.y - planeHeight, 0.0);
	pl.normal = vec3(0.0, 1.0, 0.0);

	Intersection i = RayPlaneIntersectionWorld(viewRay, pl);

	vec3 color;

	if (i.angle < 0.0) {
		vec4 cloudSample = CloudColor2(vec4(i.pos.xyz * 0.5 + vec3(30.0), 1.0), sunglow, cloudsAltitude, cloudsThickness);
			 cloudSample.a = min(1.0, cloudSample.a * density);

		color = mix(color, cloudSample.rgb, cloudSample.a);

		cloudSample = CloudColor2(vec4(i.pos.xyz * 0.65 + vec3(10.0) + vec3(i.pos.z * 0.5, 0.0, 0.0), 1.0), sunglow, cloudsAltitude, cloudsThickness);
		cloudSample.a = min(1.0, cloudSample.a * density);

		color = mix(color, cloudSample.rgb, cloudSample.a);

		return color * 0.00025;
	}
}

vec3 AddSunglow(in vec4 viewSpacePosition) {
	float sunglowFactor = CalculateSunglow(viewSpacePosition);
	float antiSunglowFactor = CalculateAntiSunglow(viewSpacePosition);

	vec3 color = vec3(1.0);
	color *= 1.0 + pow(sunglowFactor, 2.0) * (1.0 + timeNoon * 7.0) * (1.0 - horizonTime);
	color *= 1.0 + pow(sunglowFactor, 8.0) * 20.0 * (1.0 + timeNoon * 7.0) * (1.0 - horizonTime);
	color *= mix(vec3(1.0), colorSunlight * 11.0, pow(clamp(vec3(sunglowFactor) * (1.0 - timeMidnight) * (1.0 - horizonTime), vec3(0.0), vec3(1.0)), vec3(2.0)));
	color *= 1.0 + antiSunglowFactor * 2.0 * (1.0 - horizonTime);

	return color ; // * mix(vec3(1.0), vec3(1.9, 0.6, 0.4), clamp(pow(sunglowFactor, 2.0) * 4.0 * timeSunriseSunset, 0.0, 1.4));
}

vec3 CalculateSkyGradient(in vec4 viewSpacePosition) {
	float curve = 5.0;
	vec3 npos = normalize(viewSpacePosition.xyz);
	vec3 halfvec2 = normalize(-normalize(upPosition) + npos);
	float skyGradientFactor = dot(halfvec2, npos);
	float skyDirectionGradient = skyGradientFactor;

	if (dot(halfvec2, npos) > 0.75)
		skyGradientFactor = 1.5 - skyGradientFactor;

	skyGradientFactor = pow(skyGradientFactor, curve);

	vec3 color = CalculateLuminance(pow(gl_Fog.color.rgb, vec3(2.2)) * 0.001) * colorSkylight;

	color *= mix(skyGradientFactor, 1.0, clamp((0.12 - (timeNoon * 0.1)), 0.0, 1.0));
	color *= mix(1.0, 5.0, timeMidnight);
	color *= pow(skyGradientFactor, 2.5) + 0.2;
	color *= (pow(skyGradientFactor, 1.1) + 0.425) * 0.5;
	color.g *= skyGradientFactor + 1.0;


	float fade1 = clamp(skyGradientFactor - 0.05, 0.0, 0.2) / 0.2;
		  fade1 = fade1 * fade1 * (3.0 - 2.0 * fade1);
	//vec3 color1 = vec3(12.0, 8.0, 4.7) * 0.15;
	vec3 color1 = vec3(4.0);
		 color1 *= mix(1.0, 0.1, timeMidnight);
		 color1 = mix(color1, vec3(2.0, 0.55, 0.2), vec3(timeSunriseSunset));

	color *= mix(vec3(1.0), color1, vec3(fade1));

	float fade2 = clamp(skyGradientFactor - 0.11, 0.0, 0.2) / 0.2;
	vec3 color2 = vec3(2.7, 1.0, 2.8) / 20.0;
		 color2 = mix(color2, vec3(1.0, 0.15, 0.5), vec3(timeSunriseSunset));


	color *= mix(vec3(1.0), color2, vec3(fade2 * 0.5));


	float horizonGradient = 1.0 - distance(skyDirectionGradient, 0.72) / 0.72;
		  horizonGradient = pow(horizonGradient, 10.0);
		  horizonGradient = max(0.0, horizonGradient);

	float sunglow = CalculateSunglow(viewSpacePosition);
		  horizonGradient *= sunglow * 2.0 + (0.65 - timeSunriseSunset * 0.55);

	vec3 horizonColor1 = vec3(1.5, 1.5, 1.5);
		 horizonColor1 = mix(horizonColor1, vec3(1.5, 1.95, 1.5) * 2.0, vec3(timeSunriseSunset));
	vec3 horizonColor2 = vec3(1.5, 1.2, 0.8);
		 horizonColor2 = mix(horizonColor2, vec3(1.9, 0.6, 0.4) * 2.0, vec3(timeSunriseSunset));

	color *= mix(vec3(1.0), horizonColor1, vec3(horizonGradient) * (1.0 - timeMidnight) * (1.0 - horizonTime));
	color *= mix(vec3(1.0), horizonColor2, vec3(pow(horizonGradient, 2.0)) * (1.0 - timeMidnight) * (1.0 - horizonTime));


	vec3 linFogcolor = pow(gl_Fog.color.rgb, vec3(2.2));

	float fogLum = max(max(linFogcolor.r, linFogcolor.g), linFogcolor.b);

	float grayscale = fogLum / 30.0;

	color /= fogLum;

	color *= 25.0;

	return color;
}

vec4 CalculateSky(in vec3 color, in vec4 viewSpacePosition, in SpecularityStruct spec, in MaskStruct mask) {
	float	fogFactor	= (fogEnabled > 0.5) ? CalculateFogFactor(viewSpacePosition.xyz, 5.0, mask) : mask.sky;
	vec3	gradient	= CalculateSkyGradient(viewSpacePosition);
	vec3	sunspot		= CalculateSunspot(viewSpacePosition, spec);
	vec3	sunglow		= AddSunglow(viewSpacePosition);
	vec3	clouds		= CloudPlane(viewSpacePosition, pow(fogFactor, 20.0));
	vec4	composite;

	composite.rgb = gradient	* sunglow
	//		      + sunspot		* sunglow
			      + clouds		* pow(sunglow, vec3(0.25))
			      ;

	composite.a = mix(mask.sky, fogFactor, fogEnabled);

	return composite;
}

vec4 CalculateReflectedSky(in vec4 viewSpacePosition, in vec3 normal, in ReflectionStruct ref, in SpecularityStruct spec) {
	vec4 composite;

	float viewVector		= dot(normalize(viewSpacePosition.xyz), normal);
	composite.a				= pow(clamp(1.0 + viewVector, 0.0, 1.0), spec.fresnelPower) * (1.0 - spec.baseSpecularity) + spec.baseSpecularity;

	viewSpacePosition.xyz	= reflect(viewSpacePosition.xyz, normal);

	float	fogFactor		= (fogEnabled > 0.5) ? ref.fogFactor : ref.skyMask;
	vec3	gradient		= CalculateSkyGradient(viewSpacePosition);
	vec3	sunspot			= CalculateSunspot(viewSpacePosition, spec);
	vec3	sunglow			= AddSunglow(viewSpacePosition);
	vec3	clouds			= CloudPlane(viewSpacePosition, pow(fogFactor, 20.0));

	composite.rgb = gradient	* sunglow * 0.3
	//			  + sunspot		* sunglow * 20.0
				  + clouds		* pow(sunglow, vec3(0.25))
				  ;

	return composite;
}

void CalculateSpecularReflections(inout vec3 color, in vec4 viewSpacePosition, in vec3 normal, in SpecularityStruct spec, in MaskStruct mask) {
	ReflectionStruct ref;

	vec4 reflection = ComputeRaytraceReflection(viewSpacePosition, normal, ref, mask);

	vec4 fakeSkyReflection = CalculateReflectedSky(viewSpacePosition, normal, ref, spec);

	fakeSkyReflection.rgb = mix(vec3(0.0), fakeSkyReflection.rgb, spec.skylightVisibility);
	reflection.rgb = mix(fakeSkyReflection.rgb, reflection.rgb, reflection.a);

	color = mix(color, reflection.rgb, fakeSkyReflection.a);
}

vec3 convertToHDR(in vec3 color) {
  vec3 hdrImage;

  vec3 overExposed = color * 6666.0;
  vec3 underExposed = color / 1.20;

  hdrImage = mix(underExposed, overExposed, color);

  return hdrImage;
}

vec3 desaturationFilter(in vec3 color) {
	vec3 desaturatedImage;

	vec3 desat1 = color * 1.0;
	vec3 desat2 = color / 2.0;

	desaturatedImage = mix(desat1, desat2, color);

	return desaturatedImage;
}


//////////////////////////////MAIN////////////////////////////////////////////////////////////
//////////////////////////////MAIN////////////////////////////////////////////////////////////

void main() {
	CalculateMasks(mask);

	vec3  color             = pow(texture2D(colortex2, texcoord).rgb, vec3(2.2));
	vec3  normal            = GetNormals(texcoord);
	float depth             = GetDepth(texcoord);
	vec4  viewSpacePosition	= GetViewSpacePosition(texcoord, depth);

	spec.fresnelPower			= 6.0;
	spec.baseSpecularity		= 0.02;
	spec.sunlightVisibility		= max(GetSunlightVisibility(texcoord), mask.sky);
	spec.skylightVisibility		= clamp(pow(GetLightmapSky(texcoord) * 1.15, 2.0), 0.0, 1.0);

	if (mask.water > 0.5)
		CalculateSpecularReflections(color, viewSpacePosition, normal, spec, mask);


	vec4 sky = CalculateSky(color, viewSpacePosition, spec, mask);


	if (mask.brick > 0.5)
		color *= 0.0;

	color = mix(color, sky.rgb, sky.a);
	color = convertToHDR(color);
//	color = desaturationFilter(color);

	TonemapReinhard05(color);

	gl_FragColor = vec4(color, 1.0);
}
