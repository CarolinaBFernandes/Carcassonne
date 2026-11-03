class_name Direcao
extends RefCounted
enum { NORTE, LESTE, SUL, OESTE }

const TODAS: Array[int] = [NORTE, LESTE, SUL, OESTE]

const VETORES := {
	NORTE: Vector2i(0, -1),
	LESTE: Vector2i(1, 0),
	SUL: Vector2i(0, 1),
	OESTE: Vector2i(-1, 0),
}

static func oposta(d: int) -> int:
	return (d + 2) % 4

static func rotacionar(d: int, passos: int) -> int:
	return (d + passos) % 4

static func vetor(d: int) -> Vector2i:
	return VETORES[d]

static func nome(d: int) -> String:
	return ["NORTE", "LESTE", "SUL", "OESTE"][d]
