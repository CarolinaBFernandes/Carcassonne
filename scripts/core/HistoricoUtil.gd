class_name HistoricoUtil
extends RefCounted

const TS := 56

static func imagem_grupo(grupo: Array) -> Texture2D:
	var tiles := []
	for f in grupo:
		if f.tile != null and not tiles.has(f.tile):
			tiles.append(f.tile)
	if tiles.is_empty():
		return null
	var minx := 999999
	var miny := 999999
	var maxx := -999999
	var maxy := -999999
	for t in tiles:
		minx = min(minx, t.posicao.x)
		maxx = max(maxx, t.posicao.x)
		miny = min(miny, t.posicao.y)
		maxy = max(maxy, t.posicao.y)
	var w := (maxx - minx + 1)
	var h := (maxy - miny + 1)
	var img := Image.create(w * TS, h * TS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for t in tiles:
		var cam := "res://assets/tiles/%s0.png" % t.tipoBase
		if not ResourceLoader.exists(cam):
			continue
		var ti := (load(cam) as Texture2D).get_image()
		if ti.is_compressed():
			ti.decompress()
		ti.convert(Image.FORMAT_RGBA8)
		for _i in range(t.rotacao):
			ti.rotate_90(CLOCKWISE)
		ti.resize(TS, TS, Image.INTERPOLATE_BILINEAR)
		var px: int = (t.posicao.x - minx) * TS
		var py: int = (t.posicao.y - miny) * TS
		img.blit_rect(ti, Rect2i(0, 0, TS, TS), Vector2i(px, py))
		for f in grupo:
			if f.tile != t:
				continue
			for m in f.meeples:
				var cor_arq: String = m.dono.corArquivo if m.dono != null else "blue"
				var mcam := "res://assets/meeple/%s-meeple.png" % cor_arq
				if not ResourceLoader.exists(mcam):
					continue
				var mi := (load(mcam) as Texture2D).get_image()
				if mi.is_compressed():
					mi.decompress()
				mi.convert(Image.FORMAT_RGBA8)
				var msz := int(TS * 0.34)
				mi.resize(msz, msz, Image.INTERPOLATE_BILINEAR)
				var a: Vector2 = f.ancora_norm
				var mx: int = px + int(a.x * TS) - msz / 2
				var my: int = py + int(a.y * TS) - msz / 2
				img.blend_rect(mi, Rect2i(0, 0, msz, msz), Vector2i(mx, my))
	return ImageTexture.create_from_image(img)
