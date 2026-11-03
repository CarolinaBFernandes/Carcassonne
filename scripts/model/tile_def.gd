# res://scripts/model/tile_def.gd
class_name TileDef
extends Resource

@export var id: String
@export var texture: Texture2D
@export var count: int = 1
@export var features: Array[FeatureData] = []
@export var is_starter: bool = false

# Tabelas por rotação, construídas sob demanda (não exportadas).
# _side_feature[rot][lado]  -> índice da feature CITY/ROAD que toca o lado, ou -1
# _port_feature[rot][porta] -> índice da feature FIELD que contém a porta, ou -1
var _side_feature: Array = []
var _port_feature: Array = []
var _tables_ready: bool = false


func _build_tables() -> void:
	_side_feature.clear()
	_port_feature.clear()
	for r in 4:
		var sf: Array[int] = []
		sf.resize(4)
		sf.fill(-1)
		var pf: Array[int] = []
		pf.resize(8)
		pf.fill(-1)
		for i in features.size():
			var f: FeatureData = features[i]
			match f.type:
				FeatureData.Type.CITY, FeatureData.Type.ROAD:
					for s in f.sides:
						sf[Geometry.rotate_side(s, r)] = i
				FeatureData.Type.FIELD:
					for p in f.half_ports:
						pf[Geometry.rotate_port(p, r)] = i
		_side_feature.append(sf)
		_port_feature.append(pf)
	_tables_ready = true


## Índice (em `features`) da CITY/ROAD que toca `side` após `rot` rotações; -1 se nenhuma.
func side_feature_index(side: int, rot: int) -> int:
	if not _tables_ready:
		_build_tables()
	return int(_side_feature[posmod(rot, 4)][side])


## Índice (em `features`) do FIELD que contém `port` após `rot` rotações; -1 se a porta
## pertence a um lado de cidade.
func port_feature_index(port: int, rot: int) -> int:
	if not _tables_ready:
		_build_tables()
	return int(_port_feature[posmod(rot, 4)][port])


## Tipo do lado: CITY, ROAD ou FIELD (quem não é cidade nem estrada é campo).
func side_type(side: int, rot: int) -> FeatureData.Type:
	var idx := side_feature_index(side, rot)
	if idx == -1:
		return FeatureData.Type.FIELD
	return features[idx].type


## Âncora do seguidor da feature `idx`, já rotacionada (coordenadas locais da peça).
func rotated_anchor(idx: int, rot: int) -> Vector2:
	return features[idx].meeple_anchor.rotated(posmod(rot, 4) * PI / 2.0)
