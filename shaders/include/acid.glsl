void acid(inout vec3 position, in vec3 worldPosition) {
	position.y -= clamp(cameraPosition.x, 50.5, 90.5) - 90.5;		//ascent at beginning of video
	position.y += cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);

	const float speed = 20.0 / 80.0;
	float time = track + 8000.0;
	float intensity = 1.0;
	float freq = 1.0;
	float Distance, om, x, y, z;

	if (track < 50.5) position.x += track - 50.5;
	rotate(position.xy, -45.0 * rad);
	x = -289.5;
	y = -60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	// These also control the Intro Terrain Sync
	y *= sinpowslow(clamp10(track, -288.5, 5.0), 4.0);
	x *= sinpowslow(clamp10(track, -288.5, 15.0), 4.0);
	intensity = x - y;
	intensity *= clamp01(position.x, 0.0, 1.0);
	intensity *= sinpowfast(clamp01(track, 45.2, 5.0), 10.0);
	om = intensity  * sin(position.x / 500.0);
	rotate(position.yz, om);
	rotate(position.xy, 45.0 * rad);
	if (track < 50.5) position.x -= track - 50.5;


	x = 49.0;
	y = 60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	// These control the Intro Terrain Sync
	y *= sinpowfast(clamp10(track, 49.0 - 5.0, 5.0), 4.0);
	x *= sinpowfast(clamp10(track, 49.0 - 5.0, 5.0), 4.0);
	intensity = x - y;
	om = intensity * sin(position.x / 500.0);
	rotate(position.yz, om);


	x = position.x;
//	if (worldPosition.x >= 50.5) position.x = 50.0 - cameraPosition.x + position.x * 0.05;
	position.x = mix(position.x, x, sinpowfast(clamp01(track, 45.2, 5.0), 10.0));


	Distance = position.x * position.x + position.z * position.z;

	// These control the Terrain-Sync
	intensity += 1.0 * sinpowslow (clamp01(track,   766.5, 52.0), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,   949.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  1130.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  1312.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  1495.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  1678.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  1860.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  2039.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  2223.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  2406.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  2588.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  2771.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  2953.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  3135.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  3318.5, 52.0), 1.0);
	intensity -= 1.0 * sinpowfast (clamp01(track,  3517.5, 35.0), 2.0);

	intensity += 1.0 * sinpowslow (clamp01(track,  8994.5, 52.0), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9062.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  9176.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9244.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  9359.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9426.5, 52.0), 1.0);
	intensity += 1.0 * sinpowfast (clamp01(track,  9557.5, 35.0), 2.0);
	intensity += 1.0 * sinpowslow (clamp01(track,  9725.5, 52.0), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9793.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  9906.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9975.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 10089.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 10157.5, 52.0), 1.0);
	intensity += 1.0 * sinpowfast (clamp01(track, 10291.5, 35.0), 2.0);

	intensity += 1.0 * sinpowslow (clamp01(track, 20450.5, 52.0), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 20517.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 20631.5, 52.0), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 20699.5, 52.0), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 20814.5, 52.0), 1.0);
	intensity -= 1.0 * sinpowfast (clamp01(track, 20899.5, 35.0), 2.0);


	x = Distance;

	freq = 1325.0 + 700.0 * clamp01(1.0 - sign(intensity) * sign(Distance));

	position.y += intensity * 5.0 * sin(Distance / freq);

	intensity *= 1.0 - 2.0 * float(track > (2771.5 +   2823.0) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (3135.5 +   3187.0) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9176.5 +   9228.0) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9359.5 +   9411.0) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9695.5 +   9745.0) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9906.5 +   9958.0) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (10089.5 + 10141.0) / 2.0);
	intensity *= 1.0 - 1.0 * float(track > (10176.5 + 10204.0) / 2.0);

	position.z += intensity * sin(Distance / freq);

	intensity  = -1.0 * sinpowslow (clamp01(track, 80.5, 0.001), 3.0);
	intensity -= -1.0 * sinpowfast (clamp01(track, 3552.5, 182.0), 3.0);
	intensity -= 1.0 * sinpowslow  (clamp01(track, 3734.5, 300.0), 3.0);
	intensity += 1.0 * sinpowslow	 (clamp01(track, 8966.5, 79.0), 3.0);
	intensity -= 1.0 * sinpowfast	 (clamp01(track, 9046.5, 492.0), 3.0);
	intensity += 1.0 * sinpowslow	 (clamp01(track, 12673.5, 492.0), 3.0);
	intensity -= 1.0 * sinpowfast	 (clamp01(track, 13807.5, 300.0), 3.0);
	intensity += 1.0 * sinpowslow(clamp01(track, 18000.5, 1000.0), 3.0);

	#include "terrainDeformation.glsl"

	intensity  = 1.0 * sinpowsmooth(clamp01(track, 50000.5, 200.0), 3.0);
	intensity -= 1.0 * sinpowfast(clamp01(track, 50001.0, 492.0), 3.0);

	// Unused Terrain Deformation for P5 (Please note that this was never finished and is very broken)
	// Disable lines 49 and 50 in terrainDeformation.glsl and enable lines 119 to 140 in acid.glsl to use it

	//intensity  = 1.0 * sinpowsmooth(clamp01(track, 20503.5, 200.0), 3.0);
  //intensity -= 1.0 * sinpowfast(clamp01(track, 21827.0, 492.0), 3.0);

	//if (worldPosition.y > 126.9 && worldPosition.y < 131.1 && worldPosition.z > -2.1 && worldPosition.z < 3.1) {
		//position.y -= cameraPosition.y - 128.0;

		//rotateRad(position.xz, 25.0 * intensity);

		//om = dot(position.x, position.x) / 4000.0 * intensity;
		//rotate(position.xy, om);

		//position.y += cameraPosition.y - 128.0;
	//} else {
		//position.y -= cameraPosition.y - 128.0;

		//rotateRad(position.xz, 25.0 * intensity);

		//om = dot(position.x, position.x) / 4000.0 * intensity;
		//rotate(position.xy, om);

		//position.y += cameraPosition.y - 128.0;
	//}
