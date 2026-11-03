class_name FeatureTileCampo
extends FeatureTile

func _init(_direcoes: Array[int] = [], _escudo: bool = false) -> void:
	super(_direcoes, _escudo)
	tipo = Tipo.CAMPO

func estaCompleta(_grupo: Array) -> bool:
	return false

func calcularPontos(grupo: Array) -> int:
	if tile == null or tile.tabuleiro == null:
		return 0
	var tab = tile.tabuleiro
	var cidades_feats := []
	for f in grupo:
		if f.tile == null:
			continue
		for feat in f.tile.features:
			if feat.tipo == Tipo.CIDADE and not cidades_feats.has(feat):
				cidades_feats.append(feat)
	var grupos_vistos := []
	var completas := 0
	for cf in cidades_feats:
		var ja := false
		for grp in grupos_vistos:
			if grp.has(cf):
				ja = true
				break
		if ja:
			continue
		var grupo_cidade: Array = tab.getGrupoConectado(cf)
		grupos_vistos.append(grupo_cidade)
		if cf.estaCompleta(grupo_cidade):
			completas += 1
	return 3 * completas
