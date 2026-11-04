class_name Tile
extends Node2D

const TAM := 128.0

var tipoBase: String = ""
var rotacao: int = 0
var posicao: Posicao = null
var posicionadoPor = null
var tabuleiro = null
var features: Array = []
var bordas: Array[int] = [FeatureTile.Tipo.CAMPO, FeatureTile.Tipo.CAMPO,
	FeatureTile.Tipo.CAMPO, FeatureTile.Tipo.CAMPO]

var _sprite: Sprite2D

const _ADJ := {
	0: [4, 7, 8], 1: [4, 5, 8], 2: [5, 6, 8], 3: [6, 7, 8],
	4: [0, 1], 5: [1, 2], 6: [2, 3], 7: [3, 0], 8: [0, 1, 2, 3],
}

const _PONTOS := {
	0: Vector2(0.5, 0.18), 1: Vector2(0.82, 0.5), 2: Vector2(0.5, 0.82), 3: Vector2(0.18, 0.5),
	4: Vector2(0.76, 0.24), 5: Vector2(0.76, 0.76), 6: Vector2(0.24, 0.76), 7: Vector2(0.24, 0.24),
	8: Vector2(0.5, 0.5),
}

const _ROT_CEL := {
	0: 1, 1: 2, 2: 3, 3: 0,
	4: 5, 5: 6, 6: 7, 7: 4,
	8: 8,
}

# Esquerda e direita de cada borda, olhando para fora da peca.
# Celulas: 7 0 4 / 3 8 1 / 6 2 5.
const _METADE := {
	0: [7, 4],
	1: [4, 5],
	2: [5, 6],
	3: [6, 7],
}

func construir(tipo_base: String, rot: int = 0) -> void:
	tipoBase = tipo_base
	features.clear()
	var info = TilesDef.DADOS.get(tipo_base, null)
	if info != null:
		var terr: Array[int] = []
		for c in info["t"]:
			terr.append(_cod_tipo(c))
		var pai: Array[int] = []
		for i in range(9):
			pai.append(i)
		for i in range(9):
			if terr[i] < 0:
				continue
			for j in _ADJ[i]:
				if terr[j] == terr[i]:
					_uf_unir(pai, i, j)
		_unir_campos_na_frente_da_cidade(pai, terr)
		var grupos := {}
		for i in range(9):
			if terr[i] < 0:
				continue
			var r := _uf_raiz(pai, i)
			if not grupos.has(r):
				grupos[r] = []
			grupos[r].append(i)
		var escudos: Array = TilesDef.ESCUDOS.get(tipo_base, [])
		for r in grupos:
			var membros: Array = grupos[r]
			var tp: int = terr[r]
			var bordas_seg: Array[int] = []
			var tem_escudo := false
			for p in membros:
				if p < 4:
					bordas_seg.append(p)
					if escudos.has(p):
						tem_escudo = true
			var f = null
			match tp:
				FeatureTile.Tipo.CIDADE:
					f = FeatureTileCastelo.new(bordas_seg, tem_escudo)
				FeatureTile.Tipo.ESTRADA:
					f = FeatureTileEstrada.new(bordas_seg)
				FeatureTile.Tipo.CAMPO:
					f = FeatureTileCampo.new(bordas_seg)
				FeatureTile.Tipo.MOSTEIRO:
					f = FeatureTileIgreja.new()
			if f != null:
				f.tile = self
				if tp == FeatureTile.Tipo.CAMPO:
					f.aberturas = _aberturas_campo(membros, terr)
					var centro := Vector2(0.5, 0.5)
					var melhor: Vector2 = _PONTOS[membros[0]]
					var maxd := (melhor - centro).length()
					for p in membros:
						var pt: Vector2 = _PONTOS[p]
						var dd := (pt - centro).length()
						if dd > maxd:
							maxd = dd
							melhor = pt
					f.ancora_norm = melhor
				else:
					var soma := Vector2.ZERO
					for p in membros:
						soma += _PONTOS[p]
					f.ancora_norm = soma / float(membros.size())
				var cels: Array[int] = []
				for c in membros:
					cels.append(int(c))
				f.celulas = cels
				features.append(f)
	_recalcular_bordas()
	rotacao = 0
	for _i in range(rot % 4):
		rotacionar()
	_montar_visual()

func _cod_tipo(c: String) -> int:
	match c:
		"C": return FeatureTile.Tipo.CIDADE
		"R": return FeatureTile.Tipo.ESTRADA
		"F": return FeatureTile.Tipo.CAMPO
		"M": return FeatureTile.Tipo.MOSTEIRO
		_: return -1

func _uf_raiz(pai: Array[int], i: int) -> int:
	while pai[i] != i:
		pai[i] = pai[pai[i]]
		i = pai[i]
	return i

func _uf_unir(pai: Array[int], a: int, b: int) -> void:
	var ra := _uf_raiz(pai, a)
	var rb := _uf_raiz(pai, b)
	if ra != rb:
		pai[rb] = ra

