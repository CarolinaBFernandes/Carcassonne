class_name EstadoJogo
extends RefCounted

var contexto = null

func nome() -> String:
	return "EstadoJogo"

func entrada() -> void:
	pass

func saida() -> void:
	pass

func colocarPeca(_tile, _posicao) -> bool:
	return false

func colocarMeeple(_ft) -> bool:
	return false

func pular() -> void:
	pass

func novaRodada(_n) -> void:
	pass
