# res://scripts/view/ui/options_panel.gd
class_name OptionsPanel
extends VBoxContainer

signal closed


func _init() -> void:
	add_theme_constant_override("separation", 14)

	var title := Label.new()
	title.text = "Opções"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var lbl := Label.new()
	lbl.text = "Volume"
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = UserSettings.master_volume
	slider.custom_minimum_size = Vector2(260, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)

	var full := CheckBox.new()
	full.text = "Tela cheia"
	full.button_pressed = UserSettings.fullscreen
	add_child(full)

	var back := Button.new()
	back.text = "Voltar"
	add_child(back)

	# Conecta DEPOIS de definir os valores iniciais (senão aplica sem necessidade).
	slider.value_changed.connect(func(v: float):
		UserSettings.master_volume = v
		UserSettings.apply())
	full.toggled.connect(func(on: bool):
		UserSettings.fullscreen = on
		UserSettings.apply())
	back.pressed.connect(func():
		UserSettings.save_settings()
		closed.emit())
