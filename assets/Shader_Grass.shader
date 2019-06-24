shader_type particles;

uniform float rows = 4;
uniform float spacing = 1.0;
uniform sampler2D noisemap;

void vertex() {
	vec4 pos = vec4(0.0, 0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;
	
	pos.x -= rows * 0.5;
	pos.z -= rows * 0.5;
	pos *= spacing;
	
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing);
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing);
	
	float noise = texture(noisemap, pos.xz).x;
	pos.y = noise;
	pos.x += noise* spacing;
	pos.z += noise* spacing;
	
//	TRANSFORM[0][0] = cos(noise.z*3.14);
//	TRANSFORM[0][2] = -sin(noise.z*3.14);
//	TRANSFORM[2][0] = sin(noise.z*3.14);
//	TRANSFORM[2][2] = cos(noise.z*3.14);
	
	TRANSFORM[3] = pos;
}