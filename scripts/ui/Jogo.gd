extends Node2D

const TAM := 128.0

var main
var configs: Array = []
var carregar_slot := -1
var seed_inicial := 0

var _cam: Camera2D
var tabuleiro
var _ghost = null
var _validos: Node2D
var _panning := false
var _dlg_meeple: CanvasLayer
var _indicadores_meeple: Array = []

var _hud_layer: CanvasLayer
var _lbl_seed: Label
var _lbl_vez: Label
var _box_jogadores: VBoxContainer
var _preview: TextureRect
var _lbl_restantes: Label
var _btn_rot: Button
var _btn_explorar: Button
var _btn_naocolocar: Button
var _btn_desfazer: Button

const _ICONE_TIPO := {
	FeatureTile.Tipo.CIDADE: "res://assets/meeple/meeple_castle.png",
	FeatureTile.Tipo.ESTRADA: "res://assets/meeple/meeple_road.png",
	FeatureTile.Tipo.MOSTEIRO: "res://assets/meeple/meeple_monastery.png",
	FeatureTile.Tipo.CAMPO: "res://assets/meeple/meeple_fields.png",
}
const _NOME_TIPO := {
	FeatureTile.Tipo.CIDADE: "Cidade (cavaleiro)",
	FeatureTile.Tipo.ESTRADA: "Estrada (ladrao)",
	FeatureTile.Tipo.MOSTEIRO: "Mosteiro (monge)",
	FeatureTile.Tipo.CAMPO: "Campo (fazendeiro)",
}

var _ver_encaixes := true
var _ver_dominio := false
var _btn_encaixes: Button
var _btn_dominio: Button
var _overlay_dominio: DominioCampos

func _ready() -> void:
	_cam = Camera2D.new()
	_cam.position = Vector2(TAM * 0.5, TAM * 0.5)
	_cam.zoom = Vector2(0.9, 0.9)
	add_child(_cam)
	_cam.make_current()
	_construir_hud()

func iniciar() -> void:
	tabuleiro = Tabuleiro.new()
	add_child(tabuleiro)
	_overlay_dominio = DominioCampos.new()
	_overlay_dominio.z_as_relative = false
	_overlay_dominio.z_index = 20
	tabuleiro.add_child(_overlay_dominio)
	_validos = Node2D.new()
	add_child(_validos)
	GM.tile_sorteado.connect(_on_tile_sorteado)
	GM.estado_mudou.connect(_on_estado_mudou)
	GM.tabuleiro_mudou.connect(_on_atualizar)
	GM.pontuacao_mudou.connect(_on_atualizar)
	GM.vez_mudou.connect(_on_vez)
	GM.jogo_acabou.connect(_on_jogo_acabou)
	GM.pontuou.connect(_on_pontuou)
	if carregar_slot >= 0:
		GM.carregar(carregar_slot, tabuleiro)
	else:
		GM.iniciarPartida(configs, tabuleiro, seed_inicial)
	_atualizar_hud()

