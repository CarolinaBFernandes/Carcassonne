# res://scripts/view/tile_view.gd
class_name TileView
extends Node2D

const SCENE_PATH := "res://scenes/tile_view.tscn"

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _anchors_root: Node2D = $MeepleAnchors
@onready var _overlay: Node2D = $Overlay

## Definição desenhada.
var def: TileDef = null
## PlacedTile do modelo. null quando é um fantasma (preview).
var placed: PlacedTile = null
## Rotação lógica atual (0..3).
var rot_steps: int = 0

## Overlay de depuração (lados, portas e âncoras).
var show_debug: bool = false:
	set = set_show_debug

var _fit_scale: float = 1.0       # escala que faz a textura caber em TILE_SIZE
var _visual_steps: int = 0        # rotação acumulada, sem módulo (evita giros longos no tween)
var _anchors: Array[Marker2D] = []
var _rot_tween: Tween = null
var _anim_tween: Tween = null


## Cria uma instância da cena. Chame add_child() ANTES de setup_placed/setup_preview.
static func instantiate_scene() -> TileView:
	return (load(SCENE_PATH) as PackedScene).instantiate() as TileView


func _ready() -> void:
	_overlay.draw.connect(_draw_overlay)


# ============================================================ configuração

## Peça do tabuleiro: posiciona na célula, aplica a rotação e cria os âncoras.
func setup_placed(p: PlacedTile, animate := true) -> void:
	placed = p
	_apply_def(p.data)
	position = ViewConfig.cell_to_world(p.cell)
	_set_steps_instant(p.rotation)
	_build_anchors()
	if animate:
		play_place_animation()


## Fantasma/prévia: não tem célula nem âncoras. O chamador posiciona o nó.
func setup_preview(d: TileDef, rotation := 0) -> void:
	placed = null
	_apply_def(d)
	_set_steps_instant(rotation)
	_clear_anchors()


func _apply_def(d: TileDef) -> void:
	def = d
	_sprite.texture = d.texture
	_sprite.modulate = Color.WHITE
	_fit_scale = 1.0
	if d.texture == null:
		push_warning("TileView: peça %s sem textura" % d.id)
	else:
		var size := d.texture.get_size()
		if not is_equal_approx(size.x, size.y):
			push_warning("TileView: textura da peça %s não é quadrada (%s)" % [d.id, size])
		_fit_scale = float(ViewConfig.TILE_SIZE) / size.x
	_sprite.scale = Vector2.ONE * _fit_scale


# ============================================================ rotação

func _set_steps_instant(r: int) -> void:
	rot_steps = posmod(r, 4)
	_visual_steps = rot_steps
	if _rot_tween != null:
		_rot_tween.kill()
	_sprite.rotation = _visual_steps * PI / 2.0
	_overlay.queue_redraw()


## Muda a rotação lógica (0..3). Com animate, gira pelo caminho mais curto
## (de 3 para 0 é +90°, não -270°).
func set_tile_rotation(r: int, animate := true) -> void:
	var target := posmod(r, 4)
	var delta := posmod(target - rot_steps, 4)
	if delta == 3:
		delta = -1
	rot_steps = target
	_visual_steps += delta
	var angle := _visual_steps * PI / 2.0

	if _rot_tween != null:
		_rot_tween.kill()
	if animate:
		_rot_tween = create_tween()
		_rot_tween.tween_property(_sprite, "rotation", angle, 0.10) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_sprite.rotation = angle
	_overlay.queue_redraw()


# ============================================================ aparência

## Cor do fantasma (ViewConfig.COLOR_VALID / COLOR_INVALID). Color.WHITE restaura.
func set_tint(c: Color) -> void:
	_sprite.modulate = c


