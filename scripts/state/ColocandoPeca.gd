class_name ColocandoPeca
extends EstadoJogo

func nome() -> String:
	return "ColocandoPeca"

func colocarPeca(tile, posicao) -> bool:
	if not contexto.tabuleiro.podeColocar(tile, posicao):
		return false
	contexto.tabuleiro.posicionar(tile, posicao)
	tile.setPosicionadoPor(contexto.jogadorAtivo())
	contexto.ultimaPeca = tile
	contexto.tileAtual = null
	contexto.emit_signal("tabuleiro_mudou")
	contexto.mudarEstado(ColocandoMeeple.new())
	return true
