class_name Rodada
extends RefCounted

var numero: int = 1
var indiceAtivo: int = 0
var jogadores: Array = []
var turnos: Array = []

func _init(_jogadores: Array = [], _numero: int = 1) -> void:
	jogadores = _jogadores
	numero = _numero

func jogadorAtivo():
	if jogadores.is_empty():
		return null
	return jogadores[indiceAtivo]

func proximoTurno():
	if jogadores.is_empty():
		return null
	indiceAtivo = (indiceAtivo + 1) % jogadores.size()
	if indiceAtivo == 0:
		numero += 1
	return jogadorAtivo()

func adicionarTurno(t) -> void:
	turnos.append(t)

func estaCompleta() -> bool:
	return indiceAtivo == 0 and not turnos.is_empty()
