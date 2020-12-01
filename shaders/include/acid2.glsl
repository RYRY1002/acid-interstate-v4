void acid(inout vec3 position, in vec3 worldPosition) {
   //position.y -= clamp(cameraPosition.x, 50.5, 90.5) - 90.5;		//ascent at beginning of video
	position.y += cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);

	const float speed = 20.0 / 80.0;
	float time = track + 8000.0;
	float intensity = 1.0;
	float freq = 1.0;
	float Distance, om, x, y, z;

	if (track < 50.5) position.x += track - 50.5;
	rotate(position.xy, -45.0 * rad);
	x = -45.0;
	y = -60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	// These also control the Intro Terrain Sync
	y *= sinpowslow(clamp10(track, -68.1, 5.0), 4.0);
	x *= sinpowslow(clamp10(track, -73.7, 15.0), 4.0);
	intensity = x - y;
	intensity *= clamp01(position.x, 0.0, 1.0);
	intensity *= sinpowfast(clamp01(track, 45.2, 5.0), 10.0);
	om = intensity  * sin(position.x / 500.0);
	rotate(position.yz, om);
	rotate(position.xy, 45.0 * rad);
	if (track < 50.5) position.x -= track - 50.5;


	x = 45.0;
	y = 60.0 * cubesmooth(clamp01( abs(position.x) , 5.0, 55.0));
	// These control the Intro Terrain Sync
	y *= sinpowfast(clamp10(track, 44.5 - 5.0, 5.0), 4.0);
	x *= sinpowfast(clamp10(track, 44.5 - 5.0, 5.0), 4.0);
	intensity = x - y;
	om = intensity * sin(position.x / 500.0);
	rotate(position.yz, om);


	x = position.x;
	if (worldPosition.x >= 50.5) position.x = 50.0 - cameraPosition.x + position.x * 0.05;
	position.x = mix(position.x, x, sinpowfast(clamp01(track, 45.2, 5.0), 10.0));


	Distance = position.x * position.x + position.z * position.z;

	// + or - 52 for middle number in Terrain-Sync

	// These control the Terrain-Sync
	intensity  = 1.0 * sinpowslow (clamp01(track, 818.3 - 35.0, 35.0), 2.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track,  951.3,  1003.3 -  951.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 1135.3, 1187.3 - 1135.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 1315.3, 1367.3 - 1315.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 1500.3, 1552.3 - 1500.3), 1.0);

	intensity -= 2.0 * sinpowsharp(clamp01(track, 1682.3, 1734.3 - 1682.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 1864.3, 1916.3 - 1864.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 2119.3, 2171.3 - 2119.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 2232.3, 2284.3 - 2232.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 2412.3, 2464.3 - 2412.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 2594.3, 2646.3 - 2594.3), 1.0);

	intensity -= 2.0 * sinpowsharp(clamp01(track, 2776.3, 2828.3 - 2776.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 2961.3, 3013.3 - 2961.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 3141.3, 3194.3 - 3141.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 3324.3, 3376.3 - 3324.3), 1.0);

	intensity += 1.0 * sinpowsharp(clamp01(track, 9046.3, 9070.3 - 9046.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9064.3, 9116.3 - 9064.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9178.3, 9230.3 - 9178.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9246.3, 9298.3 - 9246.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9362.3, 9414.3 - 9362.3), 1.0);

	intensity -= 2.0 * sinpowsharp(clamp01(track, 9428.3, 9480.3 - 9428.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9726.3, 9778.3 - 9726.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9794.3, 9846.3 - 9794.3), 1.0);
	intensity += 2.0 * sinpowsharp(clamp01(track, 9908.3, 9960.3 - 9908.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 9976.3, 10028.3 - 9976.3), 1.0);

	intensity += 2.0 * sinpowsharp(clamp01(track, 10091.3, 10143.3 - 10091.3), 1.0);
	intensity -= 2.0 * sinpowsharp(clamp01(track, 10160.3, 10212.3 - 10160.3), 1.0);
	intensity -= 1.0 * sinpowfast (clamp01(track, 3527.3, 35.0), 2.0);

	x = Distance;

	freq = 1325.0 + 600.0 * clamp01(1.0 - sign(intensity) * sign(x));

	position.y += intensity * 5.0 * sin(x / freq);

  //intensity *= 1.0 - 2.0 * float(track > ( 900.5 +  952.1) / 2.0);
	//intensity *= 1.0 - 2.0 * float(track > (1307.3 + 1358.9) / 2.0);
	//intensity *= 1.0 - 2.0 * float(track > (1511.3 + 1561.7) / 2.0);
	//intensity *= 1.0 - 2.0 * float(track > (1916.9 + 1968.5) / 2.0);

	position.z += intensity * sin(x / freq);

	// To-do: Change Terrain Deformation (not just invert it or whatever)
	// These control the terrain deformation
  intensity  = -1.0 * sinpowfast(clamp01(track, 80.5, 85.5 - 80.5), 3.0);
  intensity += -4.5 * sinpowfast(clamp01(track, 2283.5, 492.5 - 80.5), 3.0); //Set intensity to 0.0 for Terrain Deformation the same as P1
  intensity -= -5.5 * sinpowfast(clamp01(track, 3570.5, 250.5 - 80.5), 3.0);
  intensity -= 1.0 * sinpowslow(clamp01(track, 3734.5, 3938.5 - 3734.5), 3.0);
  intensity += 1.0 * sinpowslow(clamp01(track, 8966.5, 9045.5 - 8966.5), 3.0);
  intensity -= 1.0 * sinpowfast(clamp01(track, 9046.5, 492.5 - 80.5), 3.0);

	om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
	rotate(position.yz, om / 1.5);

	position.y -= cameraPosition.y - 128.0 - 1.5 * clamp10(cameraPosition.x - 89.5);
}
