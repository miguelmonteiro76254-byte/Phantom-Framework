shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    tex.rgb *= darkness;
    COLOR = tex;
}