func _construir_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_layer = layer

	_lbl_seed = Label.new()
	_lbl_seed.add_theme_color_override("font_color", Color.WHITE)
	_lbl_seed.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_lbl_seed.add_theme_constant_override("outline_size", 4)
	_lbl_seed.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_lbl_seed.offset_left = 312
	_lbl_seed.offset_top = 10
	layer.add_child(_lbl_seed)

	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	painel.custom_minimum_size = Vector2(300, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.28)
	painel.add_theme_stylebox_override("panel", sb)
	layer.add_child(painel)

	painel.clip_contents = true
	var mc := MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for m in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		mc.add_theme_constant_override(m, 12)
	painel.add_child(mc)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	mc.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)

	var titulo := Label.new()
	titulo.text = "Carcassonne"
	titulo.add_theme_font_size_override("font_size", 26)
	vb.add_child(titulo)
	_lbl_vez = Label.new()
	vb.add_child(_lbl_vez)

	vb.add_child(HSeparator.new())
	_box_jogadores = VBoxContainer.new()
	_box_jogadores.add_theme_constant_override("separation", 6)
	vb.add_child(_box_jogadores)

	vb.add_child(HSeparator.new())
	var l_peca := Label.new()
	l_peca.text = "Peca atual:"
	vb.add_child(l_peca)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(128, 128)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_preview.pivot_offset = Vector2(64, 64)
	vb.add_child(_preview)
	_lbl_restantes = Label.new()
	vb.add_child(_lbl_restantes)

	_btn_encaixes = Button.new()
	_btn_encaixes.custom_minimum_size = Vector2(0, 40)
	_btn_encaixes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_encaixes.text = "Ver encaixes: SIM"
	_btn_encaixes.pressed.connect(_toggle_encaixes)
	vb.add_child(_btn_encaixes)

	_btn_dominio = Button.new()
	_btn_dominio.custom_minimum_size = Vector2(0, 40)
	_btn_dominio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_dominio.text = "Mostrar Dominio: NAO"
	_btn_dominio.pressed.connect(_toggle_dominio)
	vb.add_child(_btn_dominio)

	vb.add_child(HSeparator.new())
	_btn_rot = Button.new()
	_btn_rot.text = "Rotacionar (R)"
	_btn_rot.pressed.connect(_rotacionar)
	vb.add_child(_btn_rot)

	var b_hist := Button.new()
	b_hist.text = "Historico"
	b_hist.pressed.connect(func(): _mostrar_historico(false, []))
	vb.add_child(b_hist)
	var b_salvar := Button.new()
	b_salvar.text = "Salvar jogo"
	b_salvar.pressed.connect(_abrir_slots_salvar)
	vb.add_child(b_salvar)
	var b_regras := Button.new()
	b_regras.text = "Regras"
	b_regras.pressed.connect(_mostrar_regras)
	vb.add_child(b_regras)
	var b_sair := Button.new()
	b_sair.text = "Sair"
	b_sair.pressed.connect(func(): if main: main.ir_inicial())
	vb.add_child(b_sair)

	_btn_explorar = Button.new()
	_btn_explorar.text = "Explorar opcoes"
	_btn_explorar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_explorar.anchor_left = 1.0
	_btn_explorar.offset_left = -220
	_btn_explorar.offset_top = 16
	_btn_explorar.offset_right = -16
	_btn_explorar.custom_minimum_size = Vector2(0, 44)
	_btn_explorar.visible = false
	_btn_explorar.pressed.connect(_explorar_opcoes)
	layer.add_child(_btn_explorar)

	_btn_naocolocar = Button.new()
	_btn_naocolocar.text = "Nao colocar Meeple"
	_btn_naocolocar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_naocolocar.anchor_left = 1.0
	_btn_naocolocar.anchor_top = 1.0
	_btn_naocolocar.offset_left = -240
	_btn_naocolocar.offset_top = -64
	_btn_naocolocar.offset_right = -16
	_btn_naocolocar.offset_bottom = -16
	var sbv := StyleBoxFlat.new()
	sbv.bg_color = Color(0.6, 0.15, 0.15)
	sbv.set_corner_radius_all(6)
	_btn_naocolocar.add_theme_stylebox_override("normal", sbv)
	var sbv2 := StyleBoxFlat.new()
	sbv2.bg_color = Color(0.75, 0.2, 0.2)
	sbv2.set_corner_radius_all(6)
	_btn_naocolocar.add_theme_stylebox_override("hover", sbv2)
	_btn_naocolocar.visible = false
	_btn_naocolocar.pressed.connect(func(): GM.pular())
	layer.add_child(_btn_naocolocar)

	_btn_desfazer = Button.new()
	_btn_desfazer.text = "Desfazer peca"
	_btn_desfazer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_desfazer.anchor_left = 1.0
	_btn_desfazer.anchor_top = 1.0
	_btn_desfazer.offset_left = -240
	_btn_desfazer.offset_top = -120
	_btn_desfazer.offset_right = -16
	_btn_desfazer.offset_bottom = -72
	var sbd := StyleBoxFlat.new()
	sbd.bg_color = Color(0.45, 0.32, 0.08)
	sbd.set_corner_radius_all(6)
	_btn_desfazer.add_theme_stylebox_override("normal", sbd)
	var sbd2 := StyleBoxFlat.new()
	sbd2.bg_color = Color(0.62, 0.46, 0.12)
	sbd2.set_corner_radius_all(6)
	_btn_desfazer.add_theme_stylebox_override("hover", sbd2)
	_btn_desfazer.visible = false
	_btn_desfazer.pressed.connect(cancel_tile_placement)
	layer.add_child(_btn_desfazer)

