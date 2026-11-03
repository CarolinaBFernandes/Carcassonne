# res://scripts/model/scorer.gd
class_name Scorer
extends RefCounted


# ============================================================ pontuação do turno

## Pontuação após colocar a peça (e o seguidor, se houve).
## Pontua as regiões completadas e só DEPOIS devolve os seguidores.
static func score_turn(placed: PlacedTile, board: Board, graph: RegionGraph,
		meeples: MeepleManager) -> ScoreResult:
	var result := ScoreResult.new()

	# 1) Candidatas: regiões da própria peça (inclui o mosteiro dela, se houver)...
	var candidates: Array[int] = []
	for root in graph.roots_of_tile(placed):
		candidates.append(root)

	# 2) ...e mosteiros nas 8 células ao redor (a peça nova pode completá-los).
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var neighbor := board.get_tile(placed.cell + Vector2i(dx, dy))
			if neighbor == null:
				continue
			for id in monastery_ids(neighbor):
				candidates.append(graph.find(id))

	# 3) Pontua cada região completa uma única vez.
	var done := {}
	for root in candidates:
		if done.has(root):
			continue
		done[root] = true

		var points := completed_value(root, board, graph)
		if points <= 0:
			continue                      # incompleta (ou campo)
		if not graph.is_occupied(root):
			continue                      # completa, mas sem seguidor

		_award(root, points, category_of(graph.type_of(root)), graph, meeples, result, false)

		# 4) Só agora os seguidores voltam para os donos.
		result.released.append_array(meeples.release_region(root))

	return result


# ============================================================ utilidades (reusadas na Fase 11)

## Valor de uma região COMPLETA. Retorna 0 se não estiver completa
## (ou se for campo, que só pontua no fim do jogo).
static func completed_value(root: int, board: Board, graph: RegionGraph) -> int:
	match graph.type_of(root):
		FeatureData.Type.ROAD:
			if graph.is_complete(root):
				return graph.tile_count(root)
		FeatureData.Type.CITY:
			if graph.is_complete(root):
				return 2 * graph.tile_count(root) + 2 * graph.shield_count(root)
		FeatureData.Type.MONASTERY:
			if graph.is_monastery_complete(root, board):
				return 9
	return 0


static func category_of(type: FeatureData.Type) -> PlayerData.Category:
	match type:
		FeatureData.Type.ROAD:
			return PlayerData.Category.ROAD
		FeatureData.Type.CITY:
			return PlayerData.Category.CITY
		FeatureData.Type.MONASTERY:
			return PlayerData.Category.MONASTERY
	return PlayerData.Category.FARM


## IDs globais das features MONASTERY de uma peça.
static func monastery_ids(tile: PlacedTile) -> Array[int]:
	var out: Array[int] = []
	for i in tile.data.features.size():
		if tile.data.features[i].type == FeatureData.Type.MONASTERY:
			out.append(tile.feature_ids[i])
	return out


## Dá `points` a todos os donos da maioria da região e registra um evento por jogador.
## NÃO devolve seguidores (quem chama decide).
static func _award(root: int, points: int, category: PlayerData.Category,
		graph: RegionGraph, meeples: MeepleManager, result: ScoreResult,
		is_final: bool) -> void:
	var owners := graph.majority_owners(root)
	owners.sort()                         # ordem estável dos eventos
	var cells := graph.cells_of(root)
	for pid in owners:
		var p := meeples.player(pid)
		if p == null:
			continue
		p.add_score(points, category)
		result.events.append(ScoreEvent.new(pid, points, category, root, cells, is_final))


# ============================================================ pontuação final (Fase 11)

# ============================================================ pontuação final (Fase 11)

## Pontua tudo que ainda tem seguidor: estradas, cidades, mosteiros e campos.
## Depois devolve todos os seguidores.
static func score_final(board: Board, graph: RegionGraph,
		meeples: MeepleManager) -> ScoreResult:
	var result := ScoreResult.new()

	var roads: Array[int] = []
	var cities: Array[int] = []
	var monasteries: Array[int] = []
	var fields: Array[int] = []

	for root in graph.all_roots():
		if not graph.is_occupied(root):
			continue
		match graph.type_of(root):
			FeatureData.Type.ROAD:
				roads.append(root)
			FeatureData.Type.CITY:
				cities.append(root)
			FeatureData.Type.MONASTERY:
				monasteries.append(root)
			FeatureData.Type.FIELD:
				fields.append(root)

	for root in roads:
		_award(root, final_road_value(root, graph), PlayerData.Category.ROAD,
				graph, meeples, result, true)
	for root in cities:
		_award(root, final_city_value(root, graph), PlayerData.Category.CITY,
				graph, meeples, result, true)
	for root in monasteries:
		_award(root, final_monastery_value(root, board, graph), PlayerData.Category.MONASTERY,
				graph, meeples, result, true)
	for root in fields:
		var pts := final_field_value(root, graph)
		if pts > 0:
			_award(root, pts, PlayerData.Category.FARM, graph, meeples, result, true)

	# Devolve tudo no final, depois de todos os pontos calculados.
	for root in roads + cities + monasteries + fields:
		result.released.append_array(meeples.release_region(root))

	return result


## Estrada: 1 ponto por peça (vale para completa ou incompleta).
static func final_road_value(root: int, graph: RegionGraph) -> int:
	return graph.tile_count(root)


## Cidade: completa = 2 por peça + 2 por brasão; incompleta = 1 por peça + 1 por brasão.
static func final_city_value(root: int, graph: RegionGraph) -> int:
	var per := 2 if graph.is_complete(root) else 1
	return per * (graph.tile_count(root) + graph.shield_count(root))


## Mosteiro: 1 + peças nas 8 células ao redor.
static func final_monastery_value(root: int, board: Board, graph: RegionGraph) -> int:
	return 1 + board.count_neighbors8(graph.monastery_cell(root))


## Campo: 3 pontos por cidade completa distinta adjacente.
static func final_field_value(root: int, graph: RegionGraph) -> int:
	var completed := 0
	for city_root in graph.adjacent_city_roots(root):
		if graph.is_complete(city_root):
			completed += 1
	return 3 * completed
