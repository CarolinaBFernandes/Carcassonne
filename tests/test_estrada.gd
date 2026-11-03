extends SceneTree

func _initialize() -> void:
	var tab := Tabuleiro.new()

	var t_ini := Tile.new(); t_ini.construir("CastleWallRoad", 0)
	tab.posicionar(t_ini, Posicao.new(0, 0))
	var t_vila := Tile.new(); t_vila.construir("RoadEnd", 1)
	tab.posicionar(t_vila, Posicao.new(1, 0))
	var t_curva := Tile.new(); t_curva.construir("RoadCurve", 3)
	tab.posicionar(t_curva, Posicao.new(-1, 0))
	var t_cidade := Tile.new(); t_cidade.construir("CastleWallEntry", 2)
	tab.posicionar(t_cidade, Posicao.new(-1, 1))

	_dump("inicial L-O", t_ini)
	_dump("vila", t_vila)
	_dump("curva", t_curva)
	_dump("cidade-fim", t_cidade)

	var jogA := Jogador.new("A", "red")
	var jogB := Jogador.new("B", "blue")

	var road_curva = _road(t_curva)
	var road_cidade = _road(t_cidade)
	print("road_curva dirs=", road_curva.direcoes, " | road_cidade dirs=", road_cidade.direcoes)
	jogA.colocarMeeple(road_curva)
	jogB.colocarMeeple(road_cidade)
	print("meeples: curva=", road_curva.meeples.size(), " cidade=", road_cidade.meeples.size())

	var road_vila = _road(t_vila)
	var grupo = tab.getGrupoConectado(road_vila)
	print("GRUPO estrada: tiles=", road_vila.tiles_do_grupo(grupo).size(), " features=", grupo.size())
	print("completa? ", road_vila.estaCompleta(grupo))
	print("donos majoritarios: ", road_vila.donos_majoritarios(grupo).size())

	var gm := GameManager.new()
	gm.tabuleiro = tab
	gm.ultimaPeca = t_vila
	var estado := ColocandoMeeple.new()
	estado._pontuar_tile(gm, t_vila)

	print("--- APOS PONTUAR ---")
	print("A: pontos=", jogA.pontos, " reserva=", jogA.meeplesDisponiveis, " (esperado 4 / 7)")
	print("B: pontos=", jogB.pontos, " reserva=", jogB.meeplesDisponiveis, " (esperado 4 / 7)")
	print("meeples restantes na estrada: curva=", road_curva.meeples.size(), " cidade=", road_cidade.meeples.size(), " (esperado 0 / 0)")
	gm.free()
	quit()

func _road(t):
	for f in t.features:
		if f.tipo == FeatureTile.Tipo.ESTRADA:
			return f
	return null

func _dump(nome, t) -> void:
	var b := []
	for d in Direcao.TODAS:
		b.append(["C", "R", "F", "M"][t.bordas[d]] if t.bordas[d] < 4 else "?")
	print(nome, " bordas[N,L,S,O]=", b)
