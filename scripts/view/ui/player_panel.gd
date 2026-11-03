# res://scripts/view/ui/player_panel.gd
class_name PlayerPanel
extends PanelContainer

const NAME_MAX_CHARS := 14

var player: PlayerData
var stock: MeepleStock

var _name_label: Label
var _score_label: Label
var _tween: Tween = null


func _init(p: PlayerData) -> void:
	player = p
	mouse_filter = Control.MOUSE_FILTER_STOP     # clicar no painel não coloca peça no tabuleiro

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	# Amostra de cor com o NÚMERO do jogador (não depende só de cor).
	var c := MeepleView.display_color(p.color)
	var swatch := PanelContainer.new()
	swatch.custom_minimum_size = Vector2(44, 44)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.add_theme_stylebox_override("panel", UITheme.box(c, Color(1, 1, 1, 0.6), 2, 22, 0))
	var num := Label.new()
	num.text = str(p.id + 1)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_color_override("font_color", UITheme.contrast_text(c))
	swatch.add_child(num)
	row.add_child(swatch)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	_name_label = Label.new()
	_name_label.text = p.display_name.left(NAME_MAX_CHARS)
	info.add_child(_name_label)

	stock = MeepleStock.new()
	stock.set_player_color(p.color)
	info.add_child(stock)

	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.custom_minimum_size.x = 64
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 34)
	row.add_child(_score_label)


## Destaca o jogador da vez (borda dourada).
func set_current(is_current: bool) -> void:
	if is_current:
		add_theme_stylebox_override("panel",
				UITheme.box(Color(0.20, 0.25, 0.21, 0.96), UITheme.ACCENT, 3, 14, 14))
	else:
		remove_theme_stylebox_override("panel")
	_name_label.add_theme_color_override("font_color",
			UITheme.ACCENT if is_current else UITheme.TEXT)


func set_stock(n: int) -> void:
	stock.set_stock(n)


func shown_score() -> int:
	return int(_score_label.text)


## Muda o placar mostrado. Com animate, conta de um valor ao outro após `delay`
## (o painel precisa estar na árvore).
func set_score(value: int, animate := true, delay := 0.0) -> void:
	var from := int(_score_label.text)
	if _tween != null:
		_tween.kill()
	if not animate or value == from:
		_score_label.text = str(value)
		_score_label.modulate = Color.WHITE
		return
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_callback(func(): _score_label.modulate = Color(1.7, 1.5, 0.7))
	_tween.tween_method(func(v: float): _score_label.text = str(int(round(v))),
			float(from), float(value), 0.5)
	_tween.tween_property(_score_label, "modulate", Color.WHITE, 0.4)
