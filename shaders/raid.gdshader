shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float t = 0.0;
uniform float fade = 1.0;
uniform float lights = 0.0;
uniform float flak = 0.0;
uniform float fire = 0.0;
uniform vec3 flak_ev[9];

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float n(vec2 p) { return texture(noise_tex, p).r; }

bool bomber(vec2 q) {
	if (abs(q.x) > 1.1 || abs(q.y) > 1.1) return false;
	float ay = abs(q.y);
	bool body = (q.x * q.x) + (q.y / 0.085) * (q.y / 0.085) < 1.0;
	bool wing = abs(q.x + 0.05) < 0.14 * (1.0 - 0.45 * ay) && ay < 1.0;
	bool tail = abs(q.x - 0.85) < 0.07 && ay < 0.34;
	float e1 = (ay - 0.32) / 0.05;
	float e2 = (ay - 0.62) / 0.045;
	float ex = (q.x + 0.16) / 0.2;
	bool eng = ex * ex + e1 * e1 < 1.0 || ex * ex + e2 * e2 < 1.0;
	return body || wing || tail || eng;
}

void fragment() {
	float frame = floor(t * 24.0);
	vec2 uv = UV + (vec2(hash(vec2(frame, 2.0)), hash(vec2(frame, 3.0))) - 0.5) * 0.0015;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = vec2(uv.x * aspect, uv.y);
	vec3 warm = vec3(1.0, 0.55, 0.2);

	vec3 col = mix(vec3(0.015, 0.017, 0.022), vec3(0.06, 0.06, 0.07), uv.y);
	col += warm * fire * 0.35 * exp(-max(0.86 - uv.y, 0.0) * 5.0);

	float L = 0.0;
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float on = clamp(lights * 4.0 - fi, 0.0, 1.0);
		if (on <= 0.0) continue;
		vec2 o = vec2(aspect * (0.14 + 0.24 * fi), 0.96);
		float a = -1.5708 + 0.5 * sin(t * 0.35 * (1.0 + 0.23 * fi) + fi * 1.7);
		vec2 dir = vec2(cos(a), sin(a));
		vec2 v = p - o;
		float along = dot(v, dir);
		float perp = abs(v.x * dir.y - v.y * dir.x);
		float w = 0.004 + along * 0.03;
		L += step(0.0, along) * exp(-perp * perp / (w * w)) * exp(-along * 0.8) * on;
	}

	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		float k = floor((fi + 1.0) * 0.5);
		float sgn = mod(fi, 2.0) < 0.5 ? 1.0 : -1.0;
		vec2 pos = vec2(aspect + 0.25 - (t - 8.0) * 0.16 + 0.11 * k,
			0.2 + sgn * 0.05 * k + 0.004 * sin(t * 0.6 + fi));
		float sz = 0.036 - 0.002 * k;
		if (bomber((p - pos) / sz)) {
			col = vec3(0.012) + vec3(0.9, 0.92, 1.0) * min(L * 1.6, 1.0);
		}
	}

	float c = n(vec2(p.x * 0.5 + t * 0.024, uv.y * 1.1)) * n(vec2(p.x * 1.6 - t * 0.04, uv.y * 2.9) + 0.3);
	float dens = smoothstep(0.22, 0.55, c) * (1.0 - smoothstep(0.5, 0.72, uv.y));
	vec3 cloud = vec3(0.05) + vec3(0.85) * L * 0.9 + warm * fire * 0.25 * uv.y;
	col = mix(col, cloud, dens * 0.75);
	col += vec3(0.7, 0.73, 0.8) * L * 0.3;

	for (int k = 0; k < 9; k++) {
		vec3 e = flak_ev[k];
		if (e.z < 0.0) continue;
		float age = e.z;
		float r = length(p - e.xy);
		float smoke = smoothstep(0.012 + age * 0.01, 0.0, r) * (1.0 - smoothstep(0.4, 2.0, age));
		col *= 1.0 - smoke * 0.55 * flak;
		col += vec3(1.0, 0.92, 0.75) * flak * 2.5 * exp(-age * 9.0) * exp(-r * r / (0.0003 + age * 0.0015));
	}

	for (int f = 0; f < 3; f++) {
		if (fire <= 0.0) break;
		float ff = float(f);
		float fx = aspect * (0.22 + 0.27 * ff) + 0.05 * sin(ff * 4.0);
		float flick = 0.7 + 0.3 * n(vec2(t * 0.9 + ff, ff * 0.3));
		float g = exp(-(p.x - fx) * (p.x - fx) * 25.0 - (uv.y - 0.88) * (uv.y - 0.88) * 50.0);
		col += warm * g * fire * flick * 0.9;
		float lean = (0.88 - uv.y) * 0.35;
		float sm = n(vec2((p.x - fx - lean) * 3.0, uv.y * 1.8 + t * 0.22)) * exp(-abs(p.x - fx - lean) * 9.0) * smoothstep(0.9, 0.35, uv.y);
		col = mix(col, vec3(0.03) + warm * 0.25 * fire * smoothstep(0.6, 0.9, uv.y), clamp(sm * fire * 1.4, 0.0, 0.85));
	}

	float bx = floor(p.x * 30.0);
	float top = 0.87 - 0.08 * hash(vec2(bx, 3.0)) - 0.06 * step(0.93, hash(vec2(bx, 9.0)));
	if (uv.y > top) col = vec3(0.008) + warm * fire * 0.05;
	col += warm * fire * 0.25 * exp(-max(uv.y - top, 0.0) * 300.0) * step(top, uv.y + 0.004) * 0.3;

	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(g), col, 0.35) * vec3(1.05, 1.0, 0.88);
	col *= 1.0 + 0.07 * (hash(vec2(frame, 1.0)) - 0.5);
	col += (hash(floor(UV / SCREEN_PIXEL_SIZE) + frame * 17.13) - 0.5) * 0.07;
	if (hash(vec2(frame, 9.0)) > 0.55 && abs(uv.x - hash(vec2(frame, 5.0))) < 0.0007) col += 0.12;
	if (hash(floor(uv * vec2(320.0, 180.0)) + frame) > 0.9995) col *= 0.2;
	col *= smoothstep(1.15, 0.35, length((UV - 0.5) * vec2(1.3, 1.0)));
	COLOR = vec4(col * fade, 1.0);
}
