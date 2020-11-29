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
