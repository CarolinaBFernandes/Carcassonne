# res://scripts/model/score_event.gd
class_name ScoreEvent
extends RefCounted

var player_id: int
var points: int
var category: PlayerData.Category
var region_id: int = -1                 # raiz da região pontuada (para destacar na tela)
var cells: Array[Vector2i] = []         # células da região (para o "+N" flutuante)
var is_final: bool = false              # true na pontuação de fim de jogo


func _init(p_player_id: int, p_points: int, p_category: PlayerData.Category,
		p_region_id := -1, p_cells: Array[Vector2i] = [], p_is_final := false) -> void:
	player_id = p_player_id
	points = p_points
	category = p_category
	region_id = p_region_id
	cells = p_cells
	is_final = p_is_final
