class_name FimDeJogo
extends EstadoJogo

func nome() -> String:
	return "FimDeJogo"

func entrada(ctx) -> void:
	ctx.calcularPontosJogadores()
	ctx.emit_signal("pontuacao_mudou")
	ctx.emit_signal("jogo_acabou", ctx.ranking())
