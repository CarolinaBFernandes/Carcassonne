# res://scripts/model/deck.gd
class_name Deck
extends RefCounted

var _cards: Array[TileDef] = []     # ordem final (já embaralhada)
var _next: int = 0                  # índice da próxima carta a comprar
var _discarded: Array[TileDef] = [] # peças sem lugar válido, em ordem de descarte
var _seed: int = 0


## Cria o baralho a partir do catálogo e embaralha com a seed.
## Para uma partida nova com seed aleatória: Deck.new(Deck.random_seed()).
func _init(p_seed: int, cards: Array[TileDef] = []) -> void:
	_seed = p_seed
	if cards.is_empty():
		_cards = TileCatalog.build_deck_list()
	else:
		_cards = cards.duplicate()
	_shuffle()


## Gera uma seed aleatória (guarde o valor para reproduzir a partida).
static func random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return int(rng.randi())


func get_seed() -> int:
	return _seed


# ------------------------------------------------------------ embaralhar

## Fisher-Yates com gerador dedicado. Mesma seed => mesma ordem.
func _shuffle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in range(_cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := _cards[i]
		_cards[i] = _cards[j]
		_cards[j] = tmp
	_next = 0


# ------------------------------------------------------------ compra

## Próxima peça, ou null se o baralho acabou.
func draw() -> TileDef:
	if _next >= _cards.size():
		return null
	var card := _cards[_next]
	_next += 1
	return card


## Peça do topo, sem comprar.
func peek() -> TileDef:
	if _next >= _cards.size():
		return null
	return _cards[_next]


## Peças ainda não compradas.
func remaining() -> int:
	return _cards.size() - _next


func is_empty() -> bool:
	return _next >= _cards.size()


## Total de peças do baralho (71 numa partida padrão).
func total() -> int:
	return _cards.size()


# ------------------------------------------------------------ descarte

## Registra uma peça descartada por não ter lugar válido.
## O baralho não compra outra sozinho: o GameState chama draw() em seguida.
func discard(tile: TileDef) -> void:
	_discarded.append(tile)


func discarded() -> Array[TileDef]:
	return _discarded.duplicate()


## Compra a próxima peça que tenha pelo menos uma colocação válida no tabuleiro,
## descartando as que não têm. Retorna null se o baralho acabar.
## Regra oficial: peça impossível de jogar é descartada e o jogador compra outra.
func draw_playable(board: Board) -> TileDef:
	while true:
		var t := draw()
		if t == null:
			return null
		if board.has_any_valid_placement(t):
			return t
		discard(t)
	return null


# ------------------------------------------------------------ depuração e salvamento

## Ordem completa (embaralhada), inclusive as já compradas.
func order_ids() -> Array[String]:
	var out: Array[String] = []
	for c in _cards:
		out.append(c.id)
	return out


## Contagem por id das peças ainda no baralho (não compradas).
func remaining_counts() -> Dictionary:
	var counts := {}
	for i in range(_next, _cards.size()):
		var id := _cards[i].id
		counts[id] = int(counts.get(id, 0)) + 1
	return counts


func debug_print() -> void:
	print("Baralho: seed=%d total=%d restantes=%d descartadas=%d" % [
		_seed, total(), remaining(), _discarded.size()])
	var counts := remaining_counts()
	var ids := counts.keys()
	ids.sort()
	for id in ids:
		print("  %s x%d" % [id, counts[id]])
