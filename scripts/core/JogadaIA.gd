class_name JogadaIA
extends RefCounted

var tile = null
var posicao: Posicao = null
var rotacao: int = 0
var meepleEm = null
var valor: float = 0.0

func _init(_posicao: Posicao = null, _rotacao: int = 0, _valor: float = 0.0) -> void:
	posicao = _posicao
	rotacao = _rotacao
	valor = _valor

func compareTo(outra: JogadaIA) -> int:
	if valor > outra.valor:
		return 1
	elif valor < outra.valor:
		return -1
	return 0
