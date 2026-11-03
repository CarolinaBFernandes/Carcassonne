# res://scripts/model/region_graph.gd
class_name RegionGraph
extends RefCounted

## Dados de uma região. Só o Region da RAIZ do union-find é válido.
class Region:
	var type: FeatureData.Type
	var open_ends: int = 0                 # CITY/ROAD: lados ainda abertos
	var tiles: Dictionary = {}             # Vector2i -> true (conjunto de células)
	var shields: int = 0                   # CITY: brasões
	var meeples: Array[Meeple] = []
	var adjacent_cities: Dictionary = {}   # FIELD: ID de cidade -> true (pode não ser raiz)


var _parent: Array[int] = []
var _regions: Array[Region] = []


# ============================================================ criação / union-find

static func _has_ends(t: FeatureData.Type) -> bool:
	return t == FeatureData.Type.CITY or t == FeatureData.Type.ROAD


func clear() -> void:
	_parent.clear()
	_regions.clear()


func _new_region(type: FeatureData.Type, open_ends: int, shields: int, cell: Vector2i) -> int:
	var id := _parent.size()
	var r := Region.new()
	r.type = type
	r.open_ends = open_ends
	r.shields = shields
	r.tiles[cell] = true
	_parent.append(id)
	_regions.append(r)
	return id


## Raiz da região do ID (com compressão de caminho).
func find(id: int) -> int:
	var root := id
	while _parent[root] != root:
		root = _parent[root]
	while _parent[id] != root:
		var nxt := _parent[id]
		_parent[id] = root
		id = nxt
	return root


## Une as regiões de a e b e retorna a raiz resultante.
## Se já são a mesma região, uma CITY/ROAD fecha um laço (open_ends -= 2).
func union(a: int, b: int) -> int:
	var ra := find(a)
	var rb := find(b)

	if ra == rb:
		var same: Region = _regions[ra]
		if _has_ends(same.type):
			same.open_ends -= 2
		return ra

	if _regions[ra].type != _regions[rb].type:
		push_error("RegionGraph.union: tipos diferentes (%d x %d)" % [_regions[ra].type, _regions[rb].type])
		return ra

	# A raiz é a região maior (menos dados para copiar).
	if _regions[ra].tiles.size() < _regions[rb].tiles.size():
		var tmp := ra
		ra = rb
		rb = tmp

	var keep: Region = _regions[ra]
	var gone: Region = _regions[rb]

	_parent[rb] = ra
	if _has_ends(keep.type):
		keep.open_ends = keep.open_ends + gone.open_ends - 2
	keep.tiles.merge(gone.tiles)
	keep.shields += gone.shields
	keep.meeples.append_array(gone.meeples)
	keep.adjacent_cities.merge(gone.adjacent_cities)
	_regions[rb] = null
	return ra


# ============================================================ registro de peça

## Registra as features da peça recém-colocada e une com as vizinhas.
## Chame DEPOIS de board.place(). Preenche placed.feature_ids.
func add_tile(placed: PlacedTile, board: Board) -> void:
	var def := placed.data
	var cell := placed.cell
	placed.feature_ids.clear()

	# Passo 1: um ID novo para cada feature (inclusive mosteiro).
	for f in def.features:
		var open := 0
		var shield := 0
		if _has_ends(f.type):
			open = f.sides.size()
		if f.type == FeatureData.Type.CITY and f.has_shield:
			shield = 1
		placed.feature_ids.append(_new_region(f.type, open, shield, cell))

	# Passo 2: converte adjacent_cities (índices locais) em IDs globais.
	for i in def.features.size():
		var f: FeatureData = def.features[i]
		if f.type != FeatureData.Type.FIELD:
			continue
		var reg: Region = _regions[placed.feature_ids[i]]
		for local_city in f.adjacent_cities:
			reg.adjacent_cities[placed.feature_ids[local_city]] = true

	# Passo 3: une com cada vizinho.
	for side in 4:
		var neighbor := board.get_neighbor(cell, side)
		if neighbor == null:
			continue

		# Cidade/estrada: o lado toca o lado oposto do vizinho.
		var mine := placed.feature_id_at_side(side)
		var theirs := neighbor.feature_id_at_side(Geometry.opposite_side(side))
		if mine != -1 and theirs != -1:
			union(mine, theirs)

		# Campos: cada meia-borda toca uma meia-borda do vizinho.
		var ports: Dictionary = Geometry.PORT_MATCH[side]
		for my_port in ports:
			var fa := placed.feature_id_at_port(my_port)
			var fb := neighbor.feature_id_at_port(ports[my_port])
			if fa != -1 and fb != -1:
				union(fa, fb)


