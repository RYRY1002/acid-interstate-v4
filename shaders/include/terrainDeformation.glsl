
// Deformation Controller
float deformationController = 1.0;
deformationController -= 1.0 * sinpowslow(clamp01(track, -300.0, 0.001), 3.0);
deformationController += 1.0 * sinpowfast(clamp01(track, -80.5, 0.001), 3.0);
deformationController -= 1.0 * sinpowfast(clamp01(track, 2275.5, 984.0), 3.0);
deformationController += 1.0 * sinpowfast(clamp01(track, 3552.5, 157.0), 3.0);
deformationController -= 1.0 * sinpowslow(clamp01(track, 13207.5, 492.0), 3.0);
deformationController += 1.0 * sinpowfast(clamp01(track, 14675.5, 820.0), 3.0);
deformationController -= 1.0 * sinpowslow(clamp01(track, 18000.5, 1000.0), 3.0);
deformationController += 1.0 * sinpowsmooth(clamp01(track, 20011.5, 492.0), 3.0);

// Standard Deformation
om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
rotate(position.yz, om / 1.5 * deformationController);

// P1 Custom Deformation
float customDeformationP1 = 0.0;
customDeformationP1  = 1.0 * sinpowfast(clamp01(track, 2275.5, 984.0), 3.0);
customDeformationP1 -= 1.0 * sinpowfast(clamp01(track, 3552.5, 157.0), 3.0);
position.y -= 2.5 * customDeformationP1;
rotate(position.zy, position.x * customDeformationP1 * 0.05);
position.y += 2.5 * customDeformationP1;

// P3 Custom Deformation
float customDeformationP3 = 0.0;
customDeformationP3  = 1.0 * sinpowslow(clamp01(track, 10314.5, 492.0), 3.0);
customDeformationP3 -= 1.0 * sinpowslow(clamp01(track, 12715.5, 492.0), 3.0);
rotate(position.xz, position.x / 200.0 * customDeformationP3);
rotate(position.xz, radians(-45.0) * customDeformationP3);

// P4_1 Custom Deformation
float customDeformationP4_1 = 0.0;
customDeformationP4_1  = 1.0 * sinpowsmooth(clamp01(track, 13207.5, 246.0), 3.0);
customDeformationP4_1 -= 1.0 * sinpowsmooth(clamp01(track, 14675.5, 800.0), 3.0);
position.y += -2.5 * customDeformationP4_1;
rotate(position.yz, position.x * customDeformationP4_1 * 0.05);
position.y -= -2.5 * customDeformationP4_1;

// P4_2 Custom Deformation
float customDeformationP4_2 = 0.0;
customDeformationP4_2  = 1.0 * sinpowslow(clamp01(track, 18000.5, 1000.0), 3.0);
customDeformationP4_2 -= 1.0 * sinpowsmooth(clamp01(track, 20011.5, 492.0), 3.0);
rotate(position.xy, position.y / 42.5 * customDeformationP4_2);
rotate(position.yx, radians(7.5) * customDeformationP4_2);

// P5 Custom Deformation
float customDeformationP5 = 0.0;
customDeformationP5  = 1.0 * sinpowsmooth(clamp01(track, 20503.5, 200.0), 3.0);
customDeformationP5 -= 1.0 * sinpowfast(clamp01(track, 21827.0, 492.0), 3.0);
rotate(position.xy, abs(position.x) / 500.0 * customDeformationP5);
rotate(position.zy, abs(position.z) / 50.0 * customDeformationP5);
rotate(position.zx, position.x / 200.0 * customDeformationP5);
