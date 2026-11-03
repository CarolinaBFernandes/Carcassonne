extends Node
class_name GameManager

signal tile_sorteado(tile)
signal estado_mudou(nome)
signal tabuleiro_mudou()
signal pontuacao_mudou()
signal vez_mudou(jogador)
signal jogo_acabou(ranking)
signal pontuou(pontos, pos_mundo, cor)

var tabuleiro = null
var deck = null
var jogadores: Array = []
var rodada = null
var rodadas: Array = []
var estadoAtual = null
var tileAtual = null
var ultimaPeca = null
var auto_rapido := false
var partida_seed := 0
var ultimos_eventos_fim: Array = []
var historico: Array = []

static func getInstancia():
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null("/root/GM")
	return null

func jogadorAtivo():
	return rodada.jogadorAtivo() if rodada != null else null

func estadoNome() -> String:
	return estadoAtual.nome() if estadoAtual != null else ""

func iniciarPartida(configs: Array, tab, semente: int = 0) -> void:
	jogadores.clear()
	for c in configs:
		var j
		if c.get("ehIA", false):
			j = IA.new(c.get("nome", "IA"), c.get("corArquivo", "red"), c.get("cor", Color.RED))
		else:
			j = Jogador.new(c.get("nome", "Jogador"), c.get("corArquivo", "blue"), c.get("cor", Color.BLUE))
		jogadores.append(j)
	if semente == 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		semente = rng.randi()
		if semente == 0:
			semente = 1
	partida_seed = semente
	historico = []
	tabuleiro = tab
	deck = Deck.new(false, semente)
	var inicial = deck.criar_tile(TilesDef.TILE_INICIAL, 0)
	tabuleiro.posicionar(inicial, Posicao.new(0, 0))
	ultimaPeca = inicial
	rodada = Rodada.new(jogadores, 1)
	rodadas = [rodada]
	estadoAtual = Ocioso.new()
	emit_signal("vez_mudou", jogadorAtivo())
	iniciar_vez()

func iniciar_vez() -> void:
	if deck == null or deck.vazio():
		mudarEstado(FimDeJogo.new())
		return
	var t = deck.sortearTile()
	while t != null and not tabuleiro.existePosicaoValida(t):
		t.free()
		t = deck.sortearTile()
	if t == null:
		mudarEstado(FimDeJogo.new())
		return
	tileAtual = t
	emit_signal("tile_sorteado", t)
	mudarEstado(ColocandoPeca.new())
	if jogadorAtivo() != null and jogadorAtivo().ehIA:
		_agendar_ia()

func avancar_turno() -> void:
	rodada.proximoTurno()
	emit_signal("vez_mudou", jogadorAtivo())
	iniciar_vez()

func colocarPeca(tile, posicao) -> bool:
	return estadoAtual.colocarPeca(self, tile, posicao)

func colocarMeeple(ft) -> bool:
	return estadoAtual.colocarMeeple(self, ft)

func pular() -> void:
	estadoAtual.pular(self)

func mudarEstado(novo) -> void:
	if estadoAtual != null:
		estadoAtual.saida(self)
	estadoAtual = novo
	emit_signal("estado_mudou", novo.nome())
	novo.entrada(self)

func _agendar_ia() -> void:
	await get_tree().create_timer(0.0 if auto_rapido else 0.7).timeout
	_jogar_ia()

func _jogar_ia() -> void:
	if not (estadoAtual is ColocandoPeca):
		return
	var ia = jogadorAtivo()
	var jogada = ia.escolherJogada(tabuleiro, tileAtual)
	if jogada == null:
		pular()
		return
	colocarPeca(tileAtual, jogada.posicao)
	await get_tree().create_timer(0.0 if auto_rapido else 0.4).timeout
	if jogada.meepleEm != null and estadoAtual is ColocandoMeeple:
		if not colocarMeeple(jogada.meepleEm):
			pular()
	elif estadoAtual is ColocandoMeeple:
		pular()

func calcularPontosJogadores() -> void:
	if tabuleiro != null:
		ultimos_eventos_fim = tabuleiro.calcularPontos()
		for ev in ultimos_eventos_fim:
			for dono in ev["donos"]:
				historico.append({"nome": dono.nome, "cor": dono.cor, "pts": ev["pts"], "tex": ev["tex"]})

func determinarVencedor():
	var melhor = null
	for j in jogadores:
		if melhor == null or j.pontos > melhor.pontos:
			melhor = j
	return melhor

func ranking() -> Array:
	var copia := jogadores.duplicate()
	copia.sort_custom(func(a, b): return a.pontos > b.pontos)
	return copia

const SAVE_PATH := "user://save_slot_%d.json"

