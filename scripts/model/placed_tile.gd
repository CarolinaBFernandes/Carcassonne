# res://scripts/model/placed_tile.gd
class_name PlacedTile
extends RefCounted

var data: TileDef
var cell: Vector2i
var rotation: int = 0            # 0..3 (quantidade de giros de 90° horário)

## ID global de cada feature desta peça, na mesma ordem de data.features.
## Preenchido na Fase 6 (RegionGraph). Vazio até lá.
var feature_ids: Array[int] = []


func _init(p_data: TileDef, p_cell: Vector2i, p_rotation: int) -> void:
	data = p_data
	cell = p_cell
	rotation = posmod(p_rotation, 4)


## CITY, ROAD ou FIELD no lado indicado (0=N, 1=L, 2=S, 3=O), já considerando a rotação.
func side_type(side: int) -> FeatureData.Type:
	return data.side_type(side, rotation)


## Índice local (em data.features) da CITY/ROAD que toca o lado; -1 se for campo.
func feature_index_at_side(side: int) -> int:
	return data.side_feature_index(side, rotation)


## Índice local do FIELD que contém a porta (0..7); -1 se a porta é de lado de cidade.
func feature_index_at_port(port: int) -> int:
	return data.port_feature_index(port, rotation)


## ID global (RegionGraph) da CITY/ROAD no lado; -1 se não há ou se ainda não registrada.
func feature_id_at_side(side: int) -> int:
	var idx := feature_index_at_side(side)
	if idx == -1 or idx >= feature_ids.size():
		return -1
	return feature_ids[idx]


## ID global (RegionGraph) do FIELD na porta; -1 se não há ou se ainda não registrada.
func feature_id_at_port(port: int) -> int:
	var idx := feature_index_at_port(port)
	if idx == -1 or idx >= feature_ids.size():
		return -1
	return feature_ids[idx]


func get_feature(idx: int) -> FeatureData:
	return data.features[idx]


## Posição local (em relação ao centro da peça) onde o seguidor da feature deve aparecer,
## já rotacionada.
func anchor_of(idx: int) -> Vector2:
	return data.rotated_anchor(idx, rotation)
