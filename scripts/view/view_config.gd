# res://scripts/view/view_config.gd
class_name ViewConfig
extends RefCounted

## Lado da peça em pixels de mundo. ÚNICA definição no projeto.
const TILE_SIZE := 256
const HALF := TILE_SIZE / 2.0

const COLOR_VALID := Color(0.5, 1.0, 0.5, 0.65)     # fantasma: posição válida
const COLOR_INVALID := Color(1.0, 0.4, 0.4, 0.65)   # fantasma: posição inválida


## Centro da peça na célula.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE


## Célula que contém o ponto do mundo. Cada célula cobre [-HALF, +HALF) ao redor do centro.
static func world_to_cell(pos: Vector2) -> Vector2i:
	var shifted := (pos + Vector2(HALF, HALF)) / TILE_SIZE
	return Vector2i(shifted.floor())


## Retângulo do mundo ocupado por um retângulo de células (para limitar a câmera).
static func cells_to_world_rect(cells: Rect2i) -> Rect2:
	var pos := Vector2(cells.position) * TILE_SIZE - Vector2(HALF, HALF)
	return Rect2(pos, Vector2(cells.size) * TILE_SIZE)


## Ponto médio do lado (0=N, 1=L, 2=S, 3=O), em coordenadas locais da peça.
static func side_position(side: int) -> Vector2:
	return Vector2(Geometry.DIRS[side]) * HALF


## Posição da meia-borda (porta 0..7, convenção da Fase 3), em coordenadas locais.
static func port_position(port: int) -> Vector2:
	var q := TILE_SIZE / 4.0
	match port:
		0: return Vector2(-q, -HALF)   # Norte-esquerda
		1: return Vector2(q, -HALF)    # Norte-direita
		2: return Vector2(HALF, -q)    # Leste-cima
		3: return Vector2(HALF, q)     # Leste-baixo
		4: return Vector2(q, HALF)     # Sul-direita
		5: return Vector2(-q, HALF)    # Sul-esquerda
		6: return Vector2(-HALF, q)    # Oeste-baixo
		_: return Vector2(-HALF, -q)   # Oeste-cima (7)
