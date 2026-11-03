class_name Ocioso
extends EstadoJogo

func nome() -> String:
	return "Ocioso"

func novaRodada(_n) -> void:
	contexto.iniciar_vez()
