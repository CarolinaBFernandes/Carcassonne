# res://scripts/model/player_data.gd
class_name PlayerData
extends RefCounted

const MAX_MEEPLES := 7
const MIN_PLAYERS := 2
const MAX_PLAYERS := 5

## Cores padrão do jogo base.
const DEFAULT_COLORS: Array[Color] = [
	Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color.BLACK,
]

## Categorias de pontuação (usadas na tela de fim de jogo).
enum Category { ROAD, CITY, MONASTERY, FARM }

var id: int
var display_name: String
var color: Color
var meeples_available: int = MAX_MEEPLES
var score: int = 0
var score_by_category: Dictionary = {}   # Category -> int


func _init(p_id: int, p_name: String, p_color: Color) -> void:
	id = p_id
	display_name = p_name
	color = p_color
	for c in Category.values():
		score_by_category[c] = 0


func add_score(points: int, category: Category) -> void:
	score += points
	score_by_category[category] = int(score_by_category[category]) + points


## Cria 2 a 5 jogadores com ids 0..n-1. Nomes e cores omitidos usam valores padrão.
static func create_players(count: int, names: Array[String] = [],
		colors: Array[Color] = []) -> Array[PlayerData]:
	if count < MIN_PLAYERS or count > MAX_PLAYERS:
		push_error("PlayerData.create_players: %d jogadores (permitido %d a %d)" % [
			count, MIN_PLAYERS, MAX_PLAYERS])
		count = clampi(count, MIN_PLAYERS, MAX_PLAYERS)

	var out: Array[PlayerData] = []
	for i in count:
		var pname := names[i] if i < names.size() else "Jogador %d" % (i + 1)
		var pcolor := colors[i] if i < colors.size() else DEFAULT_COLORS[i]
		out.append(PlayerData.new(i, pname, pcolor))
	return out
