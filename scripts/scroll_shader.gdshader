shader_type canvas_item;

uniform float scroll_speed = 0.05;

void fragment() {
    vec2 shifteduv = UV;
    shifteduv.x += TIME * scroll_speed;
    COLOR = texture(TEXTURE, shifteduv);
}
