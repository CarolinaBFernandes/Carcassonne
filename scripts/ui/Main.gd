extends Node

const S_INICIAL := preload("res://scenes/TelaInicial.tscn")
const S_CONFIG := preload("res://scenes/TelaConfiguracao.tscn")
const S_JOGO := preload("res://scenes/Jogo.tscn")

var atual: Node = null

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "autoia" in args:
		_auto_ia(false)
		return
	if "shot" in args:
		_auto_ia(true)
		return
	if "shotmenu" in args:
		ir_inicial()
		_capturar(2.0)
		return
	if "demo" in args:
		_demo()
		return
	if "demobloq" in args:
		_demo_bloqueio()
		return
	if "shotcampo" in args:
		var cfgc := [
			{"nome": "Voce", "corArquivo": "green", "cor": Color(0.2, 0.65, 0.25), "ehIA": false},
			{"nome": "IA", "corArquivo": "blue", "cor": Color(0.15, 0.35, 0.75), "ehIA": true},
		]
		ir_jogo(cfgc)
		await get_tree().create_timer(0.5).timeout
		var t = GM.deck.criar_tile("CastleMini", 0)
		GM.tileAtual = t
		for pos in GM.tabuleiro.posicoes_candidatas():
			var ok := false
			for _r in range(4):
				if GM.tabuleiro.podeColocar(t, pos):
					ok = true
					break
				t.rotacionar()
			if ok:
				GM.colocarPeca(t, pos)
				break
		await get_tree().create_timer(0.3).timeout
		if atual != null and atual.has_method("_explorar_opcoes"):
			atual._explorar_opcoes()
		await get_tree().create_timer(0.3).timeout
		_salvar("user://shot_campo.png")
		get_tree().quit()
		return
	if "shotfim" in args:
		var cfgf := [
			{"nome": "Voce", "corArquivo": "green", "cor": Color(0.2, 0.65, 0.25), "ehIA": false},
			{"nome": "IA", "corArquivo": "blue", "cor": Color(0.15, 0.35, 0.75), "ehIA": true},
		]
		ir_jogo(cfgf)
		await get_tree().create_timer(0.5).timeout
		var st = GM.ultimaPeca
		for f in st.features:
			if f.tipo == FeatureTile.Tipo.ESTRADA:
				GM.jogadores[0].colocarMeeple(f)
				break
		for f in st.features:
			if f.tipo == FeatureTile.Tipo.CAMPO:
				GM.jogadores[0].colocarMeeple(f)
				break
		GM.mudarEstado(FimDeJogo.new())
		await get_tree().create_timer(0.3).timeout
		_salvar("user://shot_fim.png")
		await get_tree().create_timer(1.6).timeout
		_salvar("user://shot_hist.png")
		get_tree().quit()
		return
	if "shotescudo" in args:
		var cfg2 := [
			{"nome": "Voce", "corArquivo": "green", "cor": Color(0.2, 0.65, 0.25), "ehIA": false},
			{"nome": "IA", "corArquivo": "blue", "cor": Color(0.15, 0.35, 0.75), "ehIA": true},
		]
		ir_jogo(cfg2)
		await get_tree().create_timer(0.5).timeout
		var t = GM.deck.criar_tile("CastleCenterSides", 0)
		GM.tileAtual = t
		for pos in GM.tabuleiro.posicoes_candidatas():
			var ok := false
			for _r in range(4):
				if GM.tabuleiro.podeColocar(t, pos):
					ok = true
					break
				t.rotacionar()
			if ok:
				GM.colocarPeca(t, pos)
				break
		await get_tree().create_timer(0.4).timeout
		_salvar("user://shot_escudo.png")
		get_tree().quit()
		return
	if "shotcfg" in args:
		ir_configuracao()
		await get_tree().create_timer(0.4).timeout
		_salvar("user://shot_cfg.png")
		get_tree().quit()
		return
	if "shotload" in args:
		ir_inicial()
		await get_tree().create_timer(0.4).timeout
		if atual != null and atual.has_method("_on_carregar"):
			atual._on_carregar()
		await get_tree().create_timer(0.3).timeout
		_salvar("user://shot_load.png")
		get_tree().quit()
		return
	ir_inicial()

func _demo_bloqueio() -> void:
	var cfg := [
		{"nome": "Voce", "corArquivo": "green", "cor": Color(0.2, 0.65, 0.25), "ehIA": false},
		{"nome": "IA", "corArquivo": "blue", "cor": Color(0.15, 0.35, 0.75), "ehIA": true},
	]
	ir_jogo(cfg)
	await get_tree().create_timer(0.5).timeout
	var st = GM.ultimaPeca
	for f in st.features:
		if f.tipo == FeatureTile.Tipo.ESTRADA:
			GM.jogadorAtivo().colocarMeeple(f)
			break

	var t = GM.deck.criar_tile("Road", 1)
	GM.tileAtual = t
	GM.colocarPeca(t, Posicao.new(1, 0))
	await get_tree().create_timer(0.4).timeout
	if atual != null and atual.has_method("_explorar_opcoes"):
		atual._explorar_opcoes()
	await get_tree().create_timer(0.3).timeout
	_salvar("user://shot_bloq.png")
	get_tree().quit()

