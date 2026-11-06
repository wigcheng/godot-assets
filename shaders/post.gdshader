shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float k = 0.22;
uniform float blur = 0.0;

void fragment() {
	vec2 c = SCREEN_UV - 0.5;
	vec2 ca = c * vec2(1.78, 1.0);
	float r2 = dot(ca, ca);
	float s = 1.0 / (1.0 + k * 1.04);
	vec2 uv = 0.5 + c * (1.0 + k * r2) * s;
	vec3 col = vec3(0.0);
	for (int i = -3; i <= 3; i++) {
		col += texture(screen_tex, uv + vec2(float(i) * blur * 0.018, 0.0)).rgb;
	}
	col /= 7.0;
	col *= 1.0 - 0.35 * smoothstep(0.35, 1.1, r2);
	COLOR = vec4(col, 1.0);
}
