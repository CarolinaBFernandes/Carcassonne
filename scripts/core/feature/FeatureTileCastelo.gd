class_name FeatureTileCastelo
extends FeatureTile

func _init(_direcoes: Array[int] = [], _escudo: bool = false) -> void:
	super(_direcoes, _escudo)
	tipo = Tipo.CIDADE

func estaCompleta(grupo: Array) -> bool:
	return sem_arestas_abertas(grupo)

func calcularPontos(grupo: Array) -> int:
	var tiles := tiles_do_grupo(grupo).size()
	var escudos := escudos_do_grupo(grupo)
	if estaCompleta(grupo):
		return tiles * 2 + escudos * 2
	return tiles * 1 + escudos * 1
