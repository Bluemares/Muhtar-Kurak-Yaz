extends CanvasLayer
## Dünyanın üstü, HUD'un altı: sıcak hava dalgalanması, sıcak renk tonu, vinyet, yangın alarmı.
## Şiddet kuraklıkla artar (Haziran hafif, Ağustos belirgin).

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float heat = 0.0;
uniform float alarm = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	float w = sin(uv.y * 70.0 + TIME * 3.0) * 0.6 + sin(uv.y * 23.0 - TIME * 2.0 + uv.x * 9.0) * 0.4;
	uv.x += w * 0.0018 * heat;
	uv.y += cos(uv.x * 40.0 + TIME * 2.5) * 0.0008 * heat;
	vec3 c = texture(screen_tex, uv).rgb;
	c = mix(c, c * vec3(1.07, 0.97, 0.84), heat);
	float d = distance(SCREEN_UV, vec2(0.5));
	float v = smoothstep(0.42, 0.9, d);
	c *= 1.0 - v * (0.32 + heat * 0.18);
	c = mix(c, c * vec3(1.15, 0.78, 0.55), v * heat * 0.6);
	float pulse = 0.5 + 0.5 * sin(TIME * 6.0);
	c = mix(c, vec3(0.9, 0.12, 0.05), v * alarm * pulse * 0.55);
	COLOR = vec4(c, 1.0);
}
"""

var _mat := ShaderMaterial.new()
var _alarm := 0.0


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sh := Shader.new()
	sh.code = SHADER
	_mat.shader = sh
	var r := ColorRect.new()
	r.material = _mat
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(r)


func _process(delta: float) -> void:
	var game = get_tree().get_first_node_in_group("game")
	var target := 1.0 if game and game.fire_active else 0.0
	_alarm = move_toward(_alarm, target, delta * 2.0)
	_mat.set_shader_parameter("heat", (0.25 + GameState.drought() * 0.75) * (1.0 - 0.6 * GameState.night_factor()))
	_mat.set_shader_parameter("alarm", _alarm)
