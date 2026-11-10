shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.34, 0.32, 0.30, 1.0);
uniform float hatch_strength : hint_range(0.0, 1.0) = 0.28;
uniform float hatch_scale : hint_range(8.0, 120.0) = 48.0;
uniform float shadow_cutoff : hint_range(0.0, 1.0) = 0.42;

void fragment() {
    float hatch_a = step(0.84, fract((UV.x + UV.y) * hatch_scale));
    float hatch_b = step(0.88, fract((UV.x - UV.y) * hatch_scale * 0.73));
    float hatch = max(hatch_a, hatch_b) * hatch_strength;
    ALBEDO = base_color.rgb * (1.0 - hatch);
    ROUGHNESS = 0.92;
    METALLIC = 0.02;
}

void light() {
    float ndotl = max(dot(NORMAL, LIGHT), 0.0);
    float bands = ndotl > shadow_cutoff ? 1.0 : (ndotl > shadow_cutoff * 0.45 ? 0.58 : 0.28);
    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * bands;
}
