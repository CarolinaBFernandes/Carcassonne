class_name Posicao
extends RefCounted

var x: int
var y: int

func _init(_x: int = 0, _y: int = 0) -> void:
	x = _x
	y = _y

func vetor() -> Vector2i:
	return Vector2i(x, y)

func chave() -> String:
	return "%d,%d" % [x, y]

func igual(o: Posicao) -> bool:
	return o != null and o.x == x and o.y == y

func somar_direcao(d: int) -> Posicao:
	var v := Direcao.vetor(d)
	return Posicao.new(x + v.x, y + v.y)

static func de_vetor(v: Vector2i) -> Posicao:
	return Posicao.new(v.x, v.y)
