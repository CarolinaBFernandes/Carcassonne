class_name FimDeJogo
extends EstadoJogo

func nome() -> String:
	return "FimDeJogo"

func entrada() -> void:
	contexto.calcularPontosJogadores()
	contexto.emit_signal("pontuacao_mudou")
	contexto.emit_signal("jogo_acabou", contexto.ranking())
