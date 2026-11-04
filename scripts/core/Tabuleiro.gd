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

func remover(tile: Tile) -> void:
	if tile == null:
		return
	if tile.posicao != null and _tiles.get(tile.posicao.chave()) == tile:
		_tiles.erase(tile.posicao.chave())
	tile.posicao = null
	tile.tabuleiro = null
	tile.posicionadoPor = null

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
	if ft == null:
		return []
	var grupo: Array = [ft]
	var vistos := {ft.get_instance_id(): true}
	var fila: Array = [ft]
	while not fila.is_empty():
		var f = fila.pop_front()
		if f.tile == null or f.tile.posicao == null:
			continue
		if f.tipo == FeatureTile.Tipo.CAMPO:
			for ab in f.aberturas:
				var dir := int(ab / 2)
				var viz := getTile(f.tile.posicao.somar_direcao(dir))
				if viz == null:
					continue
				var espelho: int = Direcao.oposta(dir) * 2 + (1 - (int(ab) % 2))
				for g in viz.features:
					if g.tipo == FeatureTile.Tipo.CAMPO and _tem_int(g.aberturas, espelho):
						_entrar_grupo(grupo, vistos, fila, g)
		else:
			for d in f.direcoes:
				var viz := getTile(f.tile.posicao.somar_direcao(d))
				if viz == null:
					continue
				var oposto := Direcao.oposta(d)
				for g in viz.features:
					if g.tipo == f.tipo and _tem_int(g.direcoes, oposto):
						_entrar_grupo(grupo, vistos, fila, g)
	return grupo

func dominios_campo() -> Array:
	var res: Array = []
	var vistos := {}
	for t in tiles():
		for f in t.features:
			if f.tipo != FeatureTile.Tipo.CAMPO:
				continue
			if vistos.has(f.get_instance_id()):
				continue
			var grupo: Array = getGrupoConectado(f)
			for g in grupo:
				vistos[g.get_instance_id()] = true
			var donos: Array = f.donos_majoritarios(grupo)
			if donos.is_empty():
				continue
			res.append({"features": grupo, "donos": donos})
	return res

func podeColocarMeeple(ft) -> bool:
	if ft == null:
		return false
	for g in getGrupoConectado(ft):
		if not g.meeples.is_empty():
			return false
	return true

func _tem_int(lista: Array, valor: int) -> bool:
	for item in lista:
		if int(item) == valor:
			return true
	return false

func _entrar_grupo(grupo: Array, vistos: Dictionary, fila: Array, g) -> void:
	var id: int = g.get_instance_id()
	if vistos.has(id):
		return
	vistos[id] = true
	grupo.append(g)
	fila.append(g)

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
