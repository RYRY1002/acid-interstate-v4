// Deformation Controller
float deformationController = 1.0;
deformationController -= 1.0 * sinpowslow(clamp01(track, 2283.5, 123.5), 3.0);
deformationController += 1.0 * sinpowfast(clamp01(track, 3528.5, 157.5), 3.0);
deformationController -= 1.0 * sinpowsmooth(clamp01(track, 13207.5, 492.5), 3.0);
deformationController += 1.0 * sinpowsmooth(clamp01(track, 14675.5, 820.5), 3.0);

// Standard Deformation
om = intensity * sin(Distance * sin(time * speed / 256.0) / 5000);
rotate(position.yz, om / 1.5 * deformationController);

// P1 Custom Deformation
float customDeformationP1 = 0.0;
customDeformationP1  = 1.0 * sinpowslow(clamp01(track, 2283.5, 138.5), 3.0);
customDeformationP1 -= 1.0 * sinpowfast(clamp01(track, 3528.5, 157.5), 3.0);
position.y -= 3.25 * customDeformationP1;
rotate(position.yz, position.x * customDeformationP1 * 0.05);
position.y += 3.25 * customDeformationP1;

// P3 Custom Deformation
float customDeformationP3 = 0.0;
customDeformationP3  = 1.0 * sinpowsmooth(clamp01(track, 10314.5, 492.5), 3.0);
customDeformationP3 -= 1.0 * sinpowsmooth(clamp01(track, 12930.5, 257.5), 3.0);
rotate(position.xz, position.x / 200.0 * customDeformationP3);
rotate(position.xz, radians(-45.0) * customDeformationP3);

// P4 Custom Deformation
float customDeformationP4 = 0.0;
customDeformationP4  = 1.0 * sinpowslow(clamp01(track, 13207.5, 492.5), 3.0);
customDeformationP4 -= 1.0 * sinpowfast(clamp01(track, 14675.5, 820.5), 3.0);
position.y -= 3.25 * customDeformationP4;
rotate(position.yz, position.x * customDeformationP4 * 0.05);
position.y += 3.25 * customDeformationP4;
