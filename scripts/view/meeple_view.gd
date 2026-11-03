# res://scripts/view/meeple_view.gd
class_name MeepleView
extends Node2D

const TEX_STANDING_PATH := "res://assets/meeples/meeple.png"
const TEX_FARMER_PATH := "res://assets/meeples/meeple_farmer.png"

## Maior dimensão do seguidor, em pixels de mundo.
const HEIGHT := ViewConfig.TILE_SIZE * 0.30
const SHADOW_OFFSET := Vector2(4.0, 6.0)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const DROP_HEIGHT := 140.0
const DROP_TIME := 0.45
const RETURN_TIME := 0.5

static var _tex_standing: Texture2D = null
static var _tex_farmer: Texture2D = null
static var _tex_loaded := false

var meeple: Meeple = null
var is_farmer := false
var farmer_is_rotated := false       # true: fazendeiro usa a textura em pé girada 90°
var returning := false               # true depois de play_return()
var home := Vector2.ZERO             # posição final (âncora), em coordenadas do mundo

var _body: Sprite2D
var _shadow: Sprite2D
var _color := Color.WHITE
var _use_fallback := false
var _drop_tween: Tween = null
var _return_tween: Tween = null


func _init() -> void:
	_shadow = Sprite2D.new()
	_shadow.modulate = SHADOW_COLOR
	_shadow.position = SHADOW_OFFSET
	add_child(_shadow)
	_body = Sprite2D.new()
	add_child(_body)


# ============================================================ texturas

## Carrega as texturas uma vez. Textura ausente fica null (usa-se o fallback).
static func _ensure_textures() -> void:
	if _tex_loaded:
		return
	_tex_loaded = true
	if ResourceLoader.exists(TEX_STANDING_PATH):
		_tex_standing = load(TEX_STANDING_PATH) as Texture2D
	if ResourceLoader.exists(TEX_FARMER_PATH):
		_tex_farmer = load(TEX_FARMER_PATH) as Texture2D


## Textura em pé (a HUD da Fase 15 reutiliza para os ícones de estoque).
static func standing_texture() -> Texture2D:
	_ensure_textures()
	return _tex_standing


## Cores muito escuras viram cinza-escuro, senão o modulate apaga o sombreado.
static func display_color(c: Color) -> Color:
	if c.get_luminance() < 0.15:
		return Color(0.25, 0.25, 0.25, c.a)
	return c


# ============================================================ configuração

## Configura o aspecto. Pode ser chamado antes ou depois de add_child.
func setup(m: Meeple, player_color: Color) -> void:
	meeple = m
	is_farmer = m.is_farmer
	_color = display_color(player_color)
	_ensure_textures()

	var tex: Texture2D = _tex_standing
	farmer_is_rotated = false
	if is_farmer:
		if _tex_farmer != null:
			tex = _tex_farmer
		elif _tex_standing != null:
			farmer_is_rotated = true      # sem arte própria: gira o seguidor em pé

	_use_fallback = tex == null
	var rot := PI / 2.0 if farmer_is_rotated else 0.0
	var s := 1.0
	if tex != null:
		var size := tex.get_size()
		s = HEIGHT / maxf(size.x, size.y)

	for spr in [_body, _shadow]:
		spr.texture = tex
		spr.rotation = rot
		spr.scale = Vector2.ONE * s
	_body.modulate = _color
	queue_redraw()


## Posiciona no âncora (coordenadas do mundo). Chame depois de add_child se animate for true.
func place_at(world_pos: Vector2, animate := true) -> void:
	home = world_pos
	position = world_pos
	if animate:
		play_drop()


# ============================================================ animações

## Cai de cima, quica e fica parado no âncora.
func play_drop() -> void:
	_kill(_drop_tween)
	position = home + Vector2(0.0, -DROP_HEIGHT)
	scale = Vector2.ONE * 1.25
	modulate.a = 0.0
	_drop_tween = create_tween().set_parallel(true)
	_drop_tween.tween_property(self, "position", home, DROP_TIME) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "modulate:a", 1.0, 0.12)


## Voa até `target` (mundo) encolhendo e some; depois libera o nó.
## fly = false: só sobe e desaparece no lugar (quando não há destino).
## Com delay > 0 a animação de entrada em andamento não é interrompida.
func play_return(target: Vector2, delay := 0.0, fly := true) -> void:
	returning = true
	if delay <= 0.0:
		_kill(_drop_tween)
	_kill(_return_tween)

	var dest := target if fly else position + Vector2(0.0, -50.0)
	var end_scale := Vector2.ONE * (0.4 if fly else 1.0)
	_return_tween = create_tween().set_parallel(true)
	_return_tween.tween_property(self, "position", dest, RETURN_TIME) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_return_tween.tween_property(self, "scale", end_scale, RETURN_TIME) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_return_tween.tween_property(self, "modulate:a", 0.0, 0.15) \
			.set_delay(delay + RETURN_TIME - 0.15)
	_return_tween.chain().tween_callback(queue_free)


func _kill(t: Tween) -> void:
	if t != null:
		t.kill()


# ============================================================ fallback

func _draw() -> void:
	if not _use_fallback:
		return
	var r := HEIGHT * 0.28
	if is_farmer:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.5, 0.7))   # "deitado"
	draw_circle(Vector2.ZERO, r, _color)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color.BLACK, 2.0)
