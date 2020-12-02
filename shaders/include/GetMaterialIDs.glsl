float GetMaterialIDs() {						//Gather materials
	float materialID;

	switch(int(mc_Entity.x)) {
		case 31:								//Tall Grass
		case 37:								//Dandelion
		case 38:								//Rose
		case 59:								//Wheat
		case 83:								//Sugar Cane
		case 106:								//Vine
		case 175:								//Double Tall Grass
					materialID = 2.0; break;	//Translucent blocks
		case 18:								//Leaves
					materialID = 3.0; break;	//Leave
		case 8:
		case 9:
					materialID = 4.0; break;	//Water
		case 79:	materialID = 5.0; break;	//Ice
		case 50:	materialID = 7.0; break;	//Torch
		case 10:
		case 11:	materialID = 8.0; break;	//Lava
		case 89:
		case 124:	materialID = 9.0; break;	//Glowstone and Lamp
		case 51:	materialID = 10.0; break;	//Fire
		default:	materialID = 1.0;
	}

	return materialID;
}