# res://scripts/view/ui/end_screen.gd
class_name EndScreen
extends CanvasLayer

signal play_again
signal quit_to_menu

const CATEGORIES: Array[PlayerData.Category] = [
	PlayerData.Category.ROAD, PlayerData.Category.CITY,
	PlayerData.Category.MONASTERY, PlayerData.Category.FARM,
]
const CATEGORY_NAMES: Array[String] = ["Estradas", "Cidades", "Mosteiros", "Campos"]

var _shown: Control          # dim + painel de resultados
var _reopen_box: Control     # botão "Mostrar resultado"
var _title: Label
var _grid: GridContainer
var _seed_label: Label
var _seed := 0


# ============================================================ ranking (testável)

## Ordem decrescente de pontos (desempate por id, só para a ordem de exibição).
static func ranked(players: Array[PlayerData]) -> Array[PlayerData]:
	var out: Array[PlayerData] = players.duplicate()
	out.sort_custom(func(a: PlayerData, b: PlayerData) -> bool:
		if a.score != b.score:
			return a.score > b.score
		return a.id < b.id
	)
	return out


## Posição com empates ("1, 1, 3"): 1 + número de jogadores com mais pontos.
static func rank_of(players: Array[PlayerData], p: PlayerData) -> int:
	var higher := 0
	for q in players:
		if q.score > p.score:
			higher += 1
	return higher + 1


# ============================================================ construção

func _ready() -> void:
	layer = 20
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.shared()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_shown = Control.new()
	_shown.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_shown)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shown.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shown.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var head := Label.new()
	head.text = "Fim de jogo"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 40)
	box.add_child(head)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", UITheme.ACCENT)
	box.add_child(_title)

	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(_grid)

	var seed_row := HBoxContainer.new()
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seed_row.add_theme_constant_override("separation", 12)
	box.add_child(seed_row)
	_seed_label = Label.new()
	_seed_label.add_theme_font_size_override("font_size", 18)
	_seed_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	seed_row.add_child(_seed_label)
	var copy := Button.new()
	copy.text = "Copiar seed"
	copy.pressed.connect(func(): DisplayServer.clipboard_set(str(_seed)))
	seed_row.add_child(copy)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	_add_button(buttons, "Jogar de novo", func(): play_again.emit())
	_add_button(buttons, "Ver tabuleiro", _hide_results)
	_add_button(buttons, "Menu principal", func(): quit_to_menu.emit())

	# Botão que reabre o resultado depois de "Ver tabuleiro".
	var reopen := VBoxContainer.new()
	reopen.set_anchors_preset(Control.PRESET_FULL_RECT)
	reopen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reopen.visible = false
	root.add_child(reopen)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reopen.add_child(sp)
	var rb := Button.new()
	rb.text = "Mostrar resultado"
	rb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rb.pressed.connect(_show_results)
	reopen.add_child(rb)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 24)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reopen.add_child(pad)
	_reopen_box = reopen


func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	parent.add_child(b)


# ============================================================ exibição

func show_results(players: Array[PlayerData], winners: Array[PlayerData], seed_value: int) -> void:
	_seed = seed_value
	_seed_label.text = "Seed: %d" % seed_value

	var names: Array[String] = []
	for w in winners:
		names.append(w.display_name)
	_title.text = ("Vencedor: %s" % names[0]) if names.size() == 1 \
			else ("Empate: %s" % ", ".join(names))

	for c in _grid.get_children():
		c.queue_free()
	var headers: Array[String] = ["", "Jogador"]
	headers.append_array(CATEGORY_NAMES)
	headers.append("Total")
	for h in headers:
		var l := Label.new()
		l.text = h
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_grid.add_child(l)

	for p in ranked(players):
		var is_winner := winners.has(p)
		var tint := UITheme.ACCENT if is_winner else UITheme.TEXT

		var rank := Label.new()
		rank.text = "%dº" % rank_of(players, p)
		rank.add_theme_color_override("font_color", tint)
		_grid.add_child(rank)

		var who := HBoxContainer.new()
		who.add_theme_constant_override("separation", 8)
		var dot := ColorRect.new()
		dot.color = MeepleView.display_color(p.color)
		dot.custom_minimum_size = Vector2(18, 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		who.add_child(dot)
		var nm := Label.new()
		nm.text = p.display_name
		nm.add_theme_color_override("font_color", tint)
		who.add_child(nm)
		_grid.add_child(who)

		for cat in CATEGORIES:
			_grid.add_child(_number_label(int(p.score_by_category[cat]), tint))
		_grid.add_child(_number_label(p.score, tint, 26))

	visible = true
	_show_results()
	var root: Control = get_child(0)
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.4)


func _number_label(value: int, tint: Color, font_size := 22) -> Label:
	var l := Label.new()
	l.text = str(value)
	l.custom_minimum_size.x = 80
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_color_override("font_color", tint)
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _hide_results() -> void:
	_shown.visible = false
	_reopen_box.visible = true


func _show_results() -> void:
	_shown.visible = true
	_reopen_box.visible = false
