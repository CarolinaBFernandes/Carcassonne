# res://scripts/view/ui/pause_menu.gd
class_name PauseMenu
extends CanvasLayer

signal quit_to_menu

const QUIT_TEXT := "Abandonar partida"
const CONFIRM_MS := 3000

## false depois do fim de jogo.
var enabled := true

var _root: Control
var _menu_box: VBoxContainer
var _options: OptionsPanel
var _quit_btn: Button
var _confirm_until := 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS      # continua ativo com a árvore pausada
	InputSetup.ensure_actions()

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.shared()
	_root.visible = false
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 12)
	panel.add_child(_menu_box)

	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	_menu_box.add_child(title)

	_add_button("Continuar", close)
	_add_button("Opções", _show_options)
	_quit_btn = _add_button(QUIT_TEXT, _on_quit_pressed)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(_show_menu)
	panel.add_child(_options)


func _add_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	_menu_box.add_child(b)
	return b


func is_open() -> bool:
	return _root != null and _root.visible


func open() -> void:
	if not enabled or is_open():
		return
	_reset_confirm()
	_show_menu()
	_root.visible = true
	get_tree().paused = true


func close() -> void:
	_root.visible = false
	get_tree().paused = false


func close_if_open() -> void:
	if is_open():
		close()


func _show_menu() -> void:
	_menu_box.visible = true
	_options.visible = false


func _show_options() -> void:
	_menu_box.visible = false
	_options.visible = true


func _on_quit_pressed() -> void:
	var now := Time.get_ticks_msec()
	if _confirm_until > now:
		get_tree().paused = false
		quit_to_menu.emit()
	else:
		_confirm_until = now + CONFIRM_MS
		_quit_btn.text = "Clique de novo para confirmar"


func _reset_confirm() -> void:
	_confirm_until = 0
	_quit_btn.text = QUIT_TEXT


func _process(_delta: float) -> void:
	if _confirm_until != 0 and Time.get_ticks_msec() > _confirm_until:
		_reset_confirm()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if is_open():
		if _options.visible:
			_show_menu()
		else:
			close()
	else:
		open()
	get_viewport().set_input_as_handled()
