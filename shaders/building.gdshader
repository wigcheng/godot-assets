shader_type spatial;
// Night-time Taiwan apartment facade: tiled / plastered walls (CC0 ambientCG) picked per instance,
// window grid with random lit windows, a dark band at every floor line (balcony slab).
uniform sampler2D wall_a : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D wall_b : source_color, filter_linear_mipmap, repeat_enable;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 wpos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 icol = COLOR;
	float h = abs(wn.x) > 0.5 ? wpos.z : wpos.x;
	float side = step(0.5, 1.0 - abs(wn.y));
	vec2 uv = vec2(h, wpos.y) / 2.5;
	vec3 ta = texture(wall_a, uv).rgb;
	vec3 tb = texture(wall_b, uv * 0.6).rgb;
	float pick = step(0.5, hash(vec2(icol.a * 53.0, 2.0)));
	vec3 base = mix(ta, tb, pick) * icol.rgb;
	vec2 cell = vec2(h / 3.0, (wpos.y - 0.6) / 3.2);
	vec2 f = fract(cell);
	float win = step(0.26, f.x) * step(f.x, 0.74) * step(0.35, f.y) * step(f.y, 0.8) * side * step(4.0, wpos.y);
	float lit = step(0.55, hash(floor(cell) + icol.a * 97.0));
	vec3 wc = mix(vec3(1.0, 0.75, 0.45), vec3(0.6, 0.85, 1.0), hash(floor(cell) * 1.7 + icol.a * 13.0));
	float band = step(f.y, 0.1) * side * step(4.0, wpos.y);
	// roof: flat dark concrete (no texture detail needed from the chase camera)
	base = mix(base, vec3(0.16, 0.16, 0.17), 1.0 - side);
	ALBEDO = mix(base, vec3(0.03, 0.04, 0.06), win) * (1.0 - 0.45 * band);
	EMISSION = wc * win * lit * 1.4;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;
}
