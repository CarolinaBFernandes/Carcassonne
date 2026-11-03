class_name IA
extends Jogador

const TEMPO_MAX_MS := 6000

func _init(_nome: String = "", _corArquivo: String = "red", _cor: Color = Color.WHITE) -> void:
	super(_nome, _corArquivo, _cor)
	ehIA = true

func avaliarJogadas(tabuleiro, tile) -> Array:
	var jogadas := []
	var inicio := Time.get_ticks_msec()
	for pos in tabuleiro.posicoes_candidatas():
		for _r in range(4):
			if tabuleiro.podeColocar(tile, pos):
				var j := JogadaIA.new(pos, tile.rotacao, _valor_posicao(tabuleiro, pos))
				j.tile = tile
				jogadas.append(j)
			tile.rotacionar()
		if Time.get_ticks_msec() - inicio > TEMPO_MAX_MS - 500:
			break
	return jogadas

func escolherJogada(tabuleiro, tile) -> JogadaIA:
	var jogadas := avaliarJogadas(tabuleiro, tile)
	if jogadas.is_empty():
		return null
	var melhor: JogadaIA = jogadas[0]
	for j in jogadas:
		if j.compareTo(melhor) > 0:
			melhor = j
	while tile.rotacao != melhor.rotacao:
		tile.rotacionar()
	melhor.tile = tile
	melhor.meepleEm = _escolher_meeple(tile)
	return melhor

func _valor_posicao(tabuleiro, pos: Posicao) -> float:
	var viz := 0
	for d in Direcao.TODAS:
		if tabuleiro.getTile(pos.somar_direcao(d)) != null:
			viz += 1
	return float(viz) + randf() * 0.5

func _escolher_meeple(tile):
	if meeplesDisponiveis <= 0:
		return null
	var prioridade := {
		FeatureTile.Tipo.CIDADE: 3,
		FeatureTile.Tipo.MOSTEIRO: 2,
		FeatureTile.Tipo.ESTRADA: 1,
		FeatureTile.Tipo.CAMPO: -1,
	}
	var melhor = null
	var mp := 0
	for f in tile.features:
		var p: int = prioridade[f.tipo]
		if p > mp:
			mp = p
			melhor = f
	return melhor