func _atualizar_hud() -> void:
	var j = GM.jogadorAtivo()
	if j != null:
		_lbl_vez.text = "Rodada %d — Vez: %s%s" % [
			(GM.rodada.numero if GM.rodada else 1), j.nome, (" (IA)" if j.ehIA else "")]
	if GM.deck != null:
		_lbl_restantes.text = "Pecas restantes: %d" % GM.deck.restantes()
	if _lbl_seed != null:
		_lbl_seed.text = "Seed: %d" % GM.partida_seed
	_atualizar_jogadores()
	_atualizar_preview()
	var humano: bool = j != null and not j.ehIA
	_btn_rot.disabled = not (humano and GM.estadoAtual is ColocandoPeca)
	var fase_meeple: bool = _fase_meeple_humano()
	var tem_opcao: bool = fase_meeple and not _segmentos_jogaveis().is_empty()
	_btn_explorar.visible = tem_opcao
	_btn_naocolocar.visible = fase_meeple
	_btn_desfazer.visible = fase_meeple

func _atualizar_jogadores() -> void:
	for c in _box_jogadores.get_children():
		c.queue_free()
	var ativo = GM.jogadorAtivo()
	for jg in GM.jogadores:
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = (jg.cor if jg == ativo else jg.cor.darkened(0.45))
		sb.set_corner_radius_all(6)
		for m in ["content_margin_left", "content_margin_right"]:
			sb.set(m, 8)
		for m in ["content_margin_top", "content_margin_bottom"]:
			sb.set(m, 4)
		if jg == ativo:
			sb.border_color = Color(1, 1, 1)
			sb.set_border_width_all(2)
		row.add_theme_stylebox_override("panel", sb)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		row.add_child(v)
		var lbl := Label.new()
		lbl.text = "%s — %d pts" % [jg.nome, jg.pontos]
		lbl.add_theme_color_override("font_color", Color.WHITE)
		if jg == ativo:
			lbl.add_theme_font_size_override("font_size", 18)
		v.add_child(lbl)
		var icones := HBoxContainer.new()
		icones.add_theme_constant_override("separation", 1)
		var cam := "res://assets/meeple/%s-meeple.png" % jg.corArquivo
		var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
		for i in range(jg.meeplesDisponiveis):
			var ic := TextureRect.new()
			ic.texture = tex
			ic.custom_minimum_size = Vector2(16, 16)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			icones.add_child(ic)
		v.add_child(icones)
		_box_jogadores.add_child(row)

func _atualizar_preview() -> void:
	if GM.tileAtual == null:
		_preview.texture = null
		return
	var cam := "res://assets/tiles/%s0.png" % GM.tileAtual.tipoBase
	if ResourceLoader.exists(cam):
		_preview.texture = load(cam)
	_preview.rotation = GM.tileAtual.rotacao * PI / 2.0

func _mostrar_regras() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Regras (resumo)"
	dlg.dialog_text = "- No seu turno, um tile e sorteado.\n- Rotacione (R) e posicione encaixando as bordas\n  (campo/estrada/cidade) com os vizinhos.\n- As posicoes validas aparecem como pecas transparentes.\n- Depois, escolha onde por 1 meeple (ou pule).\n- Antes do meeple, Desfazer peca ou o botao direito\n  devolve a peca para escolher outro local.\n- Estradas (1/tile), cidades (2/tile + 2/escudo) e\n  mosteiros (9) devolvem o meeple ao serem concluidos.\n- Fazendeiros (campo) ficam no tabuleiro ate o fim."
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)

