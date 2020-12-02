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
uniform sampler2D colortex4;
uniform sampler2D gdepthtex;
uniform sampler2D noisetex;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float aspectRatio;
uniform float centerDepthSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform ivec2 eyeBrightnessSmooth;

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;

in vec2 texcoord;

in vec3 colorSunlight;
in vec3 colorSkylight;


//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////

vec3	GetTexture(in sampler2D tex, in vec2 coord)		//Perform a texture lookup with BANDING_FIX_FACTOR compensation
{
	return pow(texture2D(tex, coord).rgb, vec3(2.2));
}

vec3	GetTextureLod(in sampler2D tex, in vec2 coord, in int level)		//Perform a texture lookup with BANDING_FIX_FACTOR compensation
{
	return pow(texture2DLod(tex, coord, level).rgb, vec3(2.2));
}

vec3	GetTexture(in sampler2D tex, in vec2 coord, in int LOD)		//Perform a texture lookup with BANDING_FIX_FACTOR compensation and lod offset
{
	return texture2D(tex, coord, LOD).rgb;
}

float	GetDepth(in vec2 coord)
{
	return texture2D(gdepthtex, coord).x;
}

float	GetDepthLinear(in float depth)		//Function that retrieves the scene depth. 0 - 1, higher values meaning farther away
{
	return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec3	GetColorTexture(in vec2 coord)
{
	return GetTextureLod(colortex0, coord.st, 0).rgb;
}

float 	GetMaterialIDs(in vec2 coord)		//Function that retrieves the texture that has all material IDs stored in it
{
	return texture2D(colortex1, coord).r;
}

vec4	GetWorldSpacePosition(in vec2 coord)		//Function that calculates the view-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
{
	float depth = GetDepth(coord);

	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4	cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;

    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;

    return w / 6.0;
}

float	Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125, 0.7154, 0.0721));
}

float	GetFullbrightMask(in float matID)
{
	matID = matID * 255.0;

	if (matID >= 128.0 && matID < 254.5)
		return 1.0;
	else
		return 0.0;
}

float	GetMaterialMask(in int ID, in float matID)
{
	matID = matID * 255.0;

	//Catch last part of sky
	if (matID > 254.0)
		matID = 0.0;

	if (abs(matID - ID) < 0.1)
		return 1.0;
	else
		return 0.0;
}

void	Vignette(inout vec3 color)
{
	float dist = distance(texcoord, vec2(0.5)) * 2.0;
		  dist /= 1.5142;

	color.rgb *= 1.0 - dist;
}

float	CalculateDitherPattern1()
{
	int[16] ditherPattern = int[16] (0 , 9 , 3 , 11,
								 	 13, 5 , 15, 7 ,
								 	 4 , 12, 2,  10,
								 	 16, 8 , 14, 6 );

	vec2 count = vec2(0.0);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0));

	int dither = ditherPattern[int(count.x) + int(count.y) * 4];

	return float(dither) / 17.0;
}


void	CalculateExposure(inout vec3 color)
{
	float exposureMax = 1.55;
		  exposureMax *= mix(1.0, 0.25, timeSunriseSunset);
		  exposureMax *= mix(1.0, 0.0, timeMidnight);
		  exposureMax *= mix(1.0, 0.25, rainStrength);
	float exposureMin = 0.07;
	float exposure = pow(eyeBrightnessSmooth.y / 240.0, 6.0) * exposureMax + exposureMin;

	color.rgb /= vec3(exposure);
}


void SaturationBoost(inout vec3 color, in float satBoost)
{
	color.r = color.r * (1.0 + satBoost * 2.0) - (color.g * satBoost) - (color.b * satBoost);
	color.g = color.g * (1.0 + satBoost * 2.0) - (color.r * satBoost) - (color.b * satBoost);
	color.b = color.b * (1.0 + satBoost * 2.0) - (color.r * satBoost) - (color.g * satBoost);
}

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct BloomDataStruct
{
	vec3 blur0;
	vec3 blur1;
	vec3 blur2;
	vec3 blur3;
	vec3 blur4;
	vec3 blur5;
	vec3 blur6;

	vec3 bloom;
} bloomData;

