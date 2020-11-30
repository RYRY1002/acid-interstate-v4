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


const bool colortex0MipmapEnabled = true;


uniform sampler2D colortex0;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;


/* DRAWBUFFERS:2 */


//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////
//////////////////////////////FUNCTIONS////////////////////////////////////////////////////////////

vec3 CalculateBloom(in int LOD, in vec2 offset)
{
	float scale = pow(2.0, float(LOD));

	float padding = 0.02;

	if (	texcoord.s - offset.s + padding < 1.0 / scale + (padding * 2.0)
		&&  texcoord.t - offset.t + padding < 1.0 / scale + (padding * 2.0)
		&&  texcoord.s - offset.s + padding > 0.0
		&&  texcoord.t - offset.t + padding > 0.0)
	{
		vec3 bloom = vec3(0.0);
		float allWeights = 0.0;

		for (int i = 0; i < 6; i++) {
			for (int j = 0; j < 6; j++) {

				float weight = 1.0 - distance(vec2(i, j), vec2(2.5)) / 3.5;
					  weight = clamp(weight, 0.0, 1.0);
					  weight = 1.0 - cos(weight * 3.1415 / 2.0);
					  weight = pow(weight, 2.0);

				vec2 coord = vec2(i - 2.5, j - 2.5);
					 coord.x /= viewWidth;
					 coord.y /= viewHeight;

				vec2 finalCoord = (texcoord + coord.st - offset.st) * scale;

				if (weight > 0.0)
				{
					bloom += pow(clamp(texture2D(colortex0, finalCoord, 0).rgb, vec3(0.0), vec3(1.0)), vec3(2.2)) * weight;
					allWeights += 1.0 * weight;
				}
			}
		}

		bloom /= allWeights;

		return bloom;
	}

	else return vec3(0.0);
}


////////////////////////MAIN////////////////////////////////////////////////
////////////////////////MAIN////////////////////////////////////////////////
////////////////////////MAIN////////////////////////////////////////////////.

void main()
{
	vec3 bloom  = CalculateBloom(2, vec2(0.0)				+ vec2(0.000, 0.000)	);
		 bloom += CalculateBloom(3, vec2(0.0, 0.25)		+ vec2(0.000, 0.025)	);
		 bloom += CalculateBloom(4, vec2(0.125, 0.25)		+ vec2(0.025, 0.025)	);
		 bloom += CalculateBloom(5, vec2(0.1875, 0.25)	+ vec2(0.050, 0.025)	);
		 bloom += CalculateBloom(6, vec2(0.21875, 0.25)	+ vec2(0.075, 0.025)	);
		 bloom += CalculateBloom(7, vec2(0.25, 0.25)		+ vec2(0.100, 0.025)	);
		 bloom += CalculateBloom(8, vec2(0.28, 0.25)		+ vec2(0.125, 0.025)	);
		 bloom = pow(bloom, vec3(1.0 / (1.0 + 1.2)));

	gl_FragData[0] = vec4(bloom.rgb, 1.0);
}
