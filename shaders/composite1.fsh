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
#define SOFT_SHADOWS
#define SCALE_FACTOR 1.0
#define CUSTOM_TIME_CYCLE

#define SKY_ABSORBANCE
uniform sampler2D depthtex1;

//////////////////////////////INTERNAL VARIABLES////////////////////////////////////////////////////////////
//////////////////////////////INTERNAL VARIABLES////////////////////////////////////////////////////////////
//Do not change the name of these variables or their type. The Shaders Mod reads these lines and determines values to send to the inner-workings
//of the shaders mod. The shaders mod only reads these lines and doesn't actually know the real value assigned to these variables in GLSL.
//Some of these variables are critical for proper operation. Change at your own risk.

const int shadowMapResolution 	    = 3072;
const float shadowDistance          = 200.0;
const float shadowIntervalSize      = 0.0001;
const bool shadowHardwareFiltering0 = true;

const bool shadowtex1Mipmap    = true;
const bool shadowtex1Nearest   = true;
const bool shadowcolor0Mipmap  = true;
const bool shadowcolor0Nearest = false;
const bool shadowcolor1Mipmap  = true;
const bool shadowcolor1Nearest = false;

/*
const int colortex0Format 		= RGB16;
const int colortex1Format 		= RGB8;
const int colortex2Format 		= RGB16;
const int colortex3Format 		= RGB16;
const int colortex4Format 		= RGB8;
*/

#define RESOLUTION sqrt(2.0)

const float sunPathRotation       = -40.0;
const float ambientOcclusionLevel = 0.65;

const int noiseTextureResolution  = 64;

const bool colortex4MipmapEnabled	= true;

#define PI 3.1415926535
const float rad = 0.01745329;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex3;
uniform sampler2D gdepthtex;
uniform sampler2DShadow shadow;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#define track cameraPosition.x

uniform vec3 upPosition;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;

in vec3 lightVector;
in vec3 colorSunlight;
in vec3 colorSkylight;
in vec3 colorBouncedSunlight;
in vec3 colorTorchlight;
in vec3 colorWaterMurk;

in vec2 texcoord;

in float timeMidnight;
in float fogEnabled;

in mat4 shadowView;
in mat4 shadowViewInverse;

in float timeCycle;
in float timeAngle;
in float pathRotationAngle;
in float twistAngle;

/* DRAWBUFFERS:21 */


//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////

//#define texture2D(a, b) texelFetch(a, ivec2(b * vec2(viewWidth, viewHeight)), 0)

#include "include/animation.glsl"

//Get gbuffer textures
vec3 GetDiffuseLinear(in vec2 coord) {
	return pow(texture2D(colortex2, coord).rgb, vec3(2.2));
}

vec3 GetNormals(in vec2 coord) {
	return texture2DLod(colortex0, coord.st, 0).rgb * 2.0 - 1.0;
}

float GetDepth(in vec2 coord) {
	return texture2D(gdepthtex, coord).r;
}

float GetDepthLinear(in vec2 coord) {
	return 2.0 * near * far / (far + near - (2.0 * texture2D(gdepthtex, coord).x - 1.0) * (far - near));
}

float ExpToLinearDepth(in float depth) {
	return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}


vec4 GetViewSpacePosition(in vec2 coord, in float depth) {		//Function that calculates the view-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	vec4 fragposition = gbufferProjectionInverse * vec4(vec3(coord.st, depth) * 2.0 - 1.0, 1.0);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 ViewSpaceToWorldSpace(in vec4 viewSpacePosition) {
	return gbufferModelViewInverse * viewSpacePosition;
}

vec4 WorldSpaceToShadowSpace(in vec4 worldSpacePosition) {
	return shadowProjection * shadowView * worldSpacePosition;
}

//Lightmaps
float GetLightmapTorch(in vec2 coord) {
	float lightmap = texture2D(colortex1, coord).g;

	//Apply inverse square law and normalize for natural light falloff
	lightmap  = pow(lightmap, 3.0);
	lightmap  = clamp(lightmap * 1.22, 0.0, 1.0);
	lightmap  = 1.0 - lightmap;
	lightmap *= 5.6;
	lightmap  = 1.0 / pow((lightmap + 0.8), 2.0);
	lightmap -= 0.025;

	lightmap  = max(0.0, lightmap);
	lightmap *= 0.008;
	lightmap  = clamp(lightmap, 0.0, 1.0);
	lightmap  = pow(lightmap, 0.9);
	return lightmap;
}

