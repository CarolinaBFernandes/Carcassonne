class_name Turno
extends RefCounted

var ordem: int = 0
var pontosMarcados: int = 0
var jogador = null
var tileJogado = null

func _init(_jogador = null, _ordem: int = 0) -> void:
	jogador = _jogador
	ordem = _ordem
