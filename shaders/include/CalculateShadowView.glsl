float CalculateShadowView() {
	timeAngle = sunAngle * 360.0;
	pathRotationAngle = sunPathRotation;
	twistAngle = 0.0;


	timeAngle = 50.0;
	// These manage the Custom Cycle
	timeAngle += 130.0 * sinpowsmooth(clamp01(previousCameraPosition.x,       -301.0, 1.0), 1.0);
	timeAngle += 55.0 *  sinpowsmooth(clamp01(previousCameraPosition.x,       90.0, 300.0), 1.0);
	timeAngle += 125.0 * sinpowsmooth(clamp01(previousCameraPosition.x,     3734.0, 300.0), 1.0);
	timeAngle += 60.0 *  sinpowsmooth(clamp01(previousCameraPosition.x,    7500.0, 2500.0), 1.0);
	timeAngle += 115.0 * sinpowsmooth(clamp01(previousCameraPosition.x,    14675.5, 675.0), 1.0);
	timeAngle += 50.0 *  sinpowsmooth(clamp01(previousCameraPosition.x, 18000.5, 1250.0), 1.0);


	timeCycle = timeAngle;

	float isNight = abs(sign(float(mod(timeAngle, 360.0) > 180.0) - float(mod(abs(pathRotationAngle) + 90.0, 360.0) > 180.0))); // When they're not both above or below the horizon

	timeAngle = -mod(timeAngle, 180.0) * rad;
	pathRotationAngle = (mod(pathRotationAngle + 90.0, 180.0) - 90.0) * rad;
	twistAngle *= rad;


	float A = cos(pathRotationAngle);
	float B = sin(pathRotationAngle);
	float C = cos(timeAngle);
	float D = sin(timeAngle);
	float E = cos(twistAngle);
	float F = sin(twistAngle);

	shadowView = mat4(
	-D*E + B*C*F,  -A*F,  C*E + B*D*F, shadowModelView[0].w,
	        -A*C,    -B,         -A*D, shadowModelView[1].w,
	 B*C*E + D*F,  -A*E,  B*D*E - C*F, shadowModelView[2].w,
	 shadowModelView[3]);

	shadowViewInverse = mat4(
	-E*D + F*B*C,  -C*A,  F*D + E*B*C,  0.0,
	        -F*A,    -B,         -E*A,  0.0,
	 F*B*D + E*C,  -A*D,  E*B*D - F*C,  0.0,
	         0.0,   0.0,          0.0,  1.0);

	return isNight;
}
