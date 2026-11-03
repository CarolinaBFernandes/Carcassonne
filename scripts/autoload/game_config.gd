# res://scripts/autoload/game_config.gd
extends Node

## true depois que o menu chamou configure(). Em F6 direto na cena do jogo é false.
var configured := false
var player_count := 2
var player_names: Array[String] = []
var player_colors: Array[Color] = []
var seed_value := 0
var first_player := 0


## p_seed = 0 gera uma seed aleatória. O primeiro jogador sorteado deriva da seed,
## então a partida inteira continua reproduzível.
func configure(count: int, names: Array[String], colors: Array[Color],
		p_seed: int, randomize_first: bool) -> void:
	player_count = clampi(count, PlayerData.MIN_PLAYERS, PlayerData.MAX_PLAYERS)
	player_names = names.duplicate()
	player_colors = colors.duplicate()
	seed_value = p_seed if p_seed != 0 else maxi(1, Deck.random_seed())
	_randomize_first = randomize_first
	first_player = _pick_first()
	configured = true


## Nova seed, mesmos jogadores ("Jogar de novo").
func reroll_seed() -> void:
	seed_value = maxi(1, Deck.random_seed())
	first_player = _pick_first()


var _randomize_first := false


func _pick_first() -> int:
	if not _randomize_first:
		return 0
	return absi(seed_value) % player_count