# Cidade ou estrada de ponta a ponta ja separa os campos: o union-find so
# une celulas do mesmo tipo, e muralha/estrada nao sao campo. A excecao e a
# faixa de grama na frente de uma cidade que nao atravessa a peca (o grid
# nao tem celula entre a muralha e o miolo). Essa faixa e um campo so,
# exceto quando a estrada termina no portao e corta os dois lados.
func _unir_campos_na_frente_da_cidade(pai: Array[int], terr: Array[int]) -> void:
	if _estrada_termina_na_cidade(terr):
		return
	for d in Direcao.TODAS:
		if terr[d] != FeatureTile.Tipo.CIDADE or terr[8] == FeatureTile.Tipo.CIDADE:
			continue
		var esq: int = int(_METADE[d][0])
		var dire: int = int(_METADE[d][1])
		if terr[esq] != FeatureTile.Tipo.CAMPO or terr[dire] != FeatureTile.Tipo.CAMPO:
			continue
		_uf_unir(pai, esq, dire)

func _estrada_termina_na_cidade(terr: Array[int]) -> bool:
	if terr[8] != FeatureTile.Tipo.ESTRADA:
		return false
	var saidas := 0
	for d in Direcao.TODAS:
		if terr[d] == FeatureTile.Tipo.ESTRADA:
			saidas += 1
	return saidas == 1

# Campo nao atravessa borda de cidade. Em borda de estrada, cada metade
# (esquerda/direita, olhando para fora) pertence ao campo daquele canto.
func _aberturas_campo(membros: Array, terr: Array[int]) -> Array[int]:
	var abs: Array[int] = []
	for d in Direcao.TODAS:
		var borda: int = terr[d]
		if borda == FeatureTile.Tipo.CIDADE:
			continue
		var met: Array = _METADE[d]
		var esq: int = int(met[0])
		var dire: int = int(met[1])
		if borda == FeatureTile.Tipo.ESTRADA:
			if membros.has(esq):
				abs.append(d * 2)
			if membros.has(dire):
				abs.append(d * 2 + 1)
		elif membros.has(d) or membros.has(esq) or membros.has(dire):
			abs.append(d * 2)
			abs.append(d * 2 + 1)
	return abs

func _recalcular_bordas() -> void:
	bordas = [FeatureTile.Tipo.CAMPO, FeatureTile.Tipo.CAMPO,
		FeatureTile.Tipo.CAMPO, FeatureTile.Tipo.CAMPO]
	for f in features:
		if f.tipo == FeatureTile.Tipo.MOSTEIRO:
			continue
		for d in f.direcoes:
			bordas[d] = f.tipo

func rotacionar() -> void:
	rotacao = (rotacao + 1) % 4
	for f in features:
		var novas: Array[int] = []
		for d in f.direcoes:
			novas.append(Direcao.rotacionar(d, 1))
		f.direcoes = novas
		var novas_ab: Array[int] = []
		for ab in f.aberturas:
			var dir := int(ab / 2)
			var lado := int(ab) % 2
			novas_ab.append(Direcao.rotacionar(dir, 1) * 2 + lado)
		f.aberturas = novas_ab
		var novas_cel: Array[int] = []
		for c in f.celulas:
			novas_cel.append(int(_ROT_CEL[int(c)]))
		f.celulas = novas_cel
		var dlt: Vector2 = f.ancora_norm - Vector2(0.5, 0.5)
		f.ancora_norm = Vector2(0.5, 0.5) + Vector2(-dlt.y, dlt.x)
	_recalcular_bordas()
	if _sprite != null:
		_sprite.rotation_degrees = rotacao * 90

func setPosicao(p: Posicao) -> void:
	posicao = p

func setPosicionadoPor(j) -> void:
	posicionadoPor = j

func bordaTipo(d: int) -> int:
	return bordas[d]

func feature_em(d: int):
	for f in features:
		if f.tipo != FeatureTile.Tipo.MOSTEIRO and f.direcoes.has(d):
			return f
	return null

func mosteiro():
	for f in features:
		if f.tipo == FeatureTile.Tipo.MOSTEIRO:
			return f
	return null

func _montar_visual() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	var caminho := "res://assets/tiles/%s0.png" % tipoBase
	if ResourceLoader.exists(caminho):
		var tex: Texture2D = load(caminho)
		_sprite.texture = tex
		_sprite.centered = true
		_sprite.position = Vector2(TAM * 0.5, TAM * 0.5)
		_sprite.scale = Vector2.ONE * (TAM / float(tex.get_width()))
		_sprite.rotation_degrees = rotacao * 90
	add_child(_sprite)
	if tem_escudo():
		var borda := Line2D.new()
		borda.points = PackedVector2Array([
			Vector2(3, 3), Vector2(TAM - 3, 3), Vector2(TAM - 3, TAM - 3),
			Vector2(3, TAM - 3), Vector2(3, 3)])
		borda.width = 5.0
		borda.default_color = Color(1.0, 0.84, 0.0)
		borda.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(borda)

func tem_escudo() -> bool:
	for f in features:
		if f.hasEscudo:
			return true
	return false