struct MaskStruct
{
	float matIDs;

	float fullbright;

	float hand;
	float glowstone;
} mask;

struct FragmentStruct
{
	MaskStruct	mask;

	vec3	color;

	float	depth;
} frag;


/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void	CalculateMasks(inout MaskStruct mask)
{
	mask.fullbright 	= GetFullbrightMask(mask.matIDs);
	mask.matIDs			-= 128.0 / 255.0 * mask.fullbright;

	mask.glowstone 		= GetMaterialMask(9, mask.matIDs);

	mask.hand 			= GetMaterialMask(11, mask.matIDs);
}

void	CalculateBloom(inout BloomDataStruct bloomData)		//Retrieve previously calculated bloom textures
{
	//constants for bloom bloomSlant
	const float    bloomSlant = 0.25;
	const float[7] bloomWeight = float[7] (pow(7.0, bloomSlant),
										   pow(6.0, bloomSlant),
										   pow(5.0, bloomSlant),
										   pow(4.0, bloomSlant),
										   pow(3.0, bloomSlant),
										   pow(2.0, bloomSlant),
										   1.0
										   );

	vec2 recipres = vec2(1.0 / viewWidth, 1.0 / viewHeight);

	bloomData.blur0 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(2.0)) + vec2(0.0,		0.0 ) + vec2(0.000, 0.000)).rgb, vec3(2.2));
	bloomData.blur1 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(3.0)) + vec2(0.0,		0.25) + vec2(0.000, 0.025)).rgb, vec3(2.2));
	bloomData.blur2 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(4.0)) + vec2(0.125,		0.25) + vec2(0.025, 0.025)).rgb, vec3(2.2));
	bloomData.blur3 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(5.0)) + vec2(0.1875,		0.25) + vec2(0.050, 0.025)).rgb, vec3(2.2));
	bloomData.blur4 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(6.0)) + vec2(0.21875,	0.25) + vec2(0.075, 0.025)).rgb, vec3(2.2));
	bloomData.blur5 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(7.0)) + vec2(0.25,		0.25) + vec2(0.100, 0.025)).rgb, vec3(2.2));
	bloomData.blur6 = pow(texture2D(colortex2, (texcoord - recipres * 0.5) * (1.0 / exp2(8.0)) + vec2(0.28,		0.25) + vec2(0.125, 0.025)).rgb, vec3(2.2));

 	bloomData.bloom  = bloomData.blur0 * bloomWeight[0];
 	bloomData.bloom += bloomData.blur1 * bloomWeight[1];
 	bloomData.bloom += bloomData.blur2 * bloomWeight[2];
 	bloomData.bloom += bloomData.blur3 * bloomWeight[3];
 	bloomData.bloom += bloomData.blur4 * bloomWeight[4];
 	bloomData.bloom += bloomData.blur5 * bloomWeight[5];
 	bloomData.bloom += bloomData.blur6 * bloomWeight[6];
}

void	AddRainFogScatter(inout FragmentStruct frag, in BloomDataStruct bloomData)
{
	const float    bloomSlant = 0.0;
	const float[7] bloomWeight = float[7] (pow(7.0, bloomSlant),
										   pow(6.0, bloomSlant),
										   pow(5.0, bloomSlant),
										   pow(4.0, bloomSlant),
										   pow(3.0, bloomSlant),
										   pow(2.0, bloomSlant),
										   1.0
										   );

	vec3 fogBlur = bloomData.blur0 * bloomWeight[6] +
			       bloomData.blur1 * bloomWeight[5] +
			       bloomData.blur2 * bloomWeight[4] +
			       bloomData.blur3 * bloomWeight[3] +
			       bloomData.blur4 * bloomWeight[2] +
			       bloomData.blur5 * bloomWeight[1] +
			       bloomData.blur6 * bloomWeight[0];

	float fogTotalWeight = 	1.0 * bloomWeight[0] +
			       			1.0 * bloomWeight[1] +
			       			1.0 * bloomWeight[2] +
			       			1.0 * bloomWeight[3] +
			       			1.0 * bloomWeight[4] +
			       			1.0 * bloomWeight[5] +
			       			1.0 * bloomWeight[6];

	fogBlur /= fogTotalWeight;

	float linearDepth = GetDepthLinear(frag.depth);

	float fogDensity = 0.043 * (rainStrength);
	float visibility = 1.0 / (pow(exp(linearDepth * fogDensity), 1.0));
	float fogFactor = 1.0 - visibility;
		  fogFactor = clamp(fogFactor, 0.0, 1.0);
		  fogFactor *= mix(0.0, 1.0, eyeBrightnessSmooth.y / 240.0);

	frag.color = mix(frag.color, fogBlur, fogFactor);
}

