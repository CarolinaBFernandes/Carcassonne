# res://scripts/model/meeple_manager.gd
class_name MeepleManager
extends RefCounted

enum Result {
	OK,
	UNKNOWN_PLAYER,     # id de jogador inexistente
	NOT_CURRENT_TILE,   # fora da fase de seguidor, ou já colocou neste turno
	INVALID_FEATURE,    # índice fora da peça
	NO_MEEPLES,         # jogador sem seguidores no estoque
	OCCUPIED,           # a região (já fundida) tem seguidor
}

var _graph: RegionGraph
var _players: Dictionary = {}          # id -> PlayerData
var _on_board: Array[Meeple] = []      # todos os seguidores em jogo
var _current: PlacedTile = null        # peça em que ainda se pode colocar seguidor


func _init(graph: RegionGraph, players: Array[PlayerData]) -> void:
	_graph = graph
	for p in players:
		_players[p.id] = p


func player(id: int) -> PlayerData:
	return _players.get(id, null)


# ------------------------------------------------------------ fase de seguidor

## Abre a fase de seguidor para a peça recém-colocada.
func begin_tile(placed: PlacedTile) -> void:
	_current = placed


## Encerra a fase (o jogador pulou, ou o seguidor já foi colocado).
func end_meeple_phase() -> void:
	_current = null


func current_tile() -> PlacedTile:
	return _current


# ------------------------------------------------------------ regras

## Diz se o jogador pode colocar seguidor na feature `feature_index` da peça corrente.
## Ordem das verificações = ordem de prioridade das mensagens.
func check(player_id: int, feature_index: int) -> Result:
	if _current == null:
		return Result.NOT_CURRENT_TILE
	var p: PlayerData = _players.get(player_id, null)
	if p == null:
		return Result.UNKNOWN_PLAYER
	if feature_index < 0 or feature_index >= _current.feature_ids.size():
		return Result.INVALID_FEATURE
	if p.meeples_available <= 0:
		return Result.NO_MEEPLES
	if _graph.is_occupied(_current.feature_ids[feature_index]):
		return Result.OCCUPIED
	return Result.OK


## Índices locais das features da peça corrente onde o jogador pode colocar.
## A interface desenha um marcador clicável para cada um
## (posição: placed.anchor_of(idx)).
func eligible_features(player_id: int) -> Array[int]:
	var out: Array[int] = []
	if _current == null:
		return out
	for i in _current.feature_ids.size():
		if check(player_id, i) == Result.OK:
			out.append(i)
	return out


## Coloca o seguidor. Retorna o Meeple criado, ou null se a jogada for inválida
## (use check() antes se precisar do motivo). Em caso de sucesso encerra a fase.
func place_meeple(player_id: int, feature_index: int) -> Meeple:
	if check(player_id, feature_index) != Result.OK:
		return null

	var placed := _current
	var is_farmer := placed.get_feature(feature_index).type == FeatureData.Type.FIELD
	var m := Meeple.new(player_id, placed.feature_ids[feature_index], placed.cell, is_farmer)

	_graph.add_meeple(m)
	_on_board.append(m)
	_players[player_id].meeples_available -= 1
	_current = null      # um seguidor por turno
	return m


# ------------------------------------------------------------ devolução

## Devolve seguidores ao estoque dos donos. Ignora seguidores já devolvidos.
## Os seguidores já devem ter saído da região (veja release_region).
func release(list: Array[Meeple]) -> void:
	for m in list:
		var idx := _on_board.find(m)
		if idx == -1:
			continue
		_on_board.remove_at(idx)
		var p: PlayerData = _players.get(m.owner_id, null)
		if p != null:
			p.meeples_available = mini(p.meeples_available + 1, PlayerData.MAX_MEEPLES)


## Remove todos os seguidores da região e os devolve aos donos.
## Retorna a lista removida (a visão usa para animar o retorno).
## IMPORTANTE: chame só DEPOIS de calcular os pontos, pois a contagem de maioria
## precisa dos seguidores ainda na região.
func release_region(region_id: int) -> Array[Meeple]:
	var removed := _graph.clear_meeples(region_id)
	release(removed)
	return removed


# ------------------------------------------------------------ consultas

func meeples_on_board() -> Array[Meeple]:
	return _on_board.duplicate()


func meeples_of_player(player_id: int) -> Array[Meeple]:
	var out: Array[Meeple] = []
	for m in _on_board:
		if m.owner_id == player_id:
			out.append(m)
	return out


## Verifica invariantes. Retorna a lista de erros (vazia = ok).
## Chame nos testes e, em debug, ao fim de cada turno.
func check_invariants() -> Array[String]:
	var errors: Array[String] = []
	for id in _players:
		var p: PlayerData = _players[id]
		var on_board := meeples_of_player(id).size()
		if p.meeples_available < 0:
			errors.append("Jogador %d com estoque negativo" % id)
		if p.meeples_available + on_board != PlayerData.MAX_MEEPLES:
			errors.append("Jogador %d: estoque %d + em jogo %d != %d" % [
				id, p.meeples_available, on_board, PlayerData.MAX_MEEPLES])
	for m in _on_board:
		if not _graph.meeples_of(m.feature_id).has(m):
			errors.append("Seguidor do jogador %d em %s não consta na região" % [
				m.owner_id, m.cell])
	return errors


## Texto para mensagens na interface.
static func result_text(r: Result) -> String:
	match r:
		Result.OK: return ""
		Result.UNKNOWN_PLAYER: return "Jogador desconhecido."
		Result.NOT_CURRENT_TILE: return "Só é possível colocar seguidor na peça recém-jogada, uma vez por turno."
		Result.INVALID_FEATURE: return "Posição inválida."
		Result.NO_MEEPLES: return "Você não tem seguidores disponíveis."
		Result.OCCUPIED: return "Já existe um seguidor nesta região."
	return ""
