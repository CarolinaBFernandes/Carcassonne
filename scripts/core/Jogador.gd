class_name Jogador
extends RefCounted

var nome: String = ""
var cor: Color = Color.WHITE
var corArquivo: String = "blue"
var ehIA: bool = false
var meeplesDisponiveis: int = 7
var pontos: int = 0

func _init(_nome: String = "", _corArquivo: String = "blue", _cor: Color = Color.WHITE) -> void:
	nome = _nome
	corArquivo = _corArquivo
	cor = _cor

func colocarMeeple(ft) -> Meeple:
	if meeplesDisponiveis <= 0 or ft == null:
		return null
	var m := Meeple.new()
	m.configurar(self, ft.tipo)
	meeplesDisponiveis -= 1
	ft.adicionaMeeple(m)
	if ft.tile != null:
		ft.tile.add_child(m)
	m.posicionar(ft)
	return m

func creditarPontos(p: int) -> void:
	pontos += p

func devolverMeeple() -> void:
	meeplesDisponiveis += 1
