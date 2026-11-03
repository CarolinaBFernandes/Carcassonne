# res://scripts/view/ui/main_menu.gd
class_name MainMenu
extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const MAX_NAME := 14

var _count: SpinBox
var _rows: Array[HBoxContainer] = []
var _names: Array[LineEdit] = []
var _colors: Array[ColorPickerButton] = []
var _seed: LineEdit
var _seed_prev := ""
var _first: CheckBox
var _error: Label
var _play: Button
var _main_box: VBoxContainer
var _options: OptionsPanel


func _ready() -> void:
	UserSettings.load_settings()
	theme = UITheme.shared()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.11, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	center.add_child(panel)

	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 14)
	panel.add_child(_main_box)

	var title := Label.new()
	title.text = "Carcassonne"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	_main_box.add_child(title)

	# Número de jogadores
	var count_row := HBoxContainer.new()
	count_row.add_theme_constant_override("separation", 12)
	_main_box.add_child(count_row)
	var cl := Label.new()
	cl.text = "Jogadores"
	count_row.add_child(cl)
	_count = SpinBox.new()
	_count.min_value = PlayerData.MIN_PLAYERS
	_count.max_value = PlayerData.MAX_PLAYERS
	_count.value = 2
	_count.rounded = true
	count_row.add_child(_count)

	# Linhas de jogador (5; as sobressalentes ficam escondidas)
	for i in PlayerData.MAX_PLAYERS:
		_main_box.add_child(_build_player_row(i))

	# Seed e sorteio do primeiro jogador
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 12)
	_main_box.add_child(seed_row)
	var sl := Label.new()
	sl.text = "Seed (opcional)"
	seed_row.add_child(sl)
	_seed = LineEdit.new()
	_seed.placeholder_text = "aleatória"
	_seed.max_length = 12
	_seed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed.text_changed.connect(_on_seed_changed)
	seed_row.add_child(_seed)

	_first = CheckBox.new()
	_first.text = "Sortear quem começa"
	_main_box.add_child(_first)

	_error = Label.new()
	_error.add_theme_color_override("font_color", UITheme.ERROR)
	_error.add_theme_font_size_override("font_size", 18)
	_main_box.add_child(_error)

	_play = Button.new()
	_play.text = "Jogar"
	_play.pressed.connect(_on_play)
	_main_box.add_child(_play)
	var opt := Button.new()
	opt.text = "Opções"
	opt.pressed.connect(func():
		_main_box.visible = false
		_options.visible = true)
	_main_box.add_child(opt)
	if not OS.has_feature("web"):
		var quit := Button.new()
		quit.text = "Sair"
		quit.pressed.connect(func(): get_tree().quit())
		_main_box.add_child(quit)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(func():
		_options.visible = false
		_main_box.visible = true)
	panel.add_child(_options)

	_count.value_changed.connect(func(_v: float): _refresh_rows())
	_refresh_rows()


func _build_player_row(i: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var num := Label.new()
	num.text = str(i + 1)
	num.custom_minimum_size.x = 28
	row.add_child(num)

	var edit := LineEdit.new()
	edit.placeholder_text = "Jogador %d" % (i + 1)
	edit.max_length = MAX_NAME
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)

	var picker := ColorPickerButton.new()
	picker.color = PlayerData.DEFAULT_COLORS[i]
	picker.edit_alpha = false
	picker.custom_minimum_size = Vector2(72, 38)
	picker.color_changed.connect(func(_c: Color): _refresh_rows())
	row.add_child(picker)

	_rows.append(row)
	_names.append(edit)
	_colors.append(picker)
	return row


func _on_seed_changed(new_text: String) -> void:
	if new_text != "" and not new_text.is_valid_int():
		_seed.text = _seed_prev                  # recusa letras
		_seed.caret_column = _seed.text.length()
		return
	_seed_prev = new_text


func _refresh_rows() -> void:
	var n := int(_count.value)
	for i in _rows.size():
		_rows[i].visible = i < n
	_validate()


## Cores precisam ser distintas (o jogo identifica o dono pela cor).
func _validate() -> bool:
	var n := int(_count.value)
	var ok := true
	for i in n:
		for j in range(i + 1, n):
			var a := _colors[i].color
			var b := _colors[j].color
			if Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b)) < 0.2:
				ok = false
	_error.text = "" if ok else "Escolha cores bem diferentes para cada jogador."
	_play.disabled = not ok
	return ok


func _on_play() -> void:
	if not _validate():
		return
	var n := int(_count.value)
	var names: Array[String] = []
	var colors: Array[Color] = []
	for i in n:
		var t := _names[i].text.strip_edges()
		names.append(t if t != "" else "Jogador %d" % (i + 1))
		colors.append(_colors[i].color)
	var seed_text := _seed.text.strip_edges()
	var s := seed_text.to_int() if seed_text.is_valid_int() else 0
	GameConfig.configure(n, names, colors, s, _first.button_pressed)
	get_tree().change_scene_to_file(GAME_SCENE)     # a Fase 16 troca pelo SceneManager
