shader_type spatial;
// Wet asphalt after rain: photo asphalt (CC0), lane markings as before, low-roughness puddles
// driven by the roughness map sampled at a large scale so the headlights/signs reflect in them.
uniform sampler2D asphalt : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D asphalt_r : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D sidewalk : source_color, filter_linear_mipmap, repeat_enable;

float rd(float c) { return abs(mod(c + 27.0, 54.0) - 27.0); }

void fragment() {
	vec3 wpos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dx = rd(wpos.x);
	float dz = rd(wpos.z);
	bool onx = dx < 7.0;
	bool onz = dz < 7.0;
	vec3 c = texture(sidewalk, wpos.xz / 2.0).rgb * 0.3;
	float rough = 0.9;
	if (dx < 9.5 || dz < 9.5) c = texture(sidewalk, wpos.xz / 1.2).rgb * vec3(0.7, 0.68, 0.66);
	if (onx || onz) {
		vec2 uv = wpos.xz / 7.0;
		c = texture(asphalt, uv).rgb * 0.55;
		float wet = smoothstep(0.45, 0.7, texture(asphalt_r, wpos.xz / 41.0).r);
		rough = mix(texture(asphalt_r, uv).r * 0.55 + 0.3, 0.06, wet);
		c *= 1.0 - 0.55 * wet;
		if (!(onx && onz)) {
			float d = onx ? dx : dz;
			float along = onx ? wpos.z : wpos.x;
			if (abs(d - 0.25) < 0.1) c = vec3(0.85, 0.6, 0.1) * (1.0 - 0.4 * wet);
			if (abs(d - 3.5) < 0.1 && fract(along / 6.0) < 0.5) c = vec3(0.75) * (1.0 - 0.4 * wet);
			if (abs(d - 6.6) < 0.1) c = vec3(0.7) * (1.0 - 0.4 * wet);
		} else if (max(dx, dz) > 5.0 && fract((dx > dz ? wpos.z : wpos.x) / 1.2) < 0.5) {
			c = vec3(0.7) * (1.0 - 0.4 * wet);
		}
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.7;
}
