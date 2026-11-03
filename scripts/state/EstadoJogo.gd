class_name EstadoJogo
extends RefCounted

func nome() -> String:
	return "EstadoJogo"

func entrada(_ctx) -> void:
	pass

func saida(_ctx) -> void:
	pass

func colocarPeca(_ctx, _tile, _posicao) -> bool:
	return false

func colocarMeeple(_ctx, _ft) -> bool:
	return false

func pular(_ctx) -> void:
	pass

func novaRodada(_ctx, _n) -> void:
	pass
