class_name FeatureTileIgreja
extends FeatureTile

func _init(_direcoes: Array[int] = [], _escudo: bool = false) -> void:
	super(_direcoes, _escudo)
	tipo = Tipo.MOSTEIRO

func _adjacentes() -> int:
	if tile == null or tile.tabuleiro == null:
		return 0
	return tile.tabuleiro.getAoRedor(tile).size()

func estaCompleta(_grupo: Array) -> bool:
	return _adjacentes() == 8

func calcularPontos(_grupo: Array) -> int:
	if estaCompleta(_grupo):
		return 9
	return 1 + _adjacentes()
