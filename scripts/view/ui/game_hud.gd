# res://scripts/view/ui/game_hud.gd
class_name GameHUD
extends Control

signal rotate_pressed
signal skip_pressed
signal menu_pressed

const SCORE_DELAY := 0.35        # o contador espera o "+N" aparecer

var _players: Array[PlayerData] = []
var _panels: Dictionary = {}     # id do jogador -> PlayerPanel
var _held: Dictionary = {}       # id do jogador -> seguidores ainda "voando"

var _players_box: VBoxContainer
var _deck_label: Label
var _title: Label
var _hint: Label
var _skip_button: Button
var _rotate_button: Button
var _tile_panel: PanelContainer
var _tile_rect: TextureRect
var _tile_logical := 0
var _tile_steps := 0
var _rot_tween: Tween = null
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween = null


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.shared()
	_build()


# ============================================================ construção

func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _spacer_h() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return _ignore(s)


func _spacer_v() -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return _ignore(s)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(_ignore(margin))

	var column := VBoxContainer.new()
	margin.add_child(_ignore(column))

	# --- topo: jogadores (esquerda) e contador/menu (direita)
	var top := HBoxContainer.new()
	column.add_child(_ignore(top))

	_players_box = VBoxContainer.new()
	_players_box.add_theme_constant_override("separation", 8)
	top.add_child(_ignore(_players_box))
	top.add_child(_spacer_h())
	top.add_child(_build_top_right())

	column.add_child(_spacer_v())

	# --- base: status (centro) e prévia da peça (direita)
	var bottom := HBoxContainer.new()
	column.add_child(_ignore(bottom))
	bottom.add_child(_spacer_h())
	bottom.add_child(_build_status())
	bottom.add_child(_spacer_h())
	bottom.add_child(_build_tile_panel())

	_build_toast()


func _build_top_right() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	_deck_label = Label.new()
	_deck_label.text = "Peças: 0"
	_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_deck_label)

	var menu := Button.new()
	menu.text = "Menu (Esc)"
	menu.focus_mode = Control.FOCUS_NONE
	menu.pressed.connect(func(): menu_pressed.emit())
	box.add_child(menu)
	return panel


func _build_status() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", UITheme.ACCENT)
	box.add_child(_title)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	box.add_child(_hint)

	_skip_button = Button.new()
	_skip_button.text = "Sem seguidor"
	_skip_button.focus_mode = Control.FOCUS_NONE     # senão Espaço também "aperta" o botão
	_skip_button.visible = false
	_skip_button.pressed.connect(func(): skip_pressed.emit())
	box.add_child(_skip_button)
	return panel


func _build_tile_panel() -> Control:
	_tile_panel = PanelContainer.new()
	_tile_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_tile_panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile_panel.add_child(box)

	var cap := Label.new()
	cap.text = "Peça atual"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 18)
	cap.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	box.add_child(cap)

	_tile_rect = TextureRect.new()
	_tile_rect.custom_minimum_size = Vector2(128, 128)
	_tile_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tile_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tile_rect.pivot_offset = Vector2(64, 64)
	_tile_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tile_rect.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			rotate_pressed.emit())
	box.add_child(_tile_rect)

	_rotate_button = Button.new()
	_rotate_button.text = "Girar (R)"
	_rotate_button.focus_mode = Control.FOCUS_NONE
	_rotate_button.pressed.connect(func(): rotate_pressed.emit())
	box.add_child(_rotate_button)
	return _tile_panel


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label = Label.new()
	_toast.add_child(_toast_label)
	add_child(_toast)


# ============================================================ jogadores

func setup(players: Array[PlayerData]) -> void:
	_players = players
	_held.clear()
	_panels.clear()
	for c in _players_box.get_children():
		c.queue_free()
	for p in players:
		var panel := PlayerPanel.new(p)
		_players_box.add_child(panel)
		_panels[p.id] = panel
	refresh(-1, false)


## Sincroniza placar, estoque e destaque com o modelo. current_id = -1 não destaca ninguém.
func refresh(current_id: int, animate := true) -> void:
	for p in _players:
		var panel: PlayerPanel = _panels[p.id]
		panel.set_current(p.id == current_id)
		panel.set_score(p.score, animate, SCORE_DELAY)
		_update_stock(p)


func _update_stock(p: PlayerData) -> void:
	var panel: PlayerPanel = _panels.get(p.id, null)
	if panel != null:
		panel.set_stock(p.meeples_available - int(_held.get(p.id, 0)))


func _player(id: int) -> PlayerData:
	for p in _players:
		if p.id == id:
			return p
	return null


## O modelo já devolveu o seguidor, mas ele ainda está voando: segura o ícone.
func hold_stock(owner_id: int) -> void:
	_held[owner_id] = int(_held.get(owner_id, 0)) + 1
	var p := _player(owner_id)
	if p != null:
		_update_stock(p)


func release_stock(owner_id: int) -> void:
	_held[owner_id] = maxi(0, int(_held.get(owner_id, 0)) - 1)
	var p := _player(owner_id)
	if p != null:
		_update_stock(p)


## Quantos ícones cheios o painel mostra agora (usado nos testes).
func stock_shown(owner_id: int) -> int:
	var panel: PlayerPanel = _panels.get(owner_id, null)
	return panel.stock.count if panel != null else -1


## Posição de tela do estoque do jogador (destino do retorno dos seguidores).
func stock_screen_pos(owner_id: int) -> Vector2:
	var panel: PlayerPanel = _panels.get(owner_id, null)
	return panel.stock.center_global() if panel != null else Vector2(80, 60)


# ============================================================ textos e controles

func set_status(title: String, hint := "") -> void:
	_title.text = title
	_hint.text = hint
	_hint.visible = hint != ""


func set_deck_remaining(n: int) -> void:
	_deck_label.text = "Peças: %d" % n


func set_skip_visible(v: bool) -> void:
	_skip_button.visible = v


func set_rotate_enabled(v: bool) -> void:
	_rotate_button.disabled = not v


# ============================================================ prévia da peça

func show_tile(def: TileDef, rotation: int) -> void:
	_tile_rect.texture = def.texture
	_tile_logical = posmod(rotation, 4)
	_tile_steps = _tile_logical
	if _rot_tween != null:
		_rot_tween.kill()
	_tile_rect.rotation = _tile_steps * PI / 2.0
	_tile_panel.visible = true


func hide_tile() -> void:
	_tile_panel.visible = false


## Gira pelo caminho mais curto (de 3 para 0 é +90°), como o TileView.
func rotate_tile_preview(rotation: int) -> void:
	var target := posmod(rotation, 4)
	var delta := posmod(target - _tile_logical, 4)
	if delta == 3:
		delta = -1
	_tile_logical = target
	_tile_steps += delta
	var angle := _tile_steps * PI / 2.0
	if _rot_tween != null:
		_rot_tween.kill()
	if is_inside_tree():
		_rot_tween = create_tween()
		_rot_tween.tween_property(_tile_rect, "rotation", angle, 0.10) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_tile_rect.rotation = angle


# ============================================================ aviso temporário

func toast(text: String, seconds := 2.0) -> void:
	_toast_label.text = text
	_toast.reset_size()
	_toast.position = Vector2((size.x - _toast.size.x) / 2.0, 20.0)
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween != null:
		_toast_tween.kill()
	if not is_inside_tree():
		return
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): _toast.visible = false)
