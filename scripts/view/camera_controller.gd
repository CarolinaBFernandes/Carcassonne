# res://scripts/view/camera_controller.gd
class_name CameraController
extends Camera2D

const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.0
const ZOOM_STEP := 1.1
const KEY_SPEED := 900.0                        # pixels de tela por segundo
const MARGIN := ViewConfig.TILE_SIZE * 2.0      # folga além das peças colocadas

var _bounds := Rect2()
var _has_bounds := false
var _tween: Tween = null


func _ready() -> void:
	zoom = Vector2.ONE * 0.6


## Limita o centro da câmera ao retângulo das peças, mais uma margem.
## Passe ViewConfig.cells_to_world_rect(board.get_bounds()).
func set_world_bounds(r: Rect2) -> void:
	_bounds = r.grow(MARGIN)
	_has_bounds = true
	_clamp_position()


func _clamp_position() -> void:
	if _has_bounds:
		position = position.clamp(_bounds.position, _bounds.end)


## Move a câmera até um ponto do mundo (ex.: peça recém-jogada).
func focus_on(world_pos: Vector2, duration := 0.25) -> void:
	if _tween != null:
		_tween.kill()
	if duration <= 0.0:
		position = world_pos
		_clamp_position()
		return
	_tween = create_tween()
	_tween.tween_property(self, "position", world_pos, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var dir := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if dir != Vector2.ZERO:
		if _tween != null:
			_tween.kill()
		position += dir * KEY_SPEED * delta / zoom.x
		_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("camera_drag"):
		if _tween != null:
			_tween.kill()
		position -= event.relative / zoom.x
		_clamp_position()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("zoom_in"):
		_zoom_at_cursor(ZOOM_STEP)
	elif event.is_action_pressed("zoom_out"):
		_zoom_at_cursor(1.0 / ZOOM_STEP)


## Zoom que mantém o ponto sob o cursor parado na tela.
## Assume câmera sem rotação, sem offset e com ancoragem no centro (padrão).
func _zoom_at_cursor(factor: float) -> void:
	var new_zoom := clampf(zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, zoom.x):
		return
	var vp := get_viewport()
	var offset := vp.get_mouse_position() - vp.get_visible_rect().size / 2.0
	var world_under_cursor := position + offset / zoom.x
	zoom = Vector2.ONE * new_zoom
	position = world_under_cursor - offset / new_zoom
	_clamp_position()
