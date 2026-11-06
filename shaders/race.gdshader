shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float t = 0.0;
uniform float pos = 0.0;
uniform float px = 0.0;
uniform float curve = 0.0;
uniform float heading = 0.0;
uniform float steer = 0.0;
uniform float r1z = -1.0;
uniform float r2z = -1.0;
uniform float speed_n = 0.0;
uniform float fade = 1.0;

const float PROJ = 0.6;
const float W = 2.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float n(vec2 p) { return texture(noise_tex, p).r; }

void fragment() {
	vec2 uv = UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float xs = (uv.x - 0.5) * aspect;
	float hz = 0.47 + 0.015 * sin(pos * 0.012) + 0.0015 * sin(t * 41.0) * speed_n;
	vec3 fogc = vec3(0.55, 0.18, 0.38);
	vec3 col;

	if (uv.y < hz) {
		float k = (hz - uv.y) / hz;
		col = mix(vec3(0.95, 0.35, 0.45), vec3(0.06, 0.02, 0.14), pow(k, 0.6));
		vec2 cell = floor(vec2(xs + heading * 0.1, uv.y) * 160.0);
		col += vec3(step(0.995, hash(cell)) * smoothstep(0.3, 0.8, k));
		vec2 sc = vec2(-heading * 0.3, hz - 0.13);
		float sd = length(vec2(xs, uv.y) - sc);
		if (sd < 0.14) {
			float g = (uv.y - (sc.y - 0.14)) / 0.28;
			vec3 sunc = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 0.25, 0.5), g);
			float gap = smoothstep(sc.y - 0.02, sc.y + 0.14, uv.y) * 0.65;
			col = mix(col, sunc, step(gap, fract(uv.y * 45.0)));
		}
		col += vec3(1.0, 0.4, 0.5) * exp(-sd * 7.0) * 0.25;
		float mx = xs + heading * 0.6;
		float ridge = hz - 0.03 - 0.075 * n(vec2(mx * 0.35, 0.3));
		if (uv.y > ridge) {
			col = vec3(0.10, 0.03, 0.16) + vec3(0.9, 0.2, 0.8) * smoothstep(ridge + 0.005, ridge, uv.y) * 0.8;
		}
	} else {
		float dy = uv.y - hz;
		float z = PROJ / max(dy, 0.0001);
		float xw = xs * z / PROJ + px;
		float rx = xw - curve * z * z;
		float segp = (pos + z) / 10.0;
		float alt = mod(floor(segp), 2.0);
		float lw = 0.03 + z * 0.006;
		float gx = abs(fract(rx / 4.0) - 0.5) * 4.0;
		float gz = abs(fract(segp) - 0.5) * 10.0;
		col = vec3(0.07, 0.02, 0.10) + vec3(0.9, 0.2, 0.8) * smoothstep(lw * 3.0, 0.0, min(gx, gz)) * 0.6;
		float ar = abs(rx);
		if (ar < W) {
			col = mix(vec3(0.08, 0.08, 0.10), vec3(0.11, 0.11, 0.13), alt);
			if (ar < 0.06 + z * 0.002 && alt < 0.5) col = vec3(0.9);
		} else if (ar < W + 0.25) {
			col = alt < 0.5 ? vec3(1.0, 0.2, 0.75) : vec3(0.2, 0.9, 1.0);
		}
		col = mix(col, fogc, smoothstep(8.0, 60.0, z) * 0.85);
	}

	float first = ceil(pos / 15.0);
	for (int k = 9; k >= 0; k--) {
		float d = (first + float(k)) * 15.0 - pos;
		if (d < 0.6) continue;
		float yb = hz + PROJ / d;
		float hgt = 3.0 / d * PROJ;
		float wid = max(0.12 / d * PROJ, 0.0015);
		float lrad = 0.25 / d * PROJ;
		float fade_d = 1.0 - smoothstep(35.0, 140.0, d);
		for (int j = 0; j < 2; j++) {
			float s = j == 0 ? -1.0 : 1.0;
			float xw2 = s * (W + 0.6) + curve * d * d - px;
			float xsb = xw2 / d * PROJ;
			if (abs(xs - xsb) < wid && uv.y < yb && uv.y > yb - hgt) col = vec3(0.04, 0.03, 0.06);
			vec2 lp = vec2((xw2 - s * 0.8) / d * PROJ, yb - hgt);
			float lr = length(vec2(xs, uv.y) - lp);
			col += vec3(0.3, 0.9, 1.0) * (step(lr, lrad) + exp(-lr / lrad * 1.5) * 0.35) * fade_d;
		}
	}

	for (int i = 0; i < 2; i++) {
		float rz = i == 0 ? r1z : r2z;
		if (rz < 0.8 || rz > 70.0) continue;
		float lane = i == 0 ? -0.9 : 0.9;
		float yb = hz + PROJ / rz;
		float xc = (lane + curve * rz * rz - px) / rz * PROJ;
		float cw = 0.85 / rz * PROJ;
		float ch = 0.9 / rz * PROJ;
		vec2 q = vec2((xs - xc) / cw, (yb - uv.y) / ch);
		if (abs(q.x) < 1.0 && q.y > 0.0 && q.y < 1.0 && (q.y < 0.55 || abs(q.x) < 0.72 - (q.y - 0.55) * 0.7)) {
			vec3 cc = i == 0 ? vec3(0.2, 0.25, 0.9) : vec3(0.95, 0.85, 0.2);
			col = cc * 0.55;
			if (q.y > 0.6) col = vec3(0.05, 0.06, 0.1);
			if (q.y > 0.22 && q.y < 0.36 && abs(q.x) > 0.55) col = vec3(1.0, 0.15, 0.2) * 1.5;
			if (q.y < 0.08) col = vec3(0.02);
			col = mix(col, fogc, smoothstep(8.0, 60.0, rz) * 0.85);
		}
		vec2 tl = vec2(abs(xs - xc) - cw * 0.78, uv.y - (yb - ch * 0.29));
		col += vec3(1.0, 0.1, 0.2) * exp(-length(tl) / (cw * 0.25)) * 0.3 * (1.0 - smoothstep(20.0, 70.0, rz));
	}

	float hy = 0.84 + 0.05 * pow(abs(uv.x - 0.5) * 2.0, 2.0);
	if (uv.y > hy) {
		col = vec3(0.35, 0.03, 0.06) * (0.6 + 0.4 * (1.0 - (uv.y - hy) * 4.0));
		col += vec3(1.0, 0.3, 0.6) * exp(-abs(uv.y - hy - 0.012) * 300.0) * 0.5;
	}
	vec2 d = vec2(xs, uv.y) - vec2(0.0, 1.12);
	float cs = cos(steer);
	float sn = sin(steer);
	vec2 dr = vec2(cs * d.x + sn * d.y, -sn * d.x + cs * d.y);
	float rr = length(d);
	bool rim = abs(rr - 0.26) < 0.022;
	bool spoke = (abs(dr.y) < 0.018 && abs(dr.x) < 0.26) || (abs(dr.x) < 0.02 && dr.y > 0.0 && dr.y < 0.26);
	if (rim || spoke || rr < 0.06) {
		col = vec3(0.04, 0.04, 0.05);
		if (rim && abs(dr.x) < 0.02 && dr.y < 0.0) col = vec3(1.0, 0.3, 0.5);
	}
	COLOR = vec4(col * fade, 1.0);
}