func _abrir_slots_salvar() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 25
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
	t.text = "Salvar jogo — escolha o slot"
	t.add_theme_font_size_override("font_size", 22)
	vb.add_child(t)
	vb.add_child(HSeparator.new())
	for s in [1, 2, 3]:
		var info := GM.info_slot(s)
		var desc: String = "vazio"
		if info.get("existe", false):
			desc = "Rodada %d (%d jogadores)" % [info["rodada"], info["jogadores"]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 48)
		b.text = "Slot %d — %s" % [s, desc]
		var slot: int = s
		b.pressed.connect(func():
			GM.salvar(slot)
			layer.queue_free()
			_toast("Jogo salvo no slot %d" % slot))
		vb.add_child(b)
	vb.add_child(HSeparator.new())
	var cancelar := Button.new()
	cancelar.text = "Cancelar"
	cancelar.pressed.connect(layer.queue_free)
	vb.add_child(cancelar)

func _toast(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.anchor_left = 0.5
	lbl.anchor_right = 0.5
	lbl.offset_top = 24
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	if _hud_layer != null:
		_hud_layer.add_child(lbl)
		var tw := create_tween()
		tw.tween_interval(1.2)
		tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
		tw.tween_callback(lbl.queue_free)

func _on_tile_sorteado(tile) -> void:
	var j = GM.jogadorAtivo()
	if j != null and not j.ehIA:
		_ghost = tile
		if tile.get_parent() == null:
			tabuleiro.add_child(tile)
		tile.modulate = Color(1, 1, 1, 0.6)
		_atualizar_ghost()
	else:
		_ghost = null
	_atualizar_validos()
	_atualizar_hud()

func _on_estado_mudou(nome) -> void:
	_fechar_dialogo_meeple()
	_ocultar_indicadores_meeple()
	if nome != "ColocandoPeca":
		if _ghost != null and is_instance_valid(_ghost):
			_ghost.modulate = Color(1, 1, 1, 1)
		_ghost = null
	elif GM.tileAtual != null:
		var j = GM.jogadorAtivo()
		if j != null and not j.ehIA:
			_ghost = GM.tileAtual
			if _ghost.get_parent() == null and tabuleiro != null:
				tabuleiro.add_child(_ghost)
			_atualizar_ghost()
	_atualizar_validos()
	_atualizar_hud()
	if nome == "ColocandoMeeple":
		_mostrar_indicadores_meeple()

func _ao_alternar_dominio(ligado: bool) -> void:
	if _overlay_dominio == null:
		return
	_overlay_dominio.ativo = ligado
	if ligado:
		_overlay_dominio.atualizar(tabuleiro)
	else:
		_overlay_dominio.limpar()

func _on_atualizar() -> void:
	_atualizar_validos()
	_atualizar_hud()
	if _overlay_dominio != null and _overlay_dominio.ativo:
		_overlay_dominio.atualizar(tabuleiro)

func _on_vez(_j) -> void:
	_atualizar_hud()

func _on_jogo_acabou(ranking) -> void:
	_fechar_dialogo_meeple()
	await _animar_fim(GM.ultimos_eventos_fim)
	_mostrar_historico(true, ranking)

func _animar_fim(eventos) -> void:
	for ev in eventos:
		var donos: Array = ev["donos"]
		var pos: Vector2 = ev["pos"]
		var pts: int = ev["pts"]
		if donos.is_empty():
			_popup_pontos(pts, pos, Color.WHITE, 0)
		else:
			var i := 0
			for dono in donos:
				_popup_pontos(pts, pos, dono.cor, i)
				i += 1
		for m in ev["meeples"]:
			if is_instance_valid(m):
				m.devolver_animado()
		await get_tree().create_timer(0.5).timeout

func _on_pontuou(pontos, pos_mundo, cor) -> void:
	_popup_pontos(pontos, pos_mundo, cor, 0)

func _popup_pontos(pontos: int, pos_mundo: Vector2, cor, idx: int) -> void:
	if tabuleiro == null:
		return
	var lbl := Label.new()
	lbl.text = "+%d" % pontos
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", cor.lightened(0.3) if cor is Color else Color(1, 0.95, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.z_index = 100
	lbl.position = pos_mundo - Vector2(18, 18) + Vector2(0, idx * 36)
	tabuleiro.add_child(lbl)
	var alvo_y := lbl.position.y - 64
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", alvo_y, 1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT and _fase_meeple_humano():
		cancel_tile_placement()
		get_viewport().set_input_as_handled()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			_zoom(1.1)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			_zoom(0.9)
		elif ev.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			if not _fase_meeple_humano():
				_panning = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_clique_esquerdo()
	elif ev is InputEventMouseMotion:
		if _panning:
			_cam.position -= ev.relative / _cam.zoom
		else:
			_atualizar_ghost()
			_atualizar_ghost_meeple_board()
	elif ev is InputEventKey and ev.pressed and ev.keycode == KEY_R:
		_rotacionar()

func _celula_mouse() -> Vector2i:
	var w := get_global_mouse_position()
	return Vector2i(floori(w.x / TAM), floori(w.y / TAM))

func _atualizar_ghost() -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		return
	if not (GM.estadoAtual is ColocandoPeca):
		return
	var cell := _celula_mouse()
	_ghost.position = Vector2(cell) * TAM
	var pos := Posicao.new(cell.x, cell.y)
	if GM.tabuleiro.podeColocar(_ghost, pos):
		_ghost.modulate = Color(0.5, 1.0, 0.5, 0.75)
	else:
		_ghost.modulate = Color(1.0, 0.5, 0.5, 0.75)

func _rotacionar() -> void:
	var j = GM.jogadorAtivo()
	if j == null or j.ehIA:
		return
	if GM.estadoAtual is ColocandoPeca and GM.tileAtual != null:
		GM.tileAtual.rotacionar()
		_atualizar_ghost()
		_atualizar_validos()
		_atualizar_preview()

func _fase_meeple_humano() -> bool:
	var j = GM.jogadorAtivo()
	return j != null and not j.ehIA and GM.estadoAtual is ColocandoMeeple

func cancel_tile_placement() -> void:
	if not _fase_meeple_humano():
		return
	GM.cancel_tile_placement()

func _clique_esquerdo() -> void:
	var j = GM.jogadorAtivo()
	if j == null or j.ehIA:
		return
	if GM.estadoAtual is ColocandoPeca and GM.tileAtual != null:
		var cell := _celula_mouse()
		var pos := Posicao.new(cell.x, cell.y)
		if GM.tabuleiro.podeColocar(GM.tileAtual, pos):
			GM.colocarPeca(GM.tileAtual, pos)
	elif GM.estadoAtual is ColocandoMeeple:
		var f = _segmento_mais_proximo(get_global_mouse_position())
		if f != null:
			GM.colocarMeeple(f)

func _atualizar_ghost_meeple_board() -> void:
	if not _fase_meeple_humano():
		return
	_destacar_indicador_sob_mouse()

func _segmento_mais_proximo(world: Vector2):
	if GM.ultimaPeca == null:
		return null
	var base: Vector2 = (GM.ultimaPeca as Node2D).position
	var melhor = null
	var melhor_d := 44.0
	for f in _segmentos_jogaveis():
		var d := world.distance_to(base + _ancora(f))
		if d < melhor_d:
			melhor_d = d
			melhor = f
	return melhor

func _zoom(fator: float) -> void:
	var z: float = clampf(_cam.zoom.x * fator, 0.3, 2.5)
	_cam.zoom = Vector2(z, z)

func _toggle_encaixes() -> void:
	_ver_encaixes = not _ver_encaixes
	if _btn_encaixes != null:
		_btn_encaixes.text = "Ver encaixes: %s" % ("SIM" if _ver_encaixes else "NAO")
	_atualizar_validos()

func _toggle_dominio() -> void:
	_ver_dominio = not _ver_dominio
	if _btn_dominio != null:
		_btn_dominio.text = "Mostrar Dominio: %s" % ("SIM" if _ver_dominio else "NAO")
	_ao_alternar_dominio(_ver_dominio)

func _atualizar_validos() -> void:
	if _validos == null:
		return
	for c in _validos.get_children():
		c.queue_free()
	if not _ver_encaixes:
		return
	var j = GM.jogadorAtivo()
	if j == null or j.ehIA:
		return
	if not (GM.estadoAtual is ColocandoPeca) or GM.tileAtual == null:
		return
	var cam := "res://assets/tiles/%s0.png" % GM.tileAtual.tipoBase
	if not ResourceLoader.exists(cam):
		return
	var tex: Texture2D = load(cam)
	for pos in GM.tabuleiro.posicoes_candidatas():
		if GM.tabuleiro.podeColocar(GM.tileAtual, pos):
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = true
			s.position = Vector2(pos.vetor()) * TAM + Vector2(TAM * 0.5, TAM * 0.5)
			s.scale = Vector2.ONE * (TAM / float(tex.get_width()))
			s.rotation_degrees = GM.tileAtual.rotacao * 90
			s.modulate = Color(0.5, 1.0, 0.6, 0.35)
			_validos.add_child(s)

func _ancora(ft) -> Vector2:
	if ft == null:
		return Vector2(TAM * 0.5, TAM * 0.5)
	return ft.ancora_norm * TAM

func _segmentos_jogaveis() -> Array:
	var r := []
	for d in _segmentos_todos():
		if d["ok"]:
			r.append(d["f"])
	return r

func _segmentos_todos() -> Array:
	var r := []
	if GM.ultimaPeca == null:
		return r
	var j = GM.jogadorAtivo()
	for f in GM.ultimaPeca.features:
		var ok := true
		var motivo := ""
		if j == null or j.meeplesDisponiveis <= 0:
			ok = false
			motivo = "sem meeples na reserva"
		elif not GM.tabuleiro.podeColocarMeeple(f):
			ok = false
			motivo = "ja ha meeple nesta estrutura"
		r.append({"f": f, "ok": ok, "motivo": motivo})
	return r

func _explorar_opcoes() -> void:
	if not _segmentos_jogaveis().is_empty():
		_abrir_dialogo_meeple(_segmentos_todos())

func _abrir_dialogo_meeple(segs: Array) -> void:
	_fechar_dialogo_meeple()
	var layer := CanvasLayer.new()
	layer.layer = 20
	_dlg_meeple = layer
	add_child(layer)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.78)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		mc.add_theme_constant_override(m, 28)
	layer.add_child(mc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	mc.add_child(vb)

	var t := Label.new()
	t.text = "Onde colocar o meeple?"
	t.add_theme_font_size_override("font_size", 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 14)
	flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	vb.add_child(flow)

	var cont := {}
	for d in segs:
		cont[d["f"].tipo] = cont.get(d["f"].tipo, 0) + 1
	var idx := {}
	var jogador = GM.jogadorAtivo()
	for d in segs:
		var f = d["f"]
		var tipo: int = f.tipo
		var rotulo: String = _NOME_TIPO.get(tipo, "Segmento")
		if cont[tipo] > 1:
			idx[tipo] = idx.get(tipo, 0) + 1
			rotulo += " #%d" % idx[tipo]
		flow.add_child(_card_opcao(tipo, rotulo, f, jogador, d["ok"], d["motivo"]))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 20)
	vb.add_child(bottom)
	var fechar := Button.new()
	fechar.text = "Fechar"
	fechar.custom_minimum_size = Vector2(160, 46)
	fechar.pressed.connect(_fechar_dialogo_meeple)
	bottom.add_child(fechar)
	var desfazer := Button.new()
	desfazer.text = "Desfazer peca"
	desfazer.custom_minimum_size = Vector2(180, 46)
	var sbd := StyleBoxFlat.new()
	sbd.bg_color = Color(0.45, 0.32, 0.08)
	sbd.set_corner_radius_all(6)
	desfazer.add_theme_stylebox_override("normal", sbd)
	desfazer.pressed.connect(cancel_tile_placement)
	bottom.add_child(desfazer)
	var naoc := Button.new()
	naoc.text = "Nao colocar Meeple"
	naoc.custom_minimum_size = Vector2(220, 46)
	var sbv := StyleBoxFlat.new()
	sbv.bg_color = Color(0.6, 0.15, 0.15)
	sbv.set_corner_radius_all(6)
	naoc.add_theme_stylebox_override("normal", sbv)
	naoc.pressed.connect(func():
		_fechar_dialogo_meeple()
		GM.pular())
	bottom.add_child(naoc)

