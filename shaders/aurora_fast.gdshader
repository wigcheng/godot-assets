shader_type canvas_item;

uniform float speed = 0.12;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float n(vec2 p) { return texture(noise_tex, p).r; }

void fragment() {
	vec2 uv = UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float t = TIME * speed;
	float x = uv.x * aspect;
	vec3 col = mix(vec3(0.02, 0.05, 0.13), vec3(0.0, 0.01, 0.03), 1.0 - uv.y);

	vec2 cell = floor(uv * vec2(aspect, 1.0) * 180.0);
	float h = hash(cell);
	float star = step(0.996, h) * (0.6 + 0.4 * sin(TIME * 3.0 + h * 600.0));
	col += vec3(star) * (1.0 - uv.y);

	vec3 tint[3] = { vec3(0.1, 1.0, 0.55), vec3(0.2, 0.6, 1.0), vec3(0.75, 0.3, 1.0) };
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float y = 0.28 + 0.1 * fi + 0.12 * (n(vec2(x * 0.12 + t * (0.3 + 0.1 * fi), fi * 0.37 + t * 0.05)) - 0.5);
		float d = uv.y - y;
		float body = exp(-d * d * (90.0 + 40.0 * fi)) * smoothstep(0.08, -0.02, d);
		float rays = 0.45 + 0.55 * n(vec2(x * 0.9 - t * 1.2, fi * 0.21));
		col += tint[i] * body * rays * 0.7;
	}
	COLOR = vec4(col, 1.0);
}
