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

#define CUSTOM_TIME_CYCLE

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
#define track cameraPosition.x
uniform vec3 previousCameraPosition;

uniform float frameTimeCounter;
uniform float rainStrength;
uniform float sunAngle;
uniform float far;

out vec3 lightVector;
out vec3 colorSunlight;
out vec3 colorSkylight;
out vec3 colorSunglow;
out vec3 colorBouncedSunlight;
out vec3 colorScatteredSunlight;
out vec3 colorTorchlight;
out vec3 colorWaterMurk;
out vec3 colorWaterBlue;
out vec3 colorSkyTint;

out vec2 texcoord;

out float timeNoon;
out float timeMidnight;
out float timeSunriseSunset;
out float horizonTime;
out float timeSun;
out float timeMoon;
out float fogEnabled;

out mat4 shadowView;
out mat4 shadowViewInverse;

out float timeCycle;
out float timeAngle;
out float pathRotationAngle;
out float twistAngle;

const float rayleigh = 0.02;
const float sunPathRotation = -40.0;
#define PI 3.1415926535
const float rad = 0.01745329;


#include "include/animation.glsl"

void rotate(inout vec2 vector, float degrees) {
	degrees *= 0.0174533;		//Convert from degrees to radians

	vector *= mat2(cos(degrees), -sin(degrees),
				   sin(degrees),  cos(degrees));
}

#include "include/CalculateShadowView.glsl"

void main() {
	CalculateShadowView();

	texcoord    = gl_MultiTexCoord0.st;
	gl_Position = ftransform();


	float isNight = CalculateShadowView();

	lightVector = normalize((gbufferModelView * shadowViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);

	vec3 sunVector = lightVector ;// * (1.0 - isNight * 2.0);

	float LdotUp = dot(normalize(upPosition), sunVector);
	float LdotDown = -LdotUp;

	float timePow		= 4.0;

	horizonTime			= CubicSmooth(clamp01((1.0 - abs(LdotUp)) * 4.0 - 3.0));

	timeNoon			= 1.0 - pow(1.0 - clamp01(LdotUp), timePow);
	timeMidnight		= 1.0 - pow(1.0 - clamp01(LdotDown), timePow);
	timeMidnight		= 1.0 - pow(1.0 - timeMidnight, 2.0);

	timeSunriseSunset	= 1.0 - timeNoon;
	timeSunriseSunset	*= 1.0 - timeMidnight;
	timeSun				= float(timeNoon > 0.0);
	timeMoon			= float(timeMidnight > 0.0);


	colorWaterMurk = vec3(0.2, 0.5, 0.95);
	colorWaterBlue = vec3(0.2, 0.5, 0.95);
	colorWaterBlue = mix(colorWaterBlue, vec3(1.0), vec3(0.5));


	//colors for shadows/sunlight and sky
	vec3 sunrise_sun;
	sunrise_sun.r = 1.00;
	sunrise_sun.g = 0.58;
	sunrise_sun.b = 0.00;
	sunrise_sun *= 0.65 * 0.5 * timeSun;

	vec3 sunrise_amb;
	sunrise_amb.r = 0.30;
	sunrise_amb.g = 0.595;
	sunrise_amb.b = 0.70;


	vec3 noon_sun;
	noon_sun.r = mix(1.00, 1.00, rayleigh);
	noon_sun.g = mix(1.00, 0.75, rayleigh);
	noon_sun.b = mix(1.00, 0.00, rayleigh);

	vec3 noon_amb;
	noon_amb.r = 0.0 ;
	noon_amb.g = 0.3  ;
	noon_amb.b = 0.999;


	vec3 midnight_sun;
	midnight_sun.r = 0.3;
	midnight_sun.g = 0.3;
	midnight_sun.b = 0.3;

	vec3 midnight_amb;
	midnight_amb.r = 0.0 ;
	midnight_amb.g = 0.23;
	midnight_amb.b = 0.99;


	colorSunlight = sunrise_sun * timeSunriseSunset  +  noon_sun * timeNoon  +  midnight_sun * timeMidnight;


	sunrise_amb  = vec3(0.19, 0.35, 0.7) * 0.15 * 2.0;
	noon_amb	 = vec3(0.15, 0.29, 0.99);
	midnight_amb = vec3(0.005, 0.01, 0.02) * 0.025;

	colorSkylight = sunrise_amb * timeSunriseSunset  +  noon_amb * timeNoon  +  midnight_amb * timeMidnight;


	vec3 colorSunglow_sunrise;
	colorSunglow_sunrise.r = 1.00 * timeSunriseSunset;
	colorSunglow_sunrise.g = 0.46 * timeSunriseSunset;
	colorSunglow_sunrise.b = 0.00 * timeSunriseSunset;

	vec3 colorSunglow_noon;
	colorSunglow_noon.r = 1.0 * timeNoon;
	colorSunglow_noon.g = 1.0 * timeNoon;
	colorSunglow_noon.b = 1.0 * timeNoon;

	vec3 colorSunglow_midnight;
	colorSunglow_midnight.r = 0.05 * 0.8 * 0.0055 * timeMidnight;
	colorSunglow_midnight.g = 0.20 * 0.8 * 0.0055 * timeMidnight;
	colorSunglow_midnight.b = 0.90 * 0.8 * 0.0055 * timeMidnight;

	colorSunglow = colorSunglow_sunrise + colorSunglow_noon + colorSunglow_midnight;

	vec3 colorSkylight_rain = vec3(2.0, 2.0, 2.38) * 0.25 * (1.0 - timeMidnight * 0.995); //rain
	colorSkylight = mix(colorSkylight, colorSkylight_rain, rainStrength); //rain


	//Saturate sunlight colors
	colorSunlight = pow(colorSunlight, vec3(4.2));

	colorSunlight *= 1.0 - horizonTime;


	colorBouncedSunlight = mix(colorSunlight, colorSkylight, 0.15);

	colorScatteredSunlight = mix(colorSunlight, colorSkylight, 0.15);

	colorSunglow = pow(colorSunglow, vec3(2.5));


	//Make reflected light darker when not day time
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.5, timeSunriseSunset);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 1.0, timeNoon);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.000015, timeMidnight);

	//Make scattered light darker when not day time
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.5, timeSunriseSunset);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 1.0, timeNoon);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.000015, timeMidnight);


	float colorSunlightLum = colorSunlight.r + colorSunlight.g + colorSunlight.b;
		  colorSunlightLum /= 3.0;

	colorSunlight = mix(colorSunlight, vec3(colorSunlightLum), vec3(rainStrength));


	//Torchlight color
	float torchWhiteBalance = 0.05;
	colorTorchlight = vec3(1.00, 0.22, 0.00);
	colorTorchlight = mix(colorTorchlight, vec3(1.0), vec3(torchWhiteBalance));
	colorTorchlight = pow(colorTorchlight, vec3(0.99));

	fogEnabled = float(gl_Fog.start / far < 0.65);
}