func _card_opcao(tipo: int, rotulo: String, feature, jogador, ok: bool, motivo: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 176)
	b.disabled = not ok
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prev := TextureRect.new()
	prev.texture = _imagem_tile_meeple(GM.ultimaPeca, feature, jogador)
	prev.custom_minimum_size = Vector2(128, 128)
	prev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ok:
		prev.modulate = Color(1, 1, 1, 0.4)
	vb.add_child(prev)
	var l := Label.new()
	l.text = rotulo if ok else "%s\n(%s)" % [rotulo, motivo]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(140, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ok:
		l.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	vb.add_child(l)
	b.add_child(vb)
	if ok:
		b.pressed.connect(func():
			_fechar_dialogo_meeple()
			GM.colocarMeeple(feature))
	return b

func _mostrar_indicadores_meeple() -> void:
	_ocultar_indicadores_meeple()
	if not _fase_meeple_humano() or GM.ultimaPeca == null or tabuleiro == null:
		return
	var jogador = GM.jogadorAtivo()
	var base: Vector2 = (GM.ultimaPeca as Node2D).position
	for f in _segmentos_jogaveis():
		var s := _criar_sprite_meeple(jogador)
		s.position = base + _ancora(f)
		s.modulate = Color(1, 1, 1, 0.62)
		s.set_meta("feature", f)
		s.set_meta("escala", s.scale)
		tabuleiro.add_child(s)
		_indicadores_meeple.append(s)

func _ocultar_indicadores_meeple() -> void:
	for s in _indicadores_meeple:
		if is_instance_valid(s):
			s.queue_free()
	_indicadores_meeple.clear()

func _destacar_indicador_sob_mouse() -> void:
	var alvo = _segmento_mais_proximo(get_global_mouse_position())
	for s in _indicadores_meeple:
		if not is_instance_valid(s):
			continue
		var base_scale: Vector2 = s.get_meta("escala")
		var em_cima: bool = alvo != null and s.get_meta("feature") == alvo
		if em_cima:
			s.scale = base_scale * 1.3
			s.modulate = Color(1.25, 1.25, 0.85, 1.0)
			s.z_index = 51
		else:
			s.scale = base_scale
			s.modulate = Color(1, 1, 1, 0.62)
			s.z_index = 50

func _criar_sprite_meeple(jogador) -> Sprite2D:
	var s := Sprite2D.new()
	s.z_index = 50
	var cam := "res://assets/meeple/%s-meeple.png" % (jogador.corArquivo if jogador else "blue")
	if ResourceLoader.exists(cam):
		var tex: Texture2D = load(cam)
		s.texture = tex
		s.scale = Vector2.ONE * (TAM * 0.24 / float(tex.get_width()))
	return s

func _ghost_meeple_mostrar(feature, _jogador) -> void:
	if _indicadores_meeple.is_empty():
		_mostrar_indicadores_meeple()
	for s in _indicadores_meeple:
		if is_instance_valid(s) and s.get_meta("feature") == feature:
			var base_scale: Vector2 = s.get_meta("escala")
			s.scale = base_scale * 1.3
			s.modulate = Color(1.25, 1.25, 0.85, 1.0)
			s.z_index = 51

func _imagem_tile_meeple(tile, feature, jogador) -> Texture2D:
	var cam := "res://assets/tiles/%s0.png" % tile.tipoBase
	if not ResourceLoader.exists(cam):
		return null
	var img: Image = (load(cam) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for _i in range(tile.rotacao):
		img.rotate_90(CLOCKWISE)
	var ts := img.get_width()
	var mcam := "res://assets/meeple/%s-meeple.png" % (jogador.corArquivo if jogador else "blue")
	if ResourceLoader.exists(mcam):
		var mimg: Image = (load(mcam) as Texture2D).get_image()
		if mimg.is_compressed():
			mimg.decompress()
		mimg.convert(Image.FORMAT_RGBA8)
		var msz := int(ts * 0.24)
		mimg.resize(msz, msz, Image.INTERPOLATE_BILINEAR)
		var a := _ancora(feature)
		var px := int(a.x / TAM * ts) - msz / 2
		var py := int(a.y / TAM * img.get_height()) - msz / 2
		img.blend_rect(mimg, Rect2i(0, 0, msz, msz), Vector2i(px, py))
	return ImageTexture.create_from_image(img)

func _fechar_dialogo_meeple() -> void:
	if _dlg_meeple != null and is_instance_valid(_dlg_meeple):
		_dlg_meeple.queue_free()
	_dlg_meeple = null

func _mostrar_historico(ao_fim: bool, ranking) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 28
	add_child(layer)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.82)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		mc.add_theme_constant_override(m, 28)
	layer.add_child(mc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	mc.add_child(vb)
	var t := Label.new()
	t.text = "Fim de jogo — Historico de pontuacao" if ao_fim else "Historico de pontuacao"
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(0.96, 0.86, 0.5))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	grid.add_child(_hdr("Jogador"))
	grid.add_child(_hdr("Grupo"))
	grid.add_child(_hdr("Pontos"))
	if GM.historico.is_empty():
		var vazio := Label.new()
		vazio.text = "(ainda sem pontuacoes)"
		vazio.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		grid.add_child(vazio)
		grid.add_child(Label.new())
		grid.add_child(Label.new())
	for h in GM.historico:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var sw := ColorRect.new()
		sw.color = h["cor"]
		sw.custom_minimum_size = Vector2(16, 16)
		hb.add_child(sw)
		var ln := Label.new()
		ln.text = h["nome"]
		hb.add_child(ln)
		grid.add_child(hb)
		var thumb := TextureRect.new()
		thumb.texture = h["tex"]
		grid.add_child(thumb)
		var lp := Label.new()
		lp.text = "+%d" % h["pts"]
		lp.add_theme_font_size_override("font_size", 18)
		grid.add_child(lp)

	vb.add_child(HSeparator.new())
	var hbtn := HBoxContainer.new()
	hbtn.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hbtn)
	if ao_fim:
		var bres := Button.new()
		bres.text = "Ver resultado"
		bres.custom_minimum_size = Vector2(200, 46)
		bres.pressed.connect(func():
			layer.queue_free()
			_criar_painel_fim(ranking))
		hbtn.add_child(bres)
	else:
		var bf := Button.new()
		bf.text = "Fechar"
		bf.custom_minimum_size = Vector2(160, 46)
		bf.pressed.connect(layer.queue_free)
		hbtn.add_child(bf)

func _hdr(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.96, 0.86, 0.5))
	return l

func _criar_painel_fim(ranking: Array) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var cx := CenterContainer.new()
	cx.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cx)
	var painel := PanelContainer.new()
	cx.add_child(painel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(380, 0)
	painel.add_child(vb)
	var t := Label.new()
	t.text = "Fim de jogo!"
	t.add_theme_font_size_override("font_size", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if not ranking.is_empty():
		var venc := Label.new()
		venc.text = "Vencedor: %s" % ranking[0].nome
		venc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		venc.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		vb.add_child(venc)
	vb.add_child(HSeparator.new())
	var pos := 1
	for jg in ranking:
		var l := Label.new()
		l.text = "%d. %s — %d pts" % [pos, jg.nome, jg.pontos]
		vb.add_child(l)
		pos += 1
	vb.add_child(HSeparator.new())
	var b := Button.new()
	b.text = "Voltar ao menu"
	b.pressed.connect(func(): if main: main.ir_inicial())
	vb.add_child(b)
