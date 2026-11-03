# res://scripts/view/ui/score_popup.gd
class_name ScorePopup
extends Node2D

const FONT_SIZE := 64
const OUTLINE := 12
const RISE := 110.0

var text := ""
var color := Color.WHITE


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var pos := Vector2(-w / 2.0, FONT_SIZE * 0.35)
	var outline := Color.WHITE if color.get_luminance() < 0.3 else Color.BLACK
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, OUTLINE, outline)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


## Anima após `delay`: surge com um "pop", sobe e some; depois libera o nó.
## Chame depois de add_child.
func start(delay: float, cam_zoom: float) -> void:
	var target := Vector2.ONE / clampf(cam_zoom, 0.5, 1.3)
	scale = target * 0.4
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", target, 0.2).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.15).set_delay(delay)
	tw.tween_property(self, "position:y", position.y - RISE, 1.1).set_delay(delay) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(delay + 0.85)
	tw.chain().tween_callback(queue_free)
