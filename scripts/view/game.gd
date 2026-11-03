# res://scripts/view/game.gd
extends Node2D

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const TURN_STAGGER := 0.30       # intervalo entre popups de regiões diferentes
const FINAL_STAGGER := 0.55      # idem, na pontuação final

## Usados só ao abrir esta cena direto (F6), sem passar pelo menu.
@export_range(2, 5) var player_count: int = 2
@export var seed_value: int = 0  # 0 = aleatória

var gs: GameState
var rot: int = 0                 # rotação escolhida para a peça corrente
var hud: GameHUD
var pause_menu: PauseMenu
var end_screen: EndScreen

# Escalonamento dos popups de pontuação (reinicia a cada frame).
var _popup_frame := -1
var _cursor := 0.0
var _regions: Dictionary = {}    # region_id -> {"delay": float, "slots": int}

@onready var camera: CameraController = $Camera2D
@onready var board_view: BoardView = $BoardView
@onready var hud_layer: CanvasLayer = $HUD


func _ready() -> void:
	InputSetup.ensure_actions()
	UserSettings.load_settings()
	RenderingServer.set_default_clear_color(Color(0.13, 0.15, 0.13))

	hud = GameHUD.new()
	hud_layer.add_child(hud)
	hud.rotate_pressed.connect(_rotate)
	hud.skip_pressed.connect(_skip)

	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.quit_to_menu.connect(_go_menu)
	hud.menu_pressed.connect(pause_menu.open)

	end_screen = EndScreen.new()
	add_child(end_screen)
	end_screen.play_again.connect(_play_again)
	end_screen.quit_to_menu.connect(_go_menu)

	board_view.return_target = _return_target

	var errors := TileCatalog.validate()
	if not errors.is_empty():
		for e in errors:
			push_error(e)
		hud.set_status("Dados das peças inválidos", "Veja o console para os detalhes.")
		return

	if not GameConfig.configured:        # F6 direto: usa os valores do Inspetor
		var no_names: Array[String] = []
		var no_colors: Array[Color] = []
		GameConfig.configure(player_count, no_names, no_colors, seed_value, false)
	print("Seed da partida: %d" % GameConfig.seed_value)

	var players := PlayerData.create_players(GameConfig.player_count,
			GameConfig.player_names, GameConfig.player_colors)
	gs = GameState.new()
	gs.setup(players, GameConfig.seed_value, null, [], GameConfig.first_player)
	hud.setup(gs.players)

	gs.tile_placed.connect(_on_tile_placed)
	gs.tile_discarded.connect(_on_tile_discarded)
	gs.meeple_placed.connect(_on_meeple_placed)
	gs.meeples_returned.connect(_on_meeples_returned)
	gs.score_changed.connect(_on_score_changed)
	gs.phase_changed.connect(_on_phase_changed)
	gs.game_over.connect(_on_game_over)
	gs.start()                           # DEPOIS de conectar os sinais
	camera.focus_on(Vector2.ZERO, 0.0)


# ============================================================ sinais do modelo

func _on_tile_placed(placed: PlacedTile) -> void:
	board_view.add_tile(placed)
	camera.set_world_bounds(ViewConfig.cells_to_world_rect(gs.board.get_bounds()))


func _on_tile_discarded(_tile: TileDef) -> void:
	hud.toast("Peça sem lugar válido: descartada")


func _on_meeple_placed(m: Meeple, placed: PlacedTile, feature_index: int) -> void:
	board_view.add_meeple(m, placed, feature_index, gs.players[m.owner_id].color)


func _on_meeples_returned(list: Array[Meeple]) -> void:
	board_view.remove_meeples(list)
	# O modelo já devolveu; o HUD só "devolve" o ícone quando o seguidor chega.
	var order := 0
	for m in list:
		hud.hold_stock(m.owner_id)
		var wait := BoardView.RETURN_DELAY + order * BoardView.RETURN_STAGGER + MeepleView.RETURN_TIME
		order += 1
		_release_later(m.owner_id, wait)


func _release_later(owner_id: int, wait: float) -> void:
	await _wait(wait)
	hud.release_stock(owner_id)


func _on_score_changed(e: ScoreEvent) -> void:
	var frame := Engine.get_process_frames()
	if frame != _popup_frame:
		_popup_frame = frame
		_cursor = 0.0
		_regions.clear()
	if not _regions.has(e.region_id):
		_regions[e.region_id] = {"delay": _cursor, "slots": 0}
		_cursor += FINAL_STAGGER if e.is_final else TURN_STAGGER
	var info: Dictionary = _regions[e.region_id]
	var slot := int(info["slots"])
	info["slots"] = slot + 1
	board_view.show_score_popup(e, gs.players[e.player_id].color, float(info["delay"]), slot)