func _jogador_dict(j) -> Dictionary:
	return {
		"nome": j.nome, "corArquivo": j.corArquivo,
		"cor": [j.cor.r, j.cor.g, j.cor.b], "ehIA": j.ehIA,
		"meeples": j.meeplesDisponiveis, "pontos": j.pontos,
	}

func info_slot(slot: int) -> Dictionary:
	var p := SAVE_PATH % slot
	if not FileAccess.file_exists(p):
		return {"existe": false}
	var f := FileAccess.open(p, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return {"existe": false}
	return {"existe": true, "rodada": int(d.get("rodada", {}).get("numero", 1)), "jogadores": d.get("jogadores", []).size()}

func salvar(slot: int) -> bool:
	if tabuleiro == null:
		return false
	var dados := {}
	dados["seed"] = partida_seed
	dados["rodada"] = {"numero": rodada.numero, "indice": rodada.indiceAtivo}
	dados["estado"] = estadoNome()
	dados["pool"] = deck.pool_tipos()
	var js := []
	for j in jogadores:
		js.append(_jogador_dict(j))
	dados["jogadores"] = js
	var ts := []
	for t in tabuleiro.tiles():
		var meeps := []
		for i in range(t.features.size()):
			for m in t.features[i].meeples:
				meeps.append({"fi": i, "dono": jogadores.find(m.dono)})
		ts.append({
			"tipo": t.tipoBase, "rot": t.rotacao, "x": t.posicao.x, "y": t.posicao.y,
			"por": jogadores.find(t.posicionadoPor), "meeples": meeps,
		})
	dados["tiles"] = ts
	dados["tileAtual"] = ({"tipo": tileAtual.tipoBase, "rot": tileAtual.rotacao} if tileAtual != null else null)
	dados["ultima"] = ({"x": ultimaPeca.posicao.x, "y": ultimaPeca.posicao.y} if ultimaPeca != null else null)
	var f := FileAccess.open(SAVE_PATH % slot, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(dados))
	f.close()
	return true

func carregar(slot: int, tab) -> bool:
	var p := SAVE_PATH % slot
	if not FileAccess.file_exists(p):
		return false
	var f := FileAccess.open(p, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return false
	jogadores.clear()
	for jd in d["jogadores"]:
		var cor := Color(jd["cor"][0], jd["cor"][1], jd["cor"][2])
		var j
		if jd["ehIA"]:
			j = IA.new(jd["nome"], jd["corArquivo"], cor)
		else:
			j = Jogador.new(jd["nome"], jd["corArquivo"], cor)
		j.meeplesDisponiveis = int(jd["meeples"])
		j.pontos = int(jd["pontos"])
		jogadores.append(j)
	partida_seed = int(d.get("seed", 0))
	historico = []
	tabuleiro = tab
	deck = Deck.new()
	deck.carregar_pool(d["pool"])
	rodada = Rodada.new(jogadores, int(d["rodada"]["numero"]))
	rodada.indiceAtivo = int(d["rodada"]["indice"])
	rodadas = [rodada]
	for td in d["tiles"]:
		var t = deck.criar_tile(td["tipo"], int(td["rot"]))
		var por := int(td["por"])
		if por >= 0:
			t.setPosicionadoPor(jogadores[por])
		tabuleiro.posicionar(t, Posicao.new(int(td["x"]), int(td["y"])))
		for md in td["meeples"]:
			var fi := int(md["fi"])
			var dono := int(md["dono"])
			if fi < t.features.size() and dono >= 0:
				var feat = t.features[fi]
				var m = Meeple.new()
				m.configurar(jogadores[dono], feat.tipo)
				feat.adicionaMeeple(m)
				t.add_child(m)
				m.posicionar(feat)
	tileAtual = (deck.criar_tile(d["tileAtual"]["tipo"], int(d["tileAtual"]["rot"])) if d.get("tileAtual") != null else null)
	ultimaPeca = (tabuleiro.getTile(Posicao.new(int(d["ultima"]["x"]), int(d["ultima"]["y"]))) if d.get("ultima") != null else null)
	estadoAtual = _estado_por_nome(str(d.get("estado", "ColocandoPeca")))
	emit_signal("vez_mudou", jogadorAtivo())
	if tileAtual != null:
		emit_signal("tile_sorteado", tileAtual)
	emit_signal("estado_mudou", estadoNome())
	emit_signal("tabuleiro_mudou")
	emit_signal("pontuacao_mudou")
	if estadoAtual is ColocandoPeca and jogadorAtivo() != null and jogadorAtivo().ehIA:
		_agendar_ia()
	return true

func _estado_por_nome(n: String):
	match n:
		"Ocioso": return Ocioso.new()
		"ColocandoMeeple": return ColocandoMeeple.new()
		"FimDeJogo": return FimDeJogo.new()
	return ColocandoPeca.new()
