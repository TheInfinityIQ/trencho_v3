shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tile_a : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tile_b : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 boundary[8];
uniform int layout_seed = 35035;
uniform bool meadow = false;
varying vec2 meters;

vec2 quarter(vec2 value, uint q) {
	if (q == 1u) { return vec2(-value.y, value.x); }
	if (q == 2u) { return -value; }
	if (q == 3u) { return vec2(value.y, -value.x); }
	return value;
}

void vertex() {
	meters = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / 32.0;
}

void fragment() {
	vec2 lattice = meters / 8.0;
	ivec2 cell = ivec2(floor(lattice));
	uint hash = uint(cell.x) * 374761393u + uint(cell.y) * 668265263u + uint(layout_seed);
	hash = (hash ^ (hash >> 13u)) * 1274126177u;
	hash = hash ^ (hash >> 16u);
	uint q = meadow ? ((hash >> 1u) & 3u) : (((hash >> 1u) & 1u) * 2u);
	vec2 uv = quarter(lattice, q);
	// Explicit world-lattice gradients avoid a false mip stripe at tile hash /
	// orientation boundaries. No internal seam overlay or image modification.
	vec2 dx = quarter(dFdx(lattice), q);
	vec2 dy = quarter(dFdy(lattice), q);
	vec4 a = textureGrad(tile_a, uv, dx, dy);
	vec4 b = textureGrad(tile_b, uv, dx, dy);
	vec4 material_color = mix(a, b, float(hash & 1u));
	float distance_to_edge = 100000.0;
	for (int i = 0; i < 8; i++) {
		vec2 start = boundary[i];
		vec2 segment = boundary[(i + 1) % 8] - start;
		float t = clamp(dot(meters - start, segment) / max(dot(segment, segment), 0.000001), 0.0, 1.0);
		distance_to_edge = min(distance_to_edge, length(meters - start - segment * t));
	}
	COLOR = vec4(material_color.rgb, smoothstep(0.0, 0.375, distance_to_edge));
}
