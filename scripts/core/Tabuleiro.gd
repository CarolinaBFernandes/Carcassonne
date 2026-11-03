class_name Tabuleiro
extends Node2D

const TAM := 128.0

var _tiles := {}

func posicionar(tile: Tile, posicao: Posicao) -> void:
	tile.setPosicao(posicao)
	tile.tabuleiro = self
	_tiles[posicao.chave()] = tile
	if tile.get_parent() == null:
		add_child(tile)
	tile.position = Vector2(posicao.vetor()) * TAM

func getTile(posicao: Posicao) -> Tile:
	if posicao == null:
		return null
	return _tiles.get(posicao.chave(), null)

func vazio() -> bool:
	return _tiles.is_empty()

func tiles() -> Array:
	return _tiles.values()

func getVizinho(tile: Tile, direcao: int) -> Tile:
	return getTile(tile.posicao.somar_direcao(direcao))

func getVizinhos(tile: Tile) -> Array:
	var r := []
	for d in Direcao.TODAS:
		var v := getVizinho(tile, d)
		if v != null:
			r.append(v)
	return r

func getAoRedor(tile: Tile) -> Array:
	var r := []
	var base := tile.posicao.vetor()
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var t := getTile(Posicao.de_vetor(base + Vector2i(dx, dy)))
			if t != null:
				r.append(t)
	return r

func podeColocar(tile: Tile, posicao: Posicao) -> bool:
	if getTile(posicao) != null:
		return false
	var vizinhos := 0
	for d in Direcao.TODAS:
		var nb := getTile(posicao.somar_direcao(d))
		if nb != null:
			vizinhos += 1
			if tile.bordaTipo(d) != nb.bordaTipo(Direcao.oposta(d)):
				return false
	return vizinhos > 0

func existePosicaoValida(tile: Tile) -> bool:
	for pos in posicoes_candidatas():
		var achou := false
		for _r in range(4):
			if podeColocar(tile, pos):
				achou = true
			tile.rotacionar()
		if achou:
			return true
	return false

func posicoes_candidatas() -> Array:
	if vazio():
		return [Posicao.new(0, 0)]
	var vistas := {}
	var res := []
	for t in _tiles.values():
		for d in Direcao.TODAS:
			var p: Posicao = t.posicao.somar_direcao(d)
			if getTile(p) == null and not vistas.has(p.chave()):
				vistas[p.chave()] = true
				res.append(p)
	return res

func getGrupoConectado(ft) -> Array:
	var grupo := [ft]
	if ft.direcoes.is_empty():
		return grupo
	var fila := [ft]
	while not fila.is_empty():
		var f = fila.pop_back()
		for d in f.direcoes:
			var nb := getTile(Posicao.de_vetor(f.tile.posicao.vetor() + Direcao.vetor(d)))
			if nb == null:
				continue
			var oposto := Direcao.oposta(d)
			for g in nb.features:
				if g.tipo == f.tipo and g.direcoes.has(oposto) and not grupo.has(g):
					grupo.append(g)
					fila.append(g)
	return grupo

func calcularPontos() -> Array:
	var eventos := []
	var vistos := []
	for t in _tiles.values():
		for f in t.features:
			if f.meeples.is_empty():
				continue
			var ja := false
			for g in vistos:
				if g.has(f):
					ja = true
					break
			if ja:
				continue
			var grupo := getGrupoConectado(f)
			vistos.append(grupo)
			var pts: int = f.calcularPontos(grupo)
			var centro := Vector2.ZERO
			var tiles_grp: Array = f.tiles_do_grupo(grupo)
			for tt in tiles_grp:
				centro += Vector2(tt.posicao.vetor()) * TAM + Vector2(TAM * 0.5, TAM * 0.5)
			if not tiles_grp.is_empty():
				centro /= float(tiles_grp.size())
			var meeps := []
			for gf in grupo:
				for m in gf.meeples:
					meeps.append(m)
			var donos := []
			if pts > 0:
				for j in f.donos_majoritarios(grupo):
					j.creditarPontos(pts)
					donos.append(j)
			else:
				for m in meeps:
					if m.dono != null and not donos.has(m.dono):
						donos.append(m.dono)
			var tex = HistoricoUtil.imagem_grupo(grupo)
			eventos.append({"pts": pts, "pos": centro, "donos": donos, "meeples": meeps, "tex": tex})
			for gf in grupo:
				gf.meeples.clear()
	return eventos