## Entrada suave: cresce de 85% a 100% com fade. Só mexe no sprite,
## então âncoras e seguidores não são afetados.
func play_place_animation() -> void:
	if _anim_tween != null:
		_anim_tween.kill()
	var target := Vector2.ONE * _fit_scale
	_sprite.scale = target * 0.85
	_sprite.modulate.a = 0.0
	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.tween_property(_sprite, "scale", target, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_sprite, "modulate:a", 1.0, 0.12)


# ============================================================ âncoras de seguidor

func _clear_anchors() -> void:
	for a in _anchors:
		a.queue_free()
	_anchors.clear()


## Um Marker2D por feature (mesma ordem de def.features), já rotacionado e escalado.
func _build_anchors() -> void:
	_clear_anchors()
	for i in placed.data.features.size():
		var m := Marker2D.new()
		m.name = "Anchor%d" % i
		m.position = placed.anchor_of(i) * _fit_scale
		_anchors_root.add_child(m)
		_anchors.append(m)


func anchor_count() -> int:
	return _anchors.size()


## Posição do âncora da feature `idx` relativa ao centro da peça.
func anchor_local(idx: int) -> Vector2:
	return _anchors[idx].position


## Posição do âncora no mundo (onde desenhar o marcador clicável ou o seguidor).
func anchor_world(idx: int) -> Vector2:
	return _anchors[idx].global_position


# ============================================================ depuração

func set_show_debug(v: bool) -> void:
	show_debug = v
	if is_node_ready():
		_overlay.queue_redraw()


static func _side_color(t: FeatureData.Type) -> Color:
	match t:
		FeatureData.Type.CITY: return Color(0.75, 0.45, 0.10)   # marrom
		FeatureData.Type.ROAD: return Color(0.95, 0.95, 0.95)   # branco
	return Color(0.20, 0.80, 0.20)                              # campo: verde


static func _type_color(t: FeatureData.Type) -> Color:
	match t:
		FeatureData.Type.CITY: return Color(0.75, 0.45, 0.10)
		FeatureData.Type.ROAD: return Color(0.90, 0.90, 0.90)
		FeatureData.Type.MONASTERY: return Color(0.80, 0.30, 0.90)
	return Color(0.20, 0.80, 0.20)


func _draw_overlay() -> void:
	if not show_debug or def == null:
		return
	var h := ViewConfig.HALF
	var font := ThemeDB.fallback_font

	# Borda da célula.
	_overlay.draw_rect(Rect2(-h, -h, h * 2.0, h * 2.0), Color(1, 0, 1, 0.9), false, 2.0)

	# Tipo de cada lado (cidade = marrom, estrada = branco, campo = verde).
	for s in 4:
		var d := Vector2(Geometry.DIRS[s])
		var tang := Vector2(-d.y, d.x)
		var mid := d * (h - 6.0)
		_overlay.draw_line(mid - tang * 48.0, mid + tang * 48.0,
				_side_color(def.side_type(s, rot_steps)), 10.0)

	# Portas: círculo colorido por campo, com o índice do campo (-) se for lado de cidade.
	for p in 8:
		var idx := def.port_feature_index(p, rot_steps)
		var inward := -Vector2(Geometry.DIRS[Geometry.side_of_port(p)]) * 24.0
		var pos := ViewConfig.port_position(p) + inward
		var col := Color(0.3, 0.3, 0.3) if idx == -1 \
				else Color.from_hsv(fposmod(idx * 0.17, 1.0), 0.8, 1.0)
		_overlay.draw_circle(pos, 12.0, col)
		_overlay.draw_string(font, pos + Vector2(-5, 6), str(idx) if idx >= 0 else "-",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.BLACK)

	# Âncoras de seguidor: círculo com contorno preto e índice da feature.
	for i in def.features.size():
		var a := def.rotated_anchor(i, rot_steps) * _fit_scale
		_overlay.draw_circle(a, 14.0, _type_color(def.features[i].type))
		_overlay.draw_arc(a, 14.0, 0.0, TAU, 24, Color.BLACK, 2.0)
		_overlay.draw_string(font, a + Vector2(-5, 6), str(i),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.BLACK)
