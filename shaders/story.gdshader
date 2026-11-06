shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec3 band = vec3(0.0);
uniform float fade = 1.0;
uniform float meteor = -1.0;
uniform float window_light = 1.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float n(vec2 p) { return texture(noise_tex, p).r; }

float ridge_far(float x) { return 0.66 + 0.12 * n(vec2(x * 0.06, 0.5)); }
float ridge_near(float x) { return 0.80 + 0.07 * n(vec2(x * 0.11 + 0.3, 0.8)); }

void fragment() {
	vec2 uv = UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float x = uv.x * aspect;
	float t = TIME * 0.12;
	vec3 tint0 = vec3(0.1, 1.0, 0.55);
	vec3 tint1 = vec3(0.2, 0.6, 1.0);
	vec3 tint2 = vec3(0.75, 0.3, 1.0);
	vec3 ambient = (tint0 * band.x + tint1 * band.y + tint2 * band.z) / 3.0;

	vec3 col = mix(vec3(0.0, 0.01, 0.03), vec3(0.03, 0.07, 0.16), uv.y);
	col += ambient * 0.12 * uv.y;

	vec2 cell = floor(vec2(x, uv.y) * 180.0);
	float h = hash(cell);
	col += vec3(step(0.996, h) * (0.6 + 0.4 * sin(TIME * 3.0 + h * 600.0))) * (1.0 - uv.y);

	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float k = i == 0 ? band.x : (i == 1 ? band.y : band.z);
		vec3 tint = i == 0 ? tint0 : (i == 1 ? tint1 : tint2);
		k *= 0.75 + 0.5 * n(vec2(TIME * 0.15 + fi * 0.3, fi * 0.41));
		float y = 0.30 + 0.09 * fi
			+ 0.035 * sin(x * 5.0 + TIME * 0.7 + fi * 2.1)
			+ 0.10 * (n(vec2(x * 0.15 + TIME * 0.03 * (1.0 + 0.4 * fi), fi * 0.37 + TIME * 0.02)) - 0.5);
		float d = uv.y - y;
		float edge = smoothstep(0.012, -0.004, d);
		float curtain = edge * exp(min(d, 0.0) * (9.0 + 3.0 * fi));
		float r1 = n(vec2(x * 1.8 - TIME * 0.09 * (1.0 + 0.3 * fi), fi * 0.21 + TIME * 0.01));
		float r2 = n(vec2(x * 5.5 + TIME * 0.16, fi * 0.53));
		float rays = 0.25 + 1.6 * r1 * r1 + 0.6 * r2 * r2;
		col += tint * curtain * rays * 0.6 * k;
		col += vec3(1.0, 0.4, 0.6) * curtain * exp(d * 40.0) * 0.15 * k * float(i == 0);
	}

	if (meteor >= 0.0 && meteor <= 1.0) {
		vec2 dir = normalize(vec2(-0.6, 0.25));
		vec2 head = vec2(0.85 * aspect, 0.06) + dir * meteor * 0.8;
		vec2 tail = head - dir * 0.18;
		vec2 pa = vec2(x, uv.y) - tail;
		vec2 ba = head - tail;
		float hh = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
		float dist = length(pa - ba * hh);
		col += vec3(1.0, 0.95, 0.85) * (smoothstep(0.006, 0.0, dist) * 1.6 + exp(-dist * dist * 20000.0) * 0.5) * hh * sin(3.14159 * meteor);
	}

	float rf = ridge_far(x);
	col = mix(col, vec3(0.025, 0.04, 0.09) + ambient * 0.08, smoothstep(rf, rf + 0.003, uv.y));

	float rn = ridge_near(x);
	vec3 snow = vec3(0.09, 0.12, 0.19) + ambient * 0.35 * (1.0 - (uv.y - rn) * 3.0);
	col = mix(col, snow, smoothstep(rn, rn + 0.003, uv.y));

	float xc = 0.32 * aspect;
	float ry = ridge_near(xc) + 0.01;
	float dx = abs(x - xc);
	vec3 warm = vec3(1.0, 0.72, 0.35);
	float top = ry - 0.085;
	bool roof = uv.y > top && uv.y < ry - 0.05 && dx < (uv.y - top) / 0.035 * 0.05;
	bool wall = dx < 0.038 && uv.y >= ry - 0.05 && uv.y < ry + 0.02;
	if (roof || wall) col = vec3(0.015, 0.015, 0.025) + ambient * 0.03;
	vec2 wp = vec2(x - xc + 0.012, uv.y - (ry - 0.027));
	if (abs(wp.x) < 0.009 && abs(wp.y) < 0.009) col = warm * window_light;
	col += warm * window_light * 0.12 * exp(-dot(wp, wp) * 900.0);

	COLOR = vec4(col * fade, 1.0);
}