# ============================================================ consultas

func region(id: int) -> Region:
	return _regions[find(id)]


func type_of(id: int) -> FeatureData.Type:
	return region(id).type


func open_ends(id: int) -> int:
	return region(id).open_ends


## Completa = cidade ou estrada sem pontas abertas.
## Mosteiro: use is_monastery_complete. Campo nunca "completa".
func is_complete(id: int) -> bool:
	var r := region(id)
	return _has_ends(r.type) and r.open_ends == 0


## Peças distintas na região (base do valor de estrada e cidade).
func tile_count(id: int) -> int:
	return region(id).tiles.size()


func shield_count(id: int) -> int:
	return region(id).shields


func cells_of(id: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in region(id).tiles:
		out.append(c)
	return out


## Célula onde o mosteiro está.
func monastery_cell(id: int) -> Vector2i:
	var cell: Vector2i = region(id).tiles.keys()[0]
	return cell


func is_monastery_complete(id: int, board: Board) -> bool:
	if region(id).type != FeatureData.Type.MONASTERY:
		return false
	return board.count_neighbors8(monastery_cell(id)) == 8


## Raízes distintas das cidades que tocam o campo (sem duplicatas).
func adjacent_city_roots(field_id: int) -> Array[int]:
	var out: Array[int] = []
	var seen := {}
	for city_id in region(field_id).adjacent_cities:
		var root := find(city_id)
		if not seen.has(root):
			seen[root] = true
			out.append(root)
	return out


## Raízes distintas de todas as features da peça (o chamador filtra por tipo).
func roots_of_tile(placed: PlacedTile) -> Array[int]:
	var out: Array[int] = []
	var seen := {}
	for id in placed.feature_ids:
		var root := find(id)
		if not seen.has(root):
			seen[root] = true
			out.append(root)
	return out


## Todas as raízes (uma por região existente). Útil na pontuação final.
func all_roots() -> Array[int]:
	var out: Array[int] = []
	for i in _parent.size():
		if _parent[i] == i:
			out.append(i)
	return out


# ============================================================ seguidores

## Adiciona o seguidor à região de m.feature_id.
## A regra "região já ocupada" é verificada na Fase 7, não aqui.
func add_meeple(m: Meeple) -> void:
	region(m.feature_id).meeples.append(m)


func remove_meeple(m: Meeple) -> void:
	region(m.feature_id).meeples.erase(m)


## Lista interna da região. Não modifique por fora.
func meeples_of(id: int) -> Array[Meeple]:
	return region(id).meeples


func is_occupied(id: int) -> bool:
	return not region(id).meeples.is_empty()


## owner_id -> quantidade de seguidores na região.
func meeple_counts(id: int) -> Dictionary:
	var counts := {}
	for m in region(id).meeples:
		counts[m.owner_id] = int(counts.get(m.owner_id, 0)) + 1
	return counts


## Jogadores com a maioria. Vários elementos = empate (todos pontuam o valor inteiro).
func majority_owners(id: int) -> Array[int]:
	var counts := meeple_counts(id)
	var best := 0
	for k in counts:
		best = maxi(best, int(counts[k]))
	var out: Array[int] = []
	if best == 0:
		return out
	for k in counts:
		if int(counts[k]) == best:
			out.append(k)
	return out


## Remove e devolve todos os seguidores da região (para devolvê-los aos donos).
func clear_meeples(id: int) -> Array[Meeple]:
	var r := region(id)
	var removed: Array[Meeple] = []
	removed.append_array(r.meeples)
	r.meeples.clear()
	return removed


# ============================================================ depuração

func debug_dump() -> void:
	for root in all_roots():
		var r: Region = _regions[root]
		print("região %d tipo=%d abertas=%d peças=%d brasões=%d seguidores=%d" % [
			root, r.type, r.open_ends, r.tiles.size(), r.shields, r.meeples.size()])
