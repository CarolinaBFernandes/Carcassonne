# res://scripts/model/board.gd
class_name Board
extends RefCounted

## Uma colocação possível: célula + rotação.
class Placement:
	var cell: Vector2i
	var rotation: int

	func _init(p_cell: Vector2i, p_rotation: int) -> void:
		cell = p_cell
		rotation = p_rotation


## Vector2i -> PlacedTile
var tiles: Dictionary = {}

# Conjunto de células da fronteira: Vector2i -> true
var _frontier: Dictionary = {}

# Limites ocupados (para câmera/UI)
var _min: Vector2i = Vector2i.ZERO
var _max: Vector2i = Vector2i.ZERO


# ---------------------------------------------------------------- consultas básicas

func is_empty(cell: Vector2i) -> bool:
	return not tiles.has(cell)


func tile_count() -> int:
	return tiles.size()


func get_tile(cell: Vector2i) -> PlacedTile:
	return tiles.get(cell, null)


## Célula vizinha no lado indicado (0=N, 1=L, 2=S, 3=O).
func neighbor_cell(cell: Vector2i, side: int) -> Vector2i:
	return cell + Geometry.DIRS[side]


## Peça vizinha no lado indicado, ou null.
func get_neighbor(cell: Vector2i, side: int) -> PlacedTile:
	return tiles.get(neighbor_cell(cell, side), null)


## Quantidade de peças nas 8 células ao redor (usado pelos mosteiros).
func count_neighbors8(cell: Vector2i) -> int:
	var n := 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if tiles.has(cell + Vector2i(dx, dy)):
				n += 1
	return n


func get_frontier() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in _frontier:
		out.append(c)
	return out


## Retângulo (em células) que contém todas as peças. Vazio se o tabuleiro está vazio.
func get_bounds() -> Rect2i:
	if tiles.is_empty():
		return Rect2i()
	return Rect2i(_min, _max - _min + Vector2i.ONE)


# ---------------------------------------------------------------- validação

## Regras de colocação:
##  1. A célula precisa estar vazia.
##  2. Precisa encostar em pelo menos uma peça (exceto a peça inicial, em (0,0)).
##  3. Cada lado em contato precisa ter o mesmo tipo (cidade/estrada/campo) do lado oposto do vizinho.
func can_place(def: TileDef, cell: Vector2i, rot: int) -> bool:
	if tiles.has(cell):
		return false

	# Tabuleiro vazio: só a peça inicial, na origem.
	if tiles.is_empty():
		return cell == Vector2i.ZERO

	var has_neighbor := false
	for side in 4:
		var neighbor: PlacedTile = tiles.get(cell + Geometry.DIRS[side], null)
		if neighbor == null:
			continue
		has_neighbor = true
		var mine := def.side_type(side, rot)
		var theirs := neighbor.side_type(Geometry.opposite_side(side))
		if mine != theirs:
			return false
	return has_neighbor


## Todas as rotações (0..3) válidas para a célula. Útil para o fantasma e para dicas.
func get_valid_rotations(def: TileDef, cell: Vector2i) -> Array[int]:
	var out: Array[int] = []
	for rot in 4:
		if can_place(def, cell, rot):
			out.append(rot)
	return out


## Todas as colocações válidas (célula × rotação) para a peça.
## Peças simétricas geram rotações equivalentes repetidas; isso é proposital e inofensivo.
func get_valid_placements(def: TileDef) -> Array[Placement]:
	var out: Array[Placement] = []
	if tiles.is_empty():
		for rot in 4:
			out.append(Placement.new(Vector2i.ZERO, rot))
		return out
	for cell in _frontier:
		for rot in 4:
			if can_place(def, cell, rot):
				out.append(Placement.new(cell, rot))
	return out


## Versão rápida: para assim que achar a primeira colocação válida.
## Use para detectar "peça sem lugar" (descartar e comprar outra).
func has_any_valid_placement(def: TileDef) -> bool:
	if tiles.is_empty():
		return true
	for cell in _frontier:
		for rot in 4:
			if can_place(def, cell, rot):
				return true
	return false


# ---------------------------------------------------------------- escrita

## Coloca a peça e atualiza a fronteira e os limites.
## Retorna o PlacedTile criado, ou null se a colocação for inválida.
## NÃO atualiza o RegionGraph (isso é feito pelo GameState, Fase 9, chamando a Fase 6).
func place(def: TileDef, cell: Vector2i, rot: int) -> PlacedTile:
	if not can_place(def, cell, rot):
		push_error("Board.place: colocação inválida (%s, %s, rot %d)" % [def.id, cell, rot])
		return null

	var placed := PlacedTile.new(def, cell, rot)

	if tiles.is_empty():
		_min = cell
		_max = cell
	else:
		_min = Vector2i(mini(_min.x, cell.x), mini(_min.y, cell.y))
		_max = Vector2i(maxi(_max.x, cell.x), maxi(_max.y, cell.y))

	tiles[cell] = placed
	_frontier.erase(cell)
	for d in Geometry.DIRS:
		var n: Vector2i = cell + d
		if not tiles.has(n):
			_frontier[n] = true

	return placed
