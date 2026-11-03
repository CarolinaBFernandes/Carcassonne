# res://scripts/view/input_setup.gd
class_name InputSetup
extends RefCounted

## Cria as ações de input do jogo (só as que ainda não existem).
## Chame uma vez, no início da cena do jogo.
static func ensure_actions() -> void:
	_define("rotate_tile", [_key(KEY_R), _mouse(MOUSE_BUTTON_RIGHT)])
	_define("skip_meeple", [_key(KEY_SPACE)])
	_define("camera_drag", [_mouse(MOUSE_BUTTON_MIDDLE)])
	_define("zoom_in", [_mouse(MOUSE_BUTTON_WHEEL_UP), _key(KEY_EQUAL), _key(KEY_KP_ADD)])
	_define("zoom_out", [_mouse(MOUSE_BUTTON_WHEEL_DOWN), _key(KEY_MINUS), _key(KEY_KP_SUBTRACT)])
	_define("cam_left", [_key(KEY_A), _key(KEY_LEFT)])
	_define("cam_right", [_key(KEY_D), _key(KEY_RIGHT)])
	_define("cam_up", [_key(KEY_W), _key(KEY_UP)])
	_define("cam_down", [_key(KEY_S), _key(KEY_DOWN)])
	_define("pause", [_key(KEY_ESCAPE)])

static func _define(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for e in events:
		InputMap.action_add_event(action, e)


## physical_keycode: a tecla é identificada pela posição física (WASD funciona em qualquer layout).
static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e
