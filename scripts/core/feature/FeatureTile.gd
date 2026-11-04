class_name FeatureTile
extends RefCounted

enum Tipo { CAMPO, CIDADE, ESTRADA, MOSTEIRO }

var tipo: int = Tipo.CAMPO
var direcoes: Array[int] = []
# Metades de borda ocupadas por um campo: direcao * 2 + lado (0 = esquerda, 1 = direita, olhando para fora).
var aberturas: Array[int] = []
var celulas: Array[int] = []
var ancora_norm := Vector2(0.5, 0.5)
var hasEscudo: bool = false
var meeples: Array = []
var tile = null

func _init(_direcoes: Array[int] = [], _escudo: bool = false) -> void:
	direcoes = _direcoes.duplicate()
	hasEscudo = _escudo

func adicionaMeeple(m) -> void:
	meeples.append(m)
	if m != null:
		m.featureTile = self

func retornaMeepleJogador(m):
	return m.dono if m != null else null

func calcularPontos(_grupo: Array) -> int:
	push_error("FeatureTile.calcularPontos e abstrato")
	return 0

func estaCompleta(_grupo: Array) -> bool:
	push_error("FeatureTile.estaCompleta e abstrato")
	return false

func tiles_do_grupo(grupo: Array) -> Array:
	var ts := []
	for f in grupo:
		if f.tile != null and not ts.has(f.tile):
			ts.append(f.tile)
	return ts

func sem_arestas_abertas(grupo: Array) -> bool:
	for f in grupo:
		if f.tile == null:
			return false
		for d in f.direcoes:
			var alvo: Vector2i = f.tile.posicao.vetor() + Direcao.vetor(d)
			var oposto := Direcao.oposta(d)
			var achou := false
			for g in grupo:
				if g == f or g.tile == null:
					continue
				if g.tile.posicao.vetor() == alvo and g.direcoes.has(oposto):
					achou = true
					break
			if not achou:
				return false
	return true

func donos_majoritarios(grupo: Array) -> Array:
	var cont := {}
	for f in grupo:
		for m in f.meeples:
			cont[m.dono] = cont.get(m.dono, 0) + 1
	if cont.is_empty():
		return []
	var maxc: int = cont.values().max()
	var res := []
	for j in cont:
		if cont[j] == maxc:
			res.append(j)
	return res

func escudos_do_grupo(grupo: Array) -> int:
	var n := 0
	for f in grupo:
		if f.hasEscudo:
			n += 1
	return n
