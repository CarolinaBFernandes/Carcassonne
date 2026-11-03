# res://scripts/model/meeple.gd
class_name Meeple
extends RefCounted

var owner_id: int            # id do jogador
var feature_id: int          # ID global da feature onde foi colocado
var cell: Vector2i           # célula da peça onde foi colocado
var is_farmer: bool = false  # true quando colocado em campo


func _init(p_owner_id: int, p_feature_id: int, p_cell: Vector2i, p_is_farmer := false) -> void:
	owner_id = p_owner_id
	feature_id = p_feature_id
	cell = p_cell
	is_farmer = p_is_farmer
