# res://scripts/view/ui/meeple_stock.gd
class_name MeepleStock
extends Control

const SLOT := 26.0
const GAP := 4.0

var color := Color.WHITE
var count := PlayerData.MAX_MEEPLES


func _init() -> void:
	custom_minimum_size = Vector2(PlayerData.MAX_MEEPLES * (SLOT + GAP), SLOT + 4.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_player_color(c: Color) -> void:
	color = MeepleView.display_color(c)
	queue_redraw()


func set_stock(n: int) -> void:
	count = clampi(n, 0, PlayerData.MAX_MEEPLES)
	queue_redraw()


## Centro do estoque em coordenadas de tela (destino do retorno dos seguidores).
func center_global() -> Vector2:
	return get_global_rect().get_center()


func _draw() -> void:
	var tex := MeepleView.standing_texture()
	for i in PlayerData.MAX_MEEPLES:
		var filled := i < count
		var c := color if filled else Color(0.6, 0.6, 0.6, 0.20)
		var center := Vector2(i * (SLOT + GAP) + SLOT / 2.0, 2.0 + SLOT / 2.0)
		if tex != null:
			var s := tex.get_size()
			var k := SLOT / maxf(s.x, s.y)
			var sz := s * k
			draw_texture_rect(tex, Rect2(center - sz / 2.0, sz), false, c)
		else:
			draw_circle(center, SLOT * 0.38, c)
			if filled:
				draw_arc(center, SLOT * 0.38, 0.0, TAU, 20, Color.BLACK, 2.0)
