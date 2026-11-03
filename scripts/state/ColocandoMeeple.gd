class_name ColocandoMeeple
extends EstadoJogo

func nome() -> String:
	return "ColocandoMeeple"

func entrada() -> void:
	var j = contexto.jogadorAtivo()
	if j != null and j.meeplesDisponiveis <= 0:
		contexto.call_deferred("pular")

func colocarMeeple(ft) -> bool:
	if ft == null or ft.tile != contexto.ultimaPeca:
		return false
	var grupo: Array = contexto.tabuleiro.getGrupoConectado(ft)
	for f in grupo:
		if not f.meeples.is_empty():
			return false
	var j = contexto.jogadorAtivo()
	if j.meeplesDisponiveis <= 0:
		return false
	j.colocarMeeple(ft)
	contexto.emit_signal("tabuleiro_mudou")
	_finalizar()
	return true

func pular() -> void:
	_finalizar()

func _finalizar() -> void:
	_pontuar_tile(contexto.ultimaPeca)
	contexto.emit_signal("pontuacao_mudou")
	contexto.avancar_turno()

func _pontuar_tile(tile) -> void:
	var tab = contexto.tabuleiro
	var scored: Array = []
	for f in tile.features:
		if f.tipo == FeatureTile.Tipo.CIDADE or f.tipo == FeatureTile.Tipo.ESTRADA:
			var grupo: Array = tab.getGrupoConectado(f)
			if _ja_contado(scored, grupo):
				continue
			scored.append(grupo)
			if f.estaCompleta(grupo) and _grupo_tem_meeple(grupo):
				_pontuar_e_devolver(grupo)
	var candidatos: Array = [tile]
	for v in tab.getAoRedor(tile):
		candidatos.append(v)
	for t in candidatos:
		var fm = t.mosteiro()
		if fm != null and not fm.meeples.is_empty() and fm.estaCompleta([fm]):
			_pontuar_e_devolver([fm])

func _grupo_tem_meeple(grupo: Array) -> bool:
	for f in grupo:
		if not f.meeples.is_empty():
			return true
	return false

func _pontuar_e_devolver(grupo: Array) -> void:
	var rep = grupo[0]
	var pts: int = rep.calcularPontos(grupo)
	var donos: Array = rep.donos_majoritarios(grupo)
	if pts > 0:
		for j in donos:
			j.creditarPontos(pts)
	if contexto != null and not donos.is_empty():
		var tex = HistoricoUtil.imagem_grupo(grupo)
		for j in donos:
			contexto.historico.append({"nome": j.nome, "cor": j.cor, "pts": pts, "tex": tex})
	var centros := Vector2.ZERO
	var tiles: Array = rep.tiles_do_grupo(grupo)
	for t in tiles:
		centros += Vector2(t.posicao.vetor()) * Tile.TAM + Vector2(Tile.TAM * 0.5, Tile.TAM * 0.5)
	if not tiles.is_empty() and pts > 0 and contexto != null:
		var base_pos: Vector2 = centros / float(tiles.size())
		var i := 0
		for j in donos:
			contexto.emit_signal("pontuou", pts, base_pos + Vector2(0, i * 36), j.cor)
			i += 1
	for f in grupo:
		if f.tipo == FeatureTile.Tipo.CAMPO:
			continue
		for m in f.meeples:
			if m.dono != null:
				m.dono.devolverMeeple()
			if is_instance_valid(m):
				m.devolver_animado()
		f.meeples.clear()

func _ja_contado(lista: Array, grupo: Array) -> bool:
	for g in lista:
		if g.size() != grupo.size():
			continue
		var todos := true
		for x in grupo:
			if not g.has(x):
				todos = false
				break
		if todos:
			return true
	return false