## Único ponto de sincronização da visão com o modelo.
func _on_phase_changed(phase_value: GameState.Phase) -> void:
	match phase_value:
		GameState.Phase.PLACE_TILE:
			rot = 0
			board_view.clear_markers()
			board_view.show_ghost(gs.current_tile, rot)
			_refresh_highlights()
			hud.show_tile(gs.current_tile, rot)
			hud.set_rotate_enabled(true)
			hud.set_skip_visible(false)
			hud.set_status("%s: coloque a peça" % gs.current_player().display_name,
					"R, botão direito ou Girar · botão do meio: mover · roda: zoom")
			_sync_hud(gs.current_player().id)
		GameState.Phase.PLACE_MEEPLE:
			board_view.hide_ghost()
			board_view.set_valid_cells([])
			board_view.show_markers(gs.last_placed, gs.eligible_meeple_features(),
					gs.current_player().color)
			hud.set_rotate_enabled(false)
			hud.set_skip_visible(true)
			hud.set_status("%s: colocar seguidor?" % gs.current_player().display_name,
					"Clique num marcador ou pule (Espaço)")
			_sync_hud(gs.current_player().id)
		GameState.Phase.GAME_OVER:
			board_view.hide_ghost()
			board_view.set_valid_cells([])
			board_view.clear_markers()
			hud.hide_tile()
			hud.set_skip_visible(false)
			hud.set_status("Fim de jogo", "Contando os pontos finais…")
			_sync_hud(-1)
		_:
			board_view.hide_ghost()
			board_view.set_valid_cells([])
			board_view.clear_markers()


func _sync_hud(current_id: int) -> void:
	hud.set_deck_remaining(gs.deck.remaining())
	hud.refresh(current_id)


func _on_game_over(winners: Array[PlayerData]) -> void:
	pause_menu.close_if_open()
	pause_menu.enabled = false
	# _cursor já acumulou os atrasos dos popups finais (mesmo frame do game_over).
	await _wait(_cursor + 0.8)
	end_screen.show_results(gs.players, winners, gs.deck.get_seed())


## Espera sem retomar a corrotina em um nó já liberado: o Timer é filho deste nó,
## então se a cena mudar ele some junto e a espera simplesmente não termina.
func _wait(seconds: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(maxf(seconds, 0.01))
	await t.timeout
	t.queue_free()


# ============================================================ input

func _process(_delta: float) -> void:
	if gs == null or gs.phase != GameState.Phase.PLACE_TILE:
		return
	# Mouse sobre um painel do HUD: esconde o fantasma.
	if get_viewport().gui_get_hovered_control() != null:
		board_view.set_ghost_visible(false)
		return
	board_view.set_ghost_visible(true)
	var cell := ViewConfig.world_to_cell(get_global_mouse_position())
	board_view.update_ghost(cell, gs.can_place_tile(cell, rot))


func _unhandled_input(event: InputEvent) -> void:
	if gs == null:
		return
	match gs.phase:
		GameState.Phase.PLACE_TILE:
			if event.is_action_pressed("rotate_tile"):
				_rotate()
			elif _is_left_click(event):
				var cell := ViewConfig.world_to_cell(get_global_mouse_position())
				if gs.can_place_tile(cell, rot):
					gs.place_tile(cell, rot)
		GameState.Phase.PLACE_MEEPLE:
			if _is_left_click(event):
				var idx := board_view.marker_at(get_global_mouse_position())
				if idx != -1:
					gs.place_meeple(idx)
			elif event.is_action_pressed("skip_meeple"):
				_skip()


static func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT


func _rotate() -> void:
	if gs == null or gs.phase != GameState.Phase.PLACE_TILE:
		return
	rot = (rot + 1) % 4
	board_view.rotate_ghost(rot)
	hud.rotate_tile_preview(rot)
	_refresh_highlights()


func _skip() -> void:
	if gs != null:
		gs.skip_meeple()


## Células da fronteira onde a peça corrente cabe na rotação atual.
func _refresh_highlights() -> void:
	var cells: Array[Vector2i] = []
	for c in gs.board.get_frontier():
		if gs.can_place_tile(c, rot):
			cells.append(c)
	board_view.set_valid_cells(cells)


# ============================================================ retorno e navegação

## Destino do retorno dos seguidores: o ícone de estoque do jogador, convertido
## de coordenadas de tela para o mundo (substitui o destino provisório da Fase 14).
func _return_target(owner_id: int) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * hud.stock_screen_pos(owner_id)


func _play_again() -> void:
	GameConfig.reroll_seed()
	get_tree().reload_current_scene()


func _go_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)   # a Fase 16 troca pelo SceneManager
