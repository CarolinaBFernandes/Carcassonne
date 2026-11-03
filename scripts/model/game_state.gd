# res://scripts/model/game_state.gd
class_name GameState
extends RefCounted

enum Phase { SETUP, DRAW_TILE, PLACE_TILE, PLACE_MEEPLE, SCORING, GAME_OVER }

# ---------------------------------------------------------------- sinais
# A visão só LÊ o modelo e reage a estes sinais.
signal phase_changed(phase: Phase)
signal turn_started(player: PlayerData, turn_number: int)
signal tile_drawn(tile: TileDef, remaining: int)
signal tile_discarded(tile: TileDef)                       # peça sem lugar válido
signal tile_placed(placed: PlacedTile)
signal meeple_placed(meeple: Meeple, placed: PlacedTile, feature_index: int)
signal score_changed(event: ScoreEvent)                    # um por jogador pontuado por região
signal meeples_returned(list: Array[Meeple])
signal game_over(winners: Array[PlayerData])

# ---------------------------------------------------------------- opções
## Se true, a fase de seguidor é pulada quando não há onde colocar.
var auto_skip_meeple: bool = true

# ---------------------------------------------------------------- estado
var board: Board
var graph: RegionGraph
var meeples: MeepleManager
var deck: Deck
var players: Array[PlayerData] = []

var phase: Phase = Phase.SETUP
var current_tile: TileDef = null        # peça comprada, ainda não colocada
var last_placed: PlacedTile = null      # última peça colocada (turno em andamento)
var turn_number: int = 0                # 1 no primeiro turno

## Uma entrada por turno concluído. Base do salvamento (Fase 18).
## {turn, player, tile, discarded:[ids], cell:Vector2i, rotation, meeple_feature:int(-1=nenhum)}
var history: Array[Dictionary] = []

var _starter: TileDef = null
var _current_index: int = 0
var _turn_log: Dictionary = {}


# ================================================================ preparação

## Cria os objetos do modelo. Ainda não coloca peças nem abre turno.
## p_starter e p_cards são opcionais (testes); em jogo use os padrões (catálogo).
func setup(p_players: Array[PlayerData], p_seed: int, p_starter: TileDef = null,
		p_cards: Array[TileDef] = [], p_first_player := 0) -> void:
	players = p_players
	board = Board.new()
	graph = RegionGraph.new()
	meeples = MeepleManager.new(graph, players)
	deck = Deck.new(p_seed, p_cards)
	_starter = p_starter if p_starter != null else TileCatalog.get_starter()
	_current_index = clampi(p_first_player, 0, players.size() - 1)
	turn_number = 0
	history.clear()
	current_tile = null
	last_placed = null
	_set_phase(Phase.SETUP)


## Coloca a peça inicial em (0,0) e abre o primeiro turno.
func start() -> void:
	if phase != Phase.SETUP:
		push_error("GameState.start: só pode ser chamado em SETUP")
		return
	var placed := board.place(_starter, Vector2i.ZERO, 0)
	if placed == null:
		push_error("GameState.start: falha ao colocar a peça inicial")
		return
	graph.add_tile(placed, board)
	tile_placed.emit(placed)
	_begin_turn()


# ================================================================ consultas (para a visão)

func current_player() -> PlayerData:
	return players[_current_index]


## Rotações válidas para a peça corrente na célula (para a cor do fantasma).
func valid_rotations(cell: Vector2i) -> Array[int]:
	if phase != Phase.PLACE_TILE or current_tile == null:
		return []
	return board.get_valid_rotations(current_tile, cell)


func can_place_tile(cell: Vector2i, rotation: int) -> bool:
	return phase == Phase.PLACE_TILE and current_tile != null \
			and board.can_place(current_tile, cell, rotation)


## Índices locais das features onde o jogador da vez pode colocar seguidor.
func eligible_meeple_features() -> Array[int]:
	if phase != Phase.PLACE_MEEPLE:
		return []
	return meeples.eligible_features(current_player().id)


## Vencedores: maior pontuação. Empate = vitória compartilhada.
func winners() -> Array[PlayerData]:
	var best := -1
	for p in players:
		best = maxi(best, p.score)
	var out: Array[PlayerData] = []
	for p in players:
		if p.score == best:
			out.append(p)
	return out


# ================================================================ ações do jogador

## Coloca a peça corrente. Retorna false se a jogada for inválida (nada muda).
func place_tile(cell: Vector2i, rotation: int) -> bool:
	if phase != Phase.PLACE_TILE or current_tile == null:
		return false
	if not board.can_place(current_tile, cell, rotation):
		return false

	var placed := board.place(current_tile, cell, rotation)
	if placed == null:
		return false
	graph.add_tile(placed, board)

	last_placed = placed
	current_tile = null
	_turn_log["cell"] = cell
	_turn_log["rotation"] = posmod(rotation, 4)
	tile_placed.emit(placed)

	meeples.begin_tile(placed)
	_set_phase(Phase.PLACE_MEEPLE)
	if auto_skip_meeple and meeples.eligible_features(current_player().id).is_empty():
		_enter_scoring()
	return true


## Coloca um seguidor na feature (índice local da peça recém-jogada).
## Retorna o Meeple, ou null se inválido (use meeples.check() para o motivo).
func place_meeple(feature_index: int) -> Meeple:
	if phase != Phase.PLACE_MEEPLE:
		return null
	var m := meeples.place_meeple(current_player().id, feature_index)
	if m == null:
		return null
	_turn_log["meeple_feature"] = feature_index
	meeple_placed.emit(m, last_placed, feature_index)
	_enter_scoring()
	return m


## Pula a colocação de seguidor.
func skip_meeple() -> void:
	if phase != Phase.PLACE_MEEPLE:
		return
	_enter_scoring()


# ================================================================ fluxo interno

func _set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)


func _begin_turn() -> void:
	_set_phase(Phase.DRAW_TILE)
	turn_number += 1
	var player := current_player()
	turn_started.emit(player, turn_number)

	_turn_log = {
		"turn": turn_number,
		"player": player.id,
		"tile": "",
		"discarded": [],
		"cell": Vector2i.ZERO,
		"rotation": 0,
		"meeple_feature": -1,
	}

	var discarded_before := deck.discarded().size()
	var tile := deck.draw_playable(board)

	# Peças sem lugar válido, descartadas durante esta compra.
	var all_discarded := deck.discarded()
	for i in range(discarded_before, all_discarded.size()):
		_turn_log["discarded"].append(all_discarded[i].id)
		tile_discarded.emit(all_discarded[i])

	if tile == null:
		_finish_game()
		return

	current_tile = tile
	_turn_log["tile"] = tile.id
	tile_drawn.emit(tile, deck.remaining())
	_set_phase(Phase.PLACE_TILE)


func _enter_scoring() -> void:
	meeples.end_meeple_phase()      # fecha SEMPRE a fase de seguidor
	_set_phase(Phase.SCORING)

	var result := Scorer.score_turn(last_placed, board, graph, meeples)
	_emit_result(result)

	history.append(_turn_log)
	last_placed = null
	_current_index = (_current_index + 1) % players.size()
	_begin_turn()


func _finish_game() -> void:
	var result := Scorer.score_final(board, graph, meeples)
	_emit_result(result)
	_set_phase(Phase.GAME_OVER)
	game_over.emit(winners())


func _emit_result(result: ScoreResult) -> void:
	for e in result.events:
		score_changed.emit(e)
	if not result.released.is_empty():
		meeples_returned.emit(result.released)
