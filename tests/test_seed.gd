extends SceneTree

func _initialize() -> void:
	var a = Deck.new(false, 12345)
	var b = Deck.new(false, 12345)
	var c = Deck.new(false, 99999)
	var pa = a.pool_tipos()
	var pb = b.pool_tipos()
	var pc = c.pool_tipos()
	print("mesma seed iguais: ", pa == pb)
	print("seed diferente diferentes: ", pa != pc)
	print("tamanho pool: ", pa.size())
	quit()
