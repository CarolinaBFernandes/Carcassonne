extends Control

var main

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := TextureRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var cam := "res://assets/carcassonne.png"
	if ResourceLoader.exists(cam):
		fundo.texture = load(cam)
	fundo.modulate = Color(0.45, 0.45, 0.45)
	add_child(fundo)

	var cx := CenterContainer.new()
	cx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cx)

	var painel := PanelContainer.new()
	cx.add_child(painel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	vb.custom_minimum_size = Vector2(360, 0)
	painel.add_child(vb)

	var titulo := Label.new()
	titulo.text = "CARCASSONNE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 46)
	vb.add_child(titulo)

	var sub := Label.new()
	sub.text = "Versao digital — Projeto de Software"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.85, 0.85, 0.85)
	vb.add_child(sub)

	vb.add_child(HSeparator.new())

	var b_iniciar := Button.new()
	b_iniciar.text = "Iniciar Partida"
	b_iniciar.custom_minimum_size = Vector2(0, 48)
	b_iniciar.pressed.connect(_on_iniciar)
	vb.add_child(b_iniciar)

	var b_carregar := Button.new()
	b_carregar.text = "Carregar Partida"
	b_carregar.custom_minimum_size = Vector2(0, 44)
	b_carregar.pressed.connect(_on_carregar)
	vb.add_child(b_carregar)

	var b_creditos := Button.new()
	b_creditos.text = "Creditos"
	b_creditos.custom_minimum_size = Vector2(0, 40)
	b_creditos.pressed.connect(_on_creditos)
	vb.add_child(b_creditos)

	var b_fechar := Button.new()
	b_fechar.text = "Fechar"
	b_fechar.custom_minimum_size = Vector2(0, 40)
	b_fechar.pressed.connect(_on_fechar)
	vb.add_child(b_fechar)

func _on_iniciar() -> void:
	if main != null:
		main.ir_configuracao()

func _on_creditos() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Creditos"
	dlg.dialog_text = "Carcassonne — Projeto de Software\n\nIntegrantes do grupo:\n\n- Anna Luiza Barros\n- Carolina Borges Fernandes Pimentel\n- Pedro de Brito Muniz\n- Miguel Ramos Gil\n- Lucas Lopes de Moraes\n- Lucas Gaviao"
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)

func _on_carregar() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)
	var cx := CenterContainer.new()
	cx.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cx)
	var painel := PanelContainer.new()
	cx.add_child(painel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(340, 0)
	painel.add_child(vb)
	var t := Label.new()
	t.text = "Carregar partida"
	t.add_theme_font_size_override("font_size", 22)
	vb.add_child(t)
	vb.add_child(HSeparator.new())
	for s in [1, 2, 3]:
		var info := GM.info_slot(s)
		var existe: bool = info.get("existe", false)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 48)
		b.text = "Slot %d — %s" % [s, ("Rodada %d (%d jogadores)" % [info["rodada"], info["jogadores"]]) if existe else "vazio"]
		b.disabled = not existe
		var slot: int = s
		if existe:
			b.pressed.connect(func():
				layer.queue_free()
				if main:
					main.carregar_jogo(slot))
		vb.add_child(b)
	vb.add_child(HSeparator.new())
	var cancelar := Button.new()
	cancelar.text = "Cancelar"
	cancelar.pressed.connect(layer.queue_free)
	vb.add_child(cancelar)

func _on_fechar() -> void:
	get_tree().quit()
