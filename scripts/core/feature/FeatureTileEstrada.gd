class_name FeatureTileEstrada
extends FeatureTile

func _init(_direcoes: Array[int] = [], _escudo: bool = false) -> void:
	super(_direcoes, _escudo)
	tipo = Tipo.ESTRADA

func estaCompleta(grupo: Array) -> bool:
	return sem_arestas_abertas(grupo)

func calcularPontos(grupo: Array) -> int:
	return tiles_do_grupo(grupo).size()
