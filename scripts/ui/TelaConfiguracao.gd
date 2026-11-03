extends Control

var main

const CORES := [
	{"nome": "Verde", "arq": "green", "cor": Color(0.20, 0.65, 0.25)},
	{"nome": "Azul", "arq": "blue", "cor": Color(0.15, 0.40, 0.80)},
	{"nome": "Vermelho", "arq": "red", "cor": Color(0.80, 0.22, 0.22)},
	{"nome": "Amarelo", "arq": "yellow", "cor": Color(0.92, 0.78, 0.18)},
]

var _ativos: Array = []
var _nomes: Array = []
var _ias: Array = []
var _linhas: Array = []
var _aviso: Label
var _seed_edit: LineEdit

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := TextureRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/carcassonne.png"):
		fundo.texture = load("res://assets/carcassonne.png")
	fundo.modulate = Color(0.30, 0.30, 0.30)
	add_child(fundo)
	var escuro := ColorRect.new()
	escuro.color = Color(0.06, 0.07, 0.10, 0.55)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)

	var cx := CenterContainer.new()
	cx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cx)

	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.13, 0.19, 0.98)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.9, 0.78, 0.35, 0.5)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	for m in ["content_margin_left", "content_margin_right"]:
		sb.set(m, 32)
	for m in ["content_margin_top", "content_margin_bottom"]:
		sb.set(m, 26)
	card.add_theme_stylebox_override("panel", sb)
	cx.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.custom_minimum_size = Vector2(560, 0)
	card.add_child(vb)

	var titulo := Label.new()
	titulo.text = "Configurar Jogadores"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color(0.96, 0.86, 0.5))
	vb.add_child(titulo)
	var sub := Label.new()
	sub.text = "Escolha quem joga e marque quais sao controlados pela IA"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	vb.add_child(sub)
	vb.add_child(_separador())

	for i in range(CORES.size()):
		vb.add_child(_criar_linha(i))
		_atualizar_linha(i)

	vb.add_child(_separador())

	var hs := HBoxContainer.new()
	hs.add_theme_constant_override("separation", 10)
	vb.add_child(hs)
	var ls := Label.new()
	ls.text = "Seed (opcional):"
	ls.add_theme_color_override("font_color", Color(0.82, 0.85, 0.9))
	hs.add_child(ls)
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "vazio = aleatoria (deck em ordem reproduzivel)"
	_seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hs.add_child(_seed_edit)

	_aviso = Label.new()
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_color_override("font_color", Color(1, 0.55, 0.5))
	vb.add_child(_aviso)

	vb.add_child(_separador())
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 18)
	vb.add_child(hb)
	var b_voltar := _botao("Voltar", Color(0.28, 0.30, 0.36), Vector2(150, 48))
	b_voltar.pressed.connect(func(): if main: main.ir_inicial())
	hb.add_child(b_voltar)
	var b_iniciar := _botao("Iniciar Partida", Color(0.20, 0.60, 0.28), Vector2(220, 48))
	b_iniciar.add_theme_font_size_override("font_size", 18)
	b_iniciar.pressed.connect(_on_iniciar)
	hb.add_child(b_iniciar)

func _criar_linha(i: int) -> PanelContainer:
	var linha := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CORES[i]["cor"].darkened(0.35)
	sb.set_corner_radius_all(10)
	for m in ["content_margin_left", "content_margin_right"]:
		sb.set(m, 14)
	for m in ["content_margin_top", "content_margin_bottom"]:
		sb.set(m, 8)
	linha.add_theme_stylebox_override("panel", sb)
	_linhas.append(linha)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	linha.add_child(hb)

	var ativo := CheckBox.new()
	ativo.button_pressed = i < 2
	ativo.toggled.connect(func(_v): _atualizar_linha(i))
	_ativos.append(ativo)
	hb.add_child(ativo)

	var meeple := TextureRect.new()
	var cam := "res://assets/meeple/%s-meeple.png" % CORES[i]["arq"]
	if ResourceLoader.exists(cam):
		meeple.texture = load(cam)
	meeple.custom_minimum_size = Vector2(34, 34)
	meeple.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meeple.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	hb.add_child(meeple)

	var cor_lbl := Label.new()
	cor_lbl.text = CORES[i]["nome"]
	cor_lbl.custom_minimum_size = Vector2(90, 0)
	cor_lbl.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(cor_lbl)

	var nome := LineEdit.new()
	nome.text = ("Voce" if i == 0 else CORES[i]["nome"])
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nomes.append(nome)
	hb.add_child(nome)

	var ia := CheckButton.new()
	ia.text = "IA"
	ia.button_pressed = i == 1
	ia.add_theme_color_override("font_color", Color.WHITE)
	_ias.append(ia)
	hb.add_child(ia)

	return linha

func _atualizar_linha(i: int) -> void:
	_linhas[i].modulate = Color(1, 1, 1, 1) if _ativos[i].button_pressed else Color(1, 1, 1, 0.38)

func _separador() -> HSeparator:
	var s := HSeparator.new()
	return s

func _botao(txt: String, cor: Color, tam: Vector2) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = tam
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(8)
	var sb2 := StyleBoxFlat.new()
	sb2.bg_color = cor.lightened(0.12)
	sb2.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb2)
	b.add_theme_color_override("font_color", Color.WHITE)
	return b

func _on_iniciar() -> void:
	var configs: Array = []
	for i in range(CORES.size()):
		if _ativos[i].button_pressed:
			configs.append({
				"nome": _nomes[i].text,
				"corArquivo": CORES[i]["arq"],
				"cor": CORES[i]["cor"],
				"ehIA": _ias[i].button_pressed,
			})
	if configs.size() < 2:
		_aviso.text = "Selecione pelo menos 2 jogadores."
		return
	if main != null:
		main.ir_jogo(configs, _ler_seed())

func _ler_seed() -> int:
	var txt := _seed_edit.text.strip_edges()
	if txt.is_empty():
		return 0
	if txt.is_valid_int():
		var v := int(txt)
		return v if v != 0 else 1
	return int(txt.hash()) if txt.hash() != 0 else 1
