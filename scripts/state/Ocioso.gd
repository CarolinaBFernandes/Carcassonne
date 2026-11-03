class_name Ocioso
extends EstadoJogo

func nome() -> String:
	return "Ocioso"

func novaRodada(ctx, n) -> void:
	ctx.iniciar_vez()
