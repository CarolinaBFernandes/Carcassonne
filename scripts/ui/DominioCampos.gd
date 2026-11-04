class_name DominioCampos
extends Node2D

const TAM := 128.0
const RES := 126

# Celulas: 7 0 4 / 3 8 1 / 6 2 5.

var ativo := false
var _sprites: Array = []

func limpar() -> void:
	for s in _sprites:
		if is_instance_valid(s):
			s.queue_free()
	_sprites.clear()

func atualizar(tab) -> void:
	limpar()
	if not ativo or tab == null:
		return
	var dono_de := {}
	for item in tab.dominios_campo():
		for f in item["features"]:
			dono_de[f.get_instance_id()] = item["donos"]
	var vistos := {}
	for t in tab.tiles():
		var tid: int = t.get_instance_id()
		if vistos.has(tid):
			continue
		vistos[tid] = true
		var tex := _textura_do_tile(t, dono_de)
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = t.position
		s.scale = Vector2(TAM / float(RES), TAM / float(RES))
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(s)
		_sprites.append(s)

func _textura_do_tile(tile, dono_de: Dictionary) -> Texture2D:
	var img := _carregar_arte(tile)
	if img == null:
		return null
	var dados: PackedByteArray = img.get_data()
	if dados.size() < RES * RES * 4:
		return null
	var grama := PackedByteArray()
	grama.resize(RES * RES)
	for i in RES * RES:
		var o: int = i * 4
		if _grama(dados[o], dados[o + 1], dados[o + 2], dados[o + 3]):
			grama[i] = 1
	var rotulo := PackedInt32Array()
	rotulo.resize(RES * RES)
	var donos_idx: Array = [null]
	var seeds: Array[int] = []
	var algum := false
	var proximo := 1
	for f in tile.features:
		if f.tipo != FeatureTile.Tipo.CAMPO:
			continue
		var id: int = f.get_instance_id()
		var donos = dono_de.get(id, null)
		if donos != null:
			algum = true
		donos_idx.append(donos)
		var idx_campo := proximo
		proximo += 1
		for cel in f.celulas:
			_semear_celula(grama, rotulo, seeds, int(cel), idx_campo)
	if not algum or seeds.is_empty():
		return null
	_inundar(grama, rotulo, seeds)
	var out := PackedByteArray()
	out.resize(RES * RES * 4)
	var pintou := false
	for i in RES * RES:
		var campo: int = rotulo[i]
		if campo <= 0 or campo >= donos_idx.size():
			continue
		var donos_px = donos_idx[campo]
		if donos_px == null:
			continue
		var x: int = i % RES
		var y: int = int(i / RES)
		var cor: Color = _cor_hachura(donos_px, x, y)
		if cor.a <= 0.01:
			continue
		var o2: int = i * 4
		out[o2] = int(cor.r * 255.0)
		out[o2 + 1] = int(cor.g * 255.0)
		out[o2 + 2] = int(cor.b * 255.0)
		out[o2 + 3] = int(cor.a * 255.0)
		pintou = true
	if not pintou:
		return null
	var saida := Image.create_from_data(RES, RES, false, Image.FORMAT_RGBA8, out)
	return ImageTexture.create_from_image(saida)

func _carregar_arte(tile) -> Image:
	var caminho := "res://assets/tiles/%s0.png" % tile.tipoBase
	var img: Image = null
	if ResourceLoader.exists(caminho):
		var tex := load(caminho) as Texture2D
		if tex != null:
			img = tex.get_image()
	if img == null or img.get_width() <= 0:
		img = Image.new()
		if img.load(caminho) != OK:
			return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for _giro in range(int(tile.rotacao) % 4):
		img.rotate_90(ClockDirection.CLOCKWISE)
	if img.get_width() != RES or img.get_height() != RES:
		img.resize(RES, RES, Image.INTERPOLATE_NEAREST)
	return img

func _grama(r: int, g: int, b: int, a: int) -> bool:
	return a > 110 and g > 60 and g > r + 8 and g > b + 6

func _grade_da_celula(cel: int) -> Vector2i:
	match cel:
		7: return Vector2i(0, 0)
		0: return Vector2i(1, 0)
		4: return Vector2i(2, 0)
		3: return Vector2i(0, 1)
		8: return Vector2i(1, 1)
		1: return Vector2i(2, 1)
		6: return Vector2i(0, 2)
		2: return Vector2i(1, 2)
		5: return Vector2i(2, 2)
		_: return Vector2i(-1, -1)

func _semear_celula(grama: PackedByteArray, rotulo: PackedInt32Array, fila: Array[int], cel: int, campo: int) -> void:
	var grade: Vector2i = _grade_da_celula(cel)
	if grade.x < 0:
		return
	var x0: int = grade.x * RES / 3
	var y0: int = grade.y * RES / 3
	var x1: int = (grade.x + 1) * RES / 3
	var y1: int = (grade.y + 1) * RES / 3
	for y in range(y0, y1):
		for x in range(x0, x1):
			var i: int = y * RES + x
			if grama[i] == 0 or rotulo[i] != 0:
				continue
			rotulo[i] = campo
			fila.append(i)

func _inundar(grama: PackedByteArray, rotulo: PackedInt32Array, fila: Array[int]) -> void:
	var cabeca := 0
	while cabeca < fila.size():
		var atual: int = fila[cabeca]
		cabeca += 1
		var campo: int = rotulo[atual]
		var x: int = atual % RES
		var y: int = int(atual / RES)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = x + dx
				var ny: int = y + dy
				if nx < 0 or ny < 0 or nx >= RES or ny >= RES:
					continue
				_empurrar(grama, rotulo, fila, ny * RES + nx, campo)

func _empurrar(grama: PackedByteArray, rotulo: PackedInt32Array, fila: Array[int], viz: int, campo: int) -> void:
	if grama[viz] == 0 or rotulo[viz] != 0:
		return
	rotulo[viz] = campo
	fila.append(viz)

func _cor_hachura(donos: Array, x: int, y: int) -> Color:
	var n: int = donos.size()
	if n <= 0:
		return Color(0, 0, 0, 0)
	var faixa: int = int(floor(float(x + y) / 4.0))
	if posmod(faixa, 2) == 1:
		return Color(0, 0, 0, 0)
	var dono = donos[posmod(faixa / 2, n)]
	var cor: Color = dono.cor
	cor.a = 0.78
	return cor