void	MotionBlur(inout FragmentStruct frag)
{
	float sampleCount;
	const float maxSampleCount = 100.0;
	const float shutterAngle = 60.0;

	vec4 currentPosition = vec4(vec3(texcoord, frag.depth) * 2.0 - 1.0, 1.0);

	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * (shutterAngle / 360.0);
	float maxVelocity = 0.05;
	velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));

	sampleCount = length(vec2(velocity.s * viewWidth, velocity.t * viewHeight));
	sampleCount = floor(min(sampleCount, maxSampleCount));

	velocity /= sampleCount;

	float dither = CalculateDitherPattern1();

	frag.color -= frag.color * min(sampleCount, 1.0);

	float samples = 0.0;

	for (int i = 0; i < int(sampleCount); ++i)
	{
		vec2 coord = texcoord + velocity * (i - 0.5);
			 coord += vec2(dither) * 1.2 * velocity;
			 coord = clamp(coord, 1.0 / vec2(viewWidth, viewHeight), 1.0 - 1.0 / vec2(viewWidth, viewHeight));

		frag.color += GetColorTexture(coord).rgb;
		samples += 1.0;
	}

	frag.color /= max(samples, 1.0);
}

void	DepthOfField(inout FragmentStruct frag)
{
	float cursorDepth = centerDepthSmooth;


	const float blurclamp = 0.014;  // max blur amount
	const float bias = 0.15;		//aperture - bigger values for shallower depth of field


	vec2 aspectcorrect = vec2(1.0, aspectRatio) * 1.5;

	float depth = frag.depth;
		  depth += float(frag.mask.hand) * 0.36;

	float factor = (depth - cursorDepth);

	vec2 dofblur = vec2(factor * bias)*0.6;


	vec3 col = frag.color;

	col += GetColorTexture(texcoord + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur);

	col += GetColorTexture(texcoord + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur*0.9);

	col += GetColorTexture(texcoord + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.7);

	col += GetColorTexture(texcoord + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.4);

	frag.color = col/41;
}

void	TonemapReinhard05(inout vec3 color)
{
	float averageLuminance = 0.000065;

	vec3 IAverage = vec3(averageLuminance);

	vec3 value = color.rgb / (color.rgb + IAverage);

	color.rgb = value;
	color.rgb = min(color.rgb, vec3(1.0));
	color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;

    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);

    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{
	frag.mask.matIDs = GetMaterialIDs(texcoord);
	CalculateMasks(frag.mask);

	frag.color				= GetColorTexture(texcoord);
	frag.depth				= GetDepth(texcoord);

	if (frag.mask.hand > 0.5) frag.depth = 1.0;

	//MotionBlur(frag);

	if (frag.mask.hand > 0.5) frag.depth = 0.0;

	CalculateBloom(bloomData);

	//frag.color = mix(frag.color, pow(bloomData.bloom, vec3(1.03)), vec3(0.013));
	frag.color += pow(bloomData.bloom, vec3(1.03)) * 0.013;

	AddRainFogScatter(frag, bloomData);

	Vignette(frag.color);

	//CalculateExposure(frag.color);

	frag.color /= 1.5;

	TonemapReinhard05(frag.color);

	SaturationBoost(frag.color.rgb, (1.0 - pow(rgb2hsv(frag.color.rgb).g, 1.0)) * 0.1);

	gl_FragColor = vec4(frag.color.rgb, 1.0);
	//gl_FragColor = vec4(texture2D(colortex4, texcoord).rgb, 1.0);
}
