extends SceneTree

func _initialize() -> void:
	var gm = GameManager.new()
	get_root().add_child(gm)
	var tab = Tabuleiro.new()
	get_root().add_child(tab)
	var cfg = [
		{"nome": "A", "corArquivo": "green", "cor": Color.GREEN, "ehIA": false},
		{"nome": "B", "corArquivo": "blue", "cor": Color.BLUE, "ehIA": false},
	]
	gm.iniciarPartida(cfg, tab)
	for i in range(4):
		var t = gm.tileAtual
		var ok := false
		for pos in gm.tabuleiro.posicoes_candidatas():
			for _r in range(4):
				if gm.tabuleiro.podeColocar(t, pos):
					gm.colocarPeca(t, pos)
					ok = true
					break
				t.rotacionar()
			if ok:
				break
		gm.pular()
	var a_tiles = gm.tabuleiro.tiles().size()
	var a_pool = gm.deck.restantes()
	var a_estado = gm.estadoNome()
	print("ANTES  tiles=%d pool=%d estado=%s jogadores=%d" % [a_tiles, a_pool, a_estado, gm.jogadores.size()])
	print("salvar=", gm.salvar(1))

	var tab2 = Tabuleiro.new()
	get_root().add_child(tab2)
	print("carregar=", gm.carregar(1, tab2))
	var d_tiles = gm.tabuleiro.tiles().size()
	var d_pool = gm.deck.restantes()
	print("DEPOIS tiles=%d pool=%d estado=%s jogadores=%d" % [d_tiles, d_pool, gm.estadoNome(), gm.jogadores.size()])
	print("MATCH  tiles=%s pool=%s estado=%s" % [d_tiles == a_tiles, d_pool == a_pool, gm.estadoNome() == a_estado])
	quit()