float GetLightmapSky(in vec2 coord) {
	return pow(texture2D(colortex1, coord).b, 4.3);
}


//Material IDs
float GetMaterialIDs(in vec2 coord) {		//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(colortex1, coord).r;
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



void rotate(inout vec2 vector, float degrees) {
	degrees *= 0.0174533;		//Convert from degrees to radians

	vector *= mat2(cos(degrees), -sin(degrees),
	              sin(degrees),  cos(degrees));
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

vec3 BiasShadowProjection(in vec3 position) {
	return position / vec3(vec2(GetShadowBias(position.xy)), 4.0);
}


void DoNightEye(inout vec3 color, in float amount) {	//Desaturates any color input at night, simulating the rods in the human eye
	amount *= 0.8;										//How much will the new desaturated and tinted image be mixed with the original image
	vec3 rodColor = vec3(0.2, 0.4, 1.0); 				//Cyan color that humans percieve when viewing extremely low light levels via rod cells in the eye
	float colorDesat = dot(color, vec3(1.0));	 		//Desaturated color

	color = mix(color, vec3(colorDesat) * rodColor, timeMidnight * amount);
}

void DoLowlightEye(inout vec3 color, in float amount) {	//Desaturates any color input at night, simulating the rods in the human eye
	amount *= 0.8;		 								//How much will the new desaturated and tinted image be mixed with the original image
	vec3 rodColor = vec3(0.2, 0.4, 1.0); 				//Cyan color that humans percieve when viewing extremely low light levels via rod cells in the eye
	float colorDesat = dot(color, vec3(1.0)); 			//Desaturated color

	color = mix(color, vec3(colorDesat) * rodColor, amount);
}


float CalculateLuminance(in vec3 color) {
	return (color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722);
}

vec3 Glowmap(in vec3 diffuse, in float mask, in float curve, in vec3 emissiveColor) {
	vec3 color = diffuse * (mask);
		 color = pow(color, vec3(curve));
		 color = vec3(CalculateLuminance(color));
		 color *= emissiveColor;

	return color;
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
	float ice;
	float hand;
	float goldBlock;

	float torch;
	float lava;
	float glowstone;

	float water;
} mask;

struct FragmentStruct {
	MaskStruct mask;

	vec3  diffuse;
	vec3  normal;
	float depth;
	float linearDepth;

	vec4  viewSpacePosition;
	vec3  viewVector;
	float NdotL;

	float shadow;
} frag;

struct LightmapStruct {
	vec3 sunlight;
	vec3 skylight;
	vec3 torchlight;
	vec3 nolight;
	vec3 fullbright;
} lightmap;

struct ShadingStruct {
	float direct;
	float skylight;
	float sunlightVisibility;
	float sky;
	float torch;
	float fullbright;
} shading;

struct GlowStruct {
	vec3	torch;
	vec3	lava;
	vec3	glowstone;
};

struct FinalStruct {
	GlowStruct glow;

	vec3 sunlight;
	vec3 skylight;
	vec3 torchlight;
	vec3 nolight;
	vec3 fullbright;
	vec3 composite;
} final;

/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void CalculateMasks(inout MaskStruct mask) {
	mask.materialIDs = GetMaterialIDs(texcoord);
	mask.matIDs      = mask.materialIDs;

	ExpandMaterialIDs(mask.matIDs, mask.fullbright, mask.bit1, mask.bit2, mask.bit3);

	mask.sky = GetSkyMask(mask.matIDs);

	mask.grass     = GetMaterialMask(2, mask.matIDs);
	mask.leaves    = GetMaterialMask(3, mask.matIDs);
	mask.water     = GetMaterialMask(4, mask.matIDs);
	mask.ice       = GetMaterialMask(5, mask.matIDs);
	mask.goldBlock = GetMaterialMask(6, mask.matIDs);
	mask.torch     = GetMaterialMask(7, mask.matIDs);
	mask.lava      = GetMaterialMask(8, mask.matIDs);
	mask.glowstone = GetMaterialMask(9, mask.matIDs);
}


float CalculateDirectLighting(in float NdotL, in MaskStruct mask) {
	return max(0.0, NdotL * 0.99 + 0.01) * (1.0 - mask.grass - mask.leaves) + mask.grass + mask.leaves;
}


float CalculateSunlightVisibility(in vec4 viewSpacePosition, in float directShading) {
	if (directShading < 0.0) return 1.0;

	vec4 position = vec4((texture2D(colortex3, texcoord).rgb - 0.5) * 528.0, 1.0);

	position     = WorldSpaceToShadowSpace(position);
	position.xyz = BiasShadowProjection(position.xyz);
	position     = position * 0.5 + 0.5; //Transform from shadow space to shadow map coordinates

	float shading = shadow2D(shadow, vec3(position.xyz)).x;

	shading *= shading;

	return shading;
}

float CalculateBouncedSunlight(in float NdotL) {
	float bounced = clamp(-NdotL + 0.95, 0.0, 1.95) / 1.95;
		  bounced = pow(bounced, 3.0);

	return bounced;
}

float CalculateScatteredSunlight(in float NdotL) {
	float scattered = clamp(NdotL * 0.75 + 0.25, 0.0, 1.0);

	return scattered;
}

float CalculateSkylight(in vec3 normal, in vec3 upVector) {
	float skylight = dot(normal, upVector);
		  skylight = skylight * 0.45 + 0.55;

	return skylight;
}


vec3 BilateralUpsample(const in float scale, in vec2 offset, in float depth, in vec3 normal, in sampler2D sampler) {
	vec2 recipres = vec2(1.0 / viewWidth, 1.0 / viewHeight);

	vec3 light = vec3(0.0);
	float weights = 0.0;

	for (float i = -0.5; i <= 0.5; i += 1.0) {
		for (float j = -0.5; j <= 0.5; j += 1.0) {
			vec2 coord = vec2(i, j) * recipres * 2.0;

			float sampleDepth = GetDepthLinear(texcoord + coord * 2.0 * (exp2(scale)));
			vec3 sampleNormal = GetNormals(texcoord + coord * 2.0 * (exp2(scale)));

			float weight = clamp(1.0 - abs(sampleDepth - depth) / 2.0, 0.0, 1.0);
				  weight *= max(0.0, dot(sampleNormal, normal) * 2.0 - 1.0);
				  weight  = max(0.01, weight);

			light += pow(texture2DLod(sampler, (texcoord) * (1.0 / exp2(scale)) + offset + coord, 0).rgb, vec3(2.2)) * weight;

			weights += weight;
		}
	}

	light /= max(0.00001, weights);

	return light;
}

vec3 Delta(in float depth, vec3 diffuse, vec3 normal, float skylight) {
	vec3 delta = BilateralUpsample(SCALE_FACTOR, vec2(0.0, 0.0), depth, normal, colortex4);

	delta.rgb = delta.rgb * diffuse * colorSunlight;

	delta.rgb *= 5.0;// * (pow(skylight, 0.5) * 0.5 + 0.5);// * pow(skylight, 0.5);

	return delta;
}

float CalculateSkyAbsorbance(in vec4 viewSpacePosition, in vec3 normal, in sampler2D depthSampler) {
	float uDepth = texture2D(depthSampler, texcoord).x;
	vec4 uPos = GetViewSpacePosition(texcoord, uDepth);
		 uPos = ViewSpaceToWorldSpace(uPos);

	vec4 worldPos = gbufferModelViewInverse * viewSpacePosition;

	vec4 uVector = vec4(worldPos.xyz - uPos.xyz, 1.0);
		 uVector = gbufferModelView * uVector;

	float UNdotUP = abs(dot(normalize(uVector.xyz), normal));
	float depth = length(uVector.xyz) * UNdotUP;
		  depth = exp(-depth / 5.0);

	float fogFactor = CalculateFogFactor(uPos.xyz, 2.0);

	//return 1.0 - clamp(depth - fogFactor, 0.0, 1.0);
	return 1.0 - clamp(depth, 0.0, 1.0);
}

//////////////////////////////MAIN////////////////////////////////////////////////////////////
//////////////////////////////MAIN////////////////////////////////////////////////////////////

void main() {
	CalculateMasks(mask);

	if (mask.sky > 0.5) discard;

	vec3 diffuse = GetDiffuseLinear(texcoord);
	     diffuse = pow(diffuse, vec3(1.4)) * 1.65;


	vec3  normal            = GetNormals(texcoord);
	float depth             = GetDepth(texcoord);
	float linearDepth       = ExpToLinearDepth(depth);
	vec4  viewSpacePosition = GetViewSpacePosition(texcoord, depth);
	vec3  viewVector        = normalize(viewSpacePosition.xyz);
	float NdotL             = max(dot(normal, lightVector), 0.0);


	//Calculate frag shading
	shading.sky   		= GetLightmapSky(texcoord);

	shading.torch 		= GetLightmapTorch(texcoord);

	shading.direct		= CalculateDirectLighting(NdotL, mask);
	shading.direct	   *= CalculateSunlightVisibility(viewSpacePosition, shading.direct);
	shading.direct	   *= shading.sky;

	shading.skylight 	= CalculateSkylight(normal, normalize(upPosition));


	vec3 delta = Delta(linearDepth, diffuse.rgb, normal.xyz, shading.sky);


	//Colorize fragment shading and store in lightmaps
	lightmap.sunlight 			= vec3(shading.direct) * colorSunlight;

	lightmap.skylight 			= vec3(shading.sky * 0.95 + 0.05);
	lightmap.skylight 			*= mix(colorSkylight, colorBouncedSunlight, vec3(max(0.2, (1.0 - pow(shading.sky + 0.13, 1.0) * 1.0)))) + colorBouncedSunlight * (mix(0.4, 2.8, 0.0));
	lightmap.skylight 			*= shading.skylight;
	lightmap.skylight 			+= mix(colorSkylight, colorSunlight, vec3(0.2)) * vec3(shading.sky) * 0.05;

	lightmap.torchlight 		= shading.torch * colorTorchlight;

	lightmap.nolight 			= vec3(0.05);


	#ifdef SKY_ABSORBANCE
		if (mask.water > 0.5) diffuse = mix(diffuse, pow(colorWaterMurk, vec3(4.0)) * 0.002, CalculateSkyAbsorbance(viewSpacePosition, normal, depthtex1));
	#endif


	//Apply lightmaps to diffuse and generate final shaded fragment
	final.nolight 			= diffuse * lightmap.nolight;
	final.sunlight 			= diffuse * lightmap.sunlight;
	final.skylight 			= diffuse * lightmap.skylight;
	final.torchlight 		= diffuse * lightmap.torchlight;

	//final.glow.torch		= pow(diffuse, vec3(4.0)) * float(mask.torch);
	final.glow.lava			= pow(diffuse * mask.lava, vec3(0.65)) * 0.03;

	final.glow.glowstone	= Glowmap(diffuse, mask.glowstone, 2.0, colorTorchlight);

	final.glow.torch		= pow(diffuse * (mask.torch), vec3(4.4));

	//Remove glow items from torchlight to keep control
	final.torchlight *= 1.0 - mask.lava;
	final.torchlight *= 1.0 - mask.glowstone;


	//Do night eye effect on outdoor lighting and sky
	DoNightEye(final.sunlight, 1.0);
	DoNightEye(final.skylight, 1.0);
	DoNightEye(delta.rgb, 1.0);

	DoLowlightEye(final.nolight, 1.0);


	float sunlightMult = 1.0;

	//Apply lightmaps to diffuse and generate final shaded fragment
	final.composite = final.sunlight 			* 0.75		* sunlightMult
					+ delta.rgb 							* sunlightMult * 0.6
					+ final.skylight 			* 0.045		* 0.85
					+ final.nolight 			* 0.00035 / 0.05
					+ final.torchlight 			* 5.0 / 0.05
					+ final.glow.lava			* 2.6 / 0.05
					+ final.glow.glowstone		* 5.1 / 0.05
					+ final.glow.torch			* 1.15 / 0.05
					;


	final.composite *= 0.001;									//Scale image down for HDR
	final.composite = pow(final.composite, vec3(1.0 / 2.2));	//Convert final image into gamma 0.45 space to compensate for gamma 2.2 on displays

	gl_FragData[0].rgb = final.composite;
	gl_FragData[1].rgb = vec3(mask.materialIDs, shading.direct, shading.sky);
}
