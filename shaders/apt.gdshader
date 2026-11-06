shader_type spatial;

void fragment() {
	vec3 wpos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float h = abs(wn.x) > 0.5 ? wpos.z : wpos.x;
	vec2 f = fract(vec2(h / 3.2, wpos.y / 3.0));
	float win = step(0.25, f.x) * step(f.x, 0.75) * step(0.35, f.y) * step(f.y, 0.8) * step(0.5, 1.0 - abs(wn.y));
	ALBEDO = mix(COLOR.rgb, COLOR.rgb * vec3(0.55, 0.62, 0.7), win);
	ROUGHNESS = 0.85;
}
