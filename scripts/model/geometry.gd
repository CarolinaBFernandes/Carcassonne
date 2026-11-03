class_name Geometry

# Lados: 0=Norte, 1=Leste, 2=Sul, 3=Oeste
const DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]

# Portas (meias-bordas): 0=N-esq, 1=N-dir, 2=L-cima, 3=L-baixo,
# 4=S-dir, 5=S-esq, 6=O-baixo, 7=O-cima

# Porta da nova peça -> porta do vizinho que a toca, por lado
const PORT_MATCH: Array = [
	{0: 5, 1: 4},  # vizinho ao norte
	{2: 7, 3: 6},  # vizinho a leste
	{4: 1, 5: 0},  # vizinho ao sul
	{6: 3, 7: 2},  # vizinho a oeste
]

static func opposite_side(s: int) -> int:
	return (s + 2) % 4

static func rotate_side(s: int, r: int) -> int:
	return (s + r) % 4

static func rotate_port(p: int, r: int) -> int:
	return (p + 2 * r) % 8

static func side_of_port(p: int) -> int:
	return p / 2
