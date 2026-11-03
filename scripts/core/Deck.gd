class_name Deck
extends RefCounted

var _pool: Array[String] = []

func _init(incluir_inicial: bool = false, semente: int = 0) -> void:
	for tipo in TilesDef.DADOS:
		var q: int = TilesDef.DADOS[tipo].get("amount", 0)
		if tipo == TilesDef.TILE_INICIAL and not incluir_inicial:
			q -= 1
		for _i in range(q):
			_pool.append(tipo)
	if semente != 0:
		seed(semente)
	_pool.shuffle()

func pool_tipos() -> Array:
	return _pool.duplicate()

func carregar_pool(arr: Array) -> void:
	_pool = []
	for t in arr:
		_pool.append(str(t))

func vazio() -> bool:
	return _pool.is_empty()

func restantes() -> int:
	return _pool.size()

func sortearTile():
	if _pool.is_empty():
		return null
	return criar_tile(_pool.pop_back(), 0)

func criar_tile(tipo: String, rot: int = 0):
	var t = Tile.new()
	t.construir(tipo, rot)
	return t
