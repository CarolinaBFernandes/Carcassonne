class_name ColocandoPeca
extends EstadoJogo

func nome() -> String:
	return "ColocandoPeca"

func colocarPeca(ctx, tile, posicao) -> bool:
	if not ctx.tabuleiro.podeColocar(tile, posicao):
		return false
	ctx.tabuleiro.posicionar(tile, posicao)
	tile.setPosicionadoPor(ctx.jogadorAtivo())
	ctx.ultimaPeca = tile
	ctx.last_placed_pos = posicao
	ctx.tileAtual = null
	ctx.emit_signal("tabuleiro_mudou")
	ctx.mudarEstado(ColocandoMeeple.new())
	return true
