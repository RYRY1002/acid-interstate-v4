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

	// + or - 52 for middle number in Terrain-Sync

	// These control the Terrain-Sync
  intensity += 1.0 * sinpowslow (clamp01(track,   766.3, 52.3), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,   951.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  1135.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  1315.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  1500.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  1682.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  1864.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  2119.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  2232.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  2412.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  2594.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  2776.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  2961.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  3141.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  3324.3, 52.3), 1.0);
	intensity -= 1.0 * sinpowfast (clamp01(track,  3528.3, 52.3), 2.0);

	intensity += 1.0 * sinpowslow (clamp01(track,  8994.3, 52.3), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9063.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  9176.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9242.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  9358.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9424.3, 52.3), 1.0);
	intensity += 1.0 * sinpowsharp(clamp01(track,  9536.3, 52.3), 1.0);
	intensity += 1.0 * sinpowsharp(clamp01(track,  9721.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9788.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track,  9902.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  9977.3, 52.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 10083.3, 52.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 10152.3, 52.3), 1.0);
	intensity += 1.0 * sinpowfast (clamp01(track, 10285.3, 52.3), 2.0);

	x = Distance;

	freq = 1325.0 + 600.0 * clamp01(1.0 - sign(intensity) * sign(x));

	position.y += intensity * 5.0 * sin(x / freq);

  intensity *= 1.0 - 2.0 * float(track > (2776.3 + 2828.3) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (3141.3 + 3194.3) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9176.3 +  9228.3) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9358.3 + 9410.3) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9695.3 + 9745.3) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (9902.3 + 9954.3) / 2.0);
	intensity *= 1.0 - 2.0 * float(track > (10083.3 + 10135.3) / 2.0);
	intensity *= 1.0 - 1.0 * float(track > (10176.3 + 10204.3) / 2.0);

	position.z += intensity * sin(x / freq);

	// To-do: Change Terrain Deformation (not just invert it or whatever)
	// These control the terrain deformation
  intensity  = -1.0 * sinpowfast(clamp01(track, 80.5, 0.001), 3.0);
	intensity -= -1.0 * sinpowslow(clamp01(track, 3527.5, 207.5), 3.0);
	intensity -= 1.0 * sinpowslow	(clamp01(track, 3734.5, 300.5), 3.0);
	intensity += 1.0 * sinpowslow	(clamp01(track, 8966.5, 79.5), 3.0);
	intensity -= 1.0 * sinpowfast	(clamp01(track, 9046.5, 492.5), 3.0);
	intensity += 1.0 * sinpowfast	(clamp01(track, 13070.5, 207.5), 3.0);
	intensity -= 1.0 * sinpowslow	(clamp01(track, 13207.5, 300.5), 3.0);
	intensity += 1.0 * sinpowslow	(clamp01(track, 20011.5, 492.5), 3.0);
	intensity -= 1.0 * sinpowfast	(clamp01(track, 20503.5, 492.5), 3.0);
	intensity += 1.0 * sinpowfast (clamp01(track, 21827.0, 22319.5), 3.0);

  #include "terrainDeformation.glsl"

	position.y -= cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);
}