func _demo() -> void:
	var cfg := [
		{"nome": "Voce", "corArquivo": "green", "cor": Color(0.2, 0.65, 0.25), "ehIA": false},
		{"nome": "IA", "corArquivo": "blue", "cor": Color(0.15, 0.35, 0.75), "ehIA": true},
	]
	ir_jogo(cfg)
	await get_tree().create_timer(1.0).timeout
	_salvar("user://shot_ghost.png")

	for pos in GM.tabuleiro.posicoes_candidatas():
		var ok := false
		for _r in range(4):
			if GM.tabuleiro.podeColocar(GM.tileAtual, pos):
				ok = true
				break
			GM.tileAtual.rotacionar()
		if ok:
			GM.colocarPeca(GM.tileAtual, pos)
			break
	await get_tree().create_timer(0.8).timeout

	if atual != null and atual.has_method("_segmentos_jogaveis"):
		var segs: Array = atual._segmentos_jogaveis()
		if not segs.is_empty():
			atual._ghost_meeple_mostrar(segs[0], GM.jogadorAtivo())
	await get_tree().create_timer(0.3).timeout
	_salvar("user://shot_board.png")

	if atual != null and atual.has_method("_explorar_opcoes"):
		atual._explorar_opcoes()
	await get_tree().create_timer(0.3).timeout
	_salvar("user://shot_menu.png")

	if atual != null:
		atual._fechar_dialogo_meeple()
		atual._abrir_slots_salvar()
	await get_tree().create_timer(0.3).timeout
	_salvar("user://shot_save.png")
	get_tree().quit()

func _salvar(caminho: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(caminho)
	print("SHOT ", caminho)

func _capturar(espera: float) -> void:
	await get_tree().create_timer(espera).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot.png")
	get_tree().quit()

var _auto_visual := false

func _auto_ia(visual: bool) -> void:
	_auto_visual = visual
	GM.auto_rapido = not visual
	GM.jogo_acabou.connect(_on_auto_fim)
	var cores := [["Verde", "green"], ["Azul", "blue"], ["Vermelho", "red"], ["Amarelo", "yellow"]]
	var cfg: Array = []
	for c in cores:
		cfg.append({"nome": c[0], "corArquivo": c[1], "cor": Color.WHITE, "ehIA": true})
	ir_jogo(cfg)
	if visual:
		_agendar_screenshot()

func _on_auto_fim(r: Array) -> void:
	print("=== FIM DE JOGO ===")
	for jg in r:
		print("%s: %d pts" % [jg.nome, jg.pontos])
	await get_tree().create_timer(1.0).timeout
	_auditar_meeples()
	if not _auto_visual:
		get_tree().quit()

func _auditar_meeples() -> void:
	var por_dono := {}
	var nos := 0
	for t in GM.tabuleiro.tiles():
		for f in t.features:
			for m in f.meeples:
				por_dono[m.dono] = por_dono.get(m.dono, 0) + 1
		for c in t.get_children():
			if c is Meeple:
				nos += 1
	var logico_total := 0
	for jg in GM.jogadores:
		var colocados: int = por_dono.get(jg, 0)
		logico_total += colocados
		print("AUDIT %s: reserva=%d colocados=%d soma=%d" % [jg.nome, jg.meeplesDisponiveis, colocados, jg.meeplesDisponiveis + colocados])
	print("AUDIT sprites_meeple=%d  meeples_logicos=%d" % [nos, logico_total])

func _agendar_screenshot() -> void:
	await get_tree().create_timer(6.0).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot.png")
	print("SHOT salvo em user://shot.png")
	get_tree().quit()

func _troca(ps: PackedScene) -> Node:
	if atual != null and is_instance_valid(atual):
		atual.queue_free()
	atual = ps.instantiate()
	atual.set("main", self)
	add_child(atual)
	return atual

func ir_inicial() -> void:
	_troca(S_INICIAL)

func ir_configuracao() -> void:
	_troca(S_CONFIG)

func ir_jogo(configs: Array, seed: int = 0) -> void:
	var j := _troca(S_JOGO)
	j.set("configs", configs)
	j.set("seed_inicial", seed)
	if j.has_method("iniciar"):
		j.iniciar()

func carregar_jogo(slot: int) -> void:
	var j := _troca(S_JOGO)
	j.set("carregar_slot", slot)
	if j.has_method("iniciar"):
		j.iniciar()
