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

uniform sampler2D texture;

in vec4 color;

in vec3 shadowNormal;

in vec2 texcoord;

in float materialIDs;
in float entityID;

void main() {
	if (entityID <= 0.0 || abs(entityID - 66.0) < 0.1) discard;

	vec4 diffuse		= texture2D(texture, texcoord) * color;
	vec3 normal			= shadowNormal;

	float NdotL			= pow(max(dot(normal.rgb, vec3(0.0, 0.0, 1.0)), 0.0), 1.0 / 2.2);

	if (abs(materialIDs - 3.0) < 0.1 || abs(materialIDs - 5.0) < 0.1) {
	//	normal = vec3(0.0);
		NdotL = 1.0;
	}

	if (abs(entityID - 8.5) < 0.6) {
		float lum = dot(diffuse.rgb, vec3(1.0 / 3.0));

		vec3 waterColor = normalize(color.rgb);

		diffuse = vec4(0.1, 0.7, 1.0, 210.0/255.0);
		diffuse.rgb *= 0.8 * waterColor.rgb;
		diffuse.rgb *= vec3(lum);
	}

	normal.xy *= -1.0;

	gl_FragData[0] = vec4(diffuse.rgb * NdotL, diffuse.a);
	gl_FragData[1] = vec4(normal * 0.5 + 0.5, 1.0);
}
