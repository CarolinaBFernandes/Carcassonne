# res://scripts/model/tile_catalog.gd
class_name TileCatalog
extends RefCounted

const TILE_DIR := "res://data/tiles/"
const EXPECTED_TOTAL := 72

# IDs dos 24 tipos. O arquivo de cada um é tile_<ID>.tres
# e o campo `id` do recurso deve ser igual ao ID listado aqui.
const IDS: Array[String] = [
	"a", "b", "c", "d", "e", "f", "h", "i", "j", "k", "l",
	"m", "n", "o", "p", "q", "r", "s", "t", "u",
]

static var _tiles: Array[TileDef] = []
static var _by_id: Dictionary = {}
static var _starter: TileDef = null
static var _loaded: bool = false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	for tile_id in IDS:
		var path := "%stile_%s.tres" % [TILE_DIR, tile_id]
		if not ResourceLoader.exists(path):
			push_error("TileCatalog: arquivo não encontrado: %s" % path)
			continue
		var res := load(path) as TileDef
		if res == null:
			push_error("TileCatalog: %s não é um TileDef" % path)
			continue
		if res.id != tile_id:
			push_error("TileCatalog: id '%s' difere do nome do arquivo '%s'" % [res.id, tile_id])
		_tiles.append(res)
		_by_id[res.id] = res
		if res.is_starter:
			if _starter != null:
				push_error("TileCatalog: mais de uma peça inicial definida")
			_starter = res
	_loaded = true


## Todos os 24 tipos de peça.
static func get_all() -> Array[TileDef]:
	_ensure_loaded()
	return _tiles


## A peça inicial (a de id marcado com is_starter).
static func get_starter() -> TileDef:
	_ensure_loaded()
	return _starter


static func get_by_id(tile_id: String) -> TileDef:
	_ensure_loaded()
	return _by_id.get(tile_id, null)


## Soma de `count` de todos os tipos (deve ser 72).
static func total_count() -> int:
	_ensure_loaded()
	var total := 0
	for t in _tiles:
		total += t.count
	return total


## Lista de peças do baralho: `count` cópias de cada tipo,
## menos UMA cópia da peça inicial (que vai direto ao tabuleiro).
## Retorna as referências ao mesmo recurso, sem duplicá-lo.
static func build_deck_list() -> Array[TileDef]:
	_ensure_loaded()
	var list: Array[TileDef] = []
	for t in _tiles:
		var n := t.count
		if t.is_starter:
			n -= 1
		for i in n:
			list.append(t)
	return list


## Verifica a consistência dos dados. Retorna a lista de erros (vazia = ok).
static func validate() -> Array[String]:
	_ensure_loaded()
	var errors: Array[String] = []

	if _tiles.size() != IDS.size():
		errors.append("Esperados %d tipos, carregados %d" % [IDS.size(), _tiles.size()])
	if total_count() != EXPECTED_TOTAL:
		errors.append("Soma de count = %d (esperado %d)" % [total_count(), EXPECTED_TOTAL])
	if _starter == null:
		errors.append("Nenhuma peça inicial definida")
	if build_deck_list().size() != EXPECTED_TOTAL - 1:
		errors.append("Baralho deveria ter %d peças" % (EXPECTED_TOTAL - 1))

	for t in _tiles:
		if t.texture == null:
			errors.append("Peça %s sem textura" % t.id)
		if t.count <= 0:
			errors.append("Peça %s com count <= 0" % t.id)
		if t.features.is_empty():
			errors.append("Peça %s sem features" % t.id)
		errors.append_array(_validate_features(t))

	return errors


## Regras de consistência das features (as regras 1 a 6 da lista anterior).
static func _validate_features(t: TileDef) -> Array[String]:
	var errs: Array[String] = []
	var side_owner := {}   # lado -> índice da feature CITY/ROAD
	var port_owner := {}   # porta -> índice da feature FIELD

	for i in t.features.size():
		var f := t.features[i]
		match f.type:
			FeatureData.Type.CITY, FeatureData.Type.ROAD:
				for s in f.sides:
					if side_owner.has(s):
						errs.append("%s: lado %d usado por duas features" % [t.id, s])
					side_owner[s] = i
			FeatureData.Type.FIELD:
				for p in f.half_ports:
					if port_owner.has(p):
						errs.append("%s: porta %d em dois campos" % [t.id, p])
					port_owner[p] = i
				for c in f.adjacent_cities:
					if c < 0 or c >= t.features.size() \
							or t.features[c].type != FeatureData.Type.CITY:
						errs.append("%s: adjacent_cities %d não é uma cidade" % [t.id, c])

	# Lados de cidade não podem ter portas em campos.
	for s in side_owner:
		var f := t.features[side_owner[s]]
		if f.type == FeatureData.Type.CITY:
			for p in [s * 2, s * 2 + 1]:
				if port_owner.has(p):
					errs.append("%s: porta %d de lado de cidade aparece em campo" % [t.id, p])

	# Toda porta de lado não-cidade deve pertencer a algum campo.
	for s in 4:
		var is_city: bool = side_owner.has(s) \
				and t.features[side_owner[s]].type == FeatureData.Type.CITY
		if not is_city:
			for p in [s * 2, s * 2 + 1]:
				if not port_owner.has(p):
					errs.append("%s: porta %d sem campo" % [t.id, p])

	return errs
