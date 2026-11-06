shader_type canvas_item;

uniform float speed = 0.12;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float t = TIME * speed;
	vec3 col = mix(vec3(0.02, 0.05, 0.13), vec3(0.0, 0.01, 0.03), 1.0 - uv.y);

	vec2 cell = floor(uv * vec2(aspect, 1.0) * 180.0);
	float star = step(0.996, hash(cell)) * (0.6 + 0.4 * sin(TIME * 3.0 + hash(cell + 7.0) * 6.28));
	col += vec3(star) * (1.0 - uv.y);

	vec3 tint[3] = { vec3(0.1, 1.0, 0.55), vec3(0.2, 0.6, 1.0), vec3(0.75, 0.3, 1.0) };
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float x = uv.x * aspect;
		float y = 0.28 + 0.1 * fi + 0.12 * (fbm(vec2(x * 1.3 + t * (1.0 + 0.3 * fi), t + fi * 3.1)) - 0.5);
		float d = uv.y - y;
		float body = exp(-d * d * (90.0 + 40.0 * fi)) * smoothstep(0.08, -0.02, d);
		float rays = 0.45 + 0.55 * fbm(vec2(x * 9.0 - t * 4.0, fi * 5.0));
		col += tint[i] * body * rays * 0.7;
	}
	COLOR = vec4(col, 1.0);
}
