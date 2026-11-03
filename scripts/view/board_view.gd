# res://scripts/view/board_view.gd
class_name BoardView
extends Node2D

const MARKER_BASE_RADIUS := 26.0
const HIGHLIGHT_FILL := Color(1, 1, 1, 0.10)
const HIGHLIGHT_BORDER := Color(1, 1, 1, 0.35)


const RETURN_DELAY := 0.6             # espera antes de o seguidor voltar (deixa a entrada terminar)
const RETURN_STAGGER := 0.08          # intervalo entre seguidores devolvidos juntos

## (owner_id: int) -> Vector2 em coordenadas do MUNDO. Inválido = só desaparece no lugar.
var return_target: Callable = Callable()

var _meeple_nodes: Dictionary = {}    # Meeple -> MeepleView

var _popup_layer: Node2D

var _tiles_layer: Node2D
var _meeples_layer: Node2D
var _marker_layer: Node2D
var _ghost: TileView

var _views: Dictionary = {}            # Vector2i -> TileView
var _valid_cells: Array[Vector2i] = []

var _marker_cell := Vector2i.ZERO
var _marker_indices: Array[int] = []
var _marker_color := Color.WHITE
var _hover_idx := -1


func _ready() -> void:
	# Ordem de desenho (de baixo para cima): destaques (_draw), peças, fantasma, seguidores, marcadores.
	_tiles_layer = _make_layer("TilesLayer")
	_ghost = TileView.instantiate_scene()
	add_child(_ghost)
	_ghost.visible = false
	_meeples_layer = _make_layer("MeeplesLayer")
	_meeples_layer.y_sort_enabled = true
	_marker_layer = _make_layer("MarkerLayer")
	_marker_layer.draw.connect(_draw_markers)
	_popup_layer = _make_layer("PopupLayer")

func _make_layer(layer_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = layer_name
	add_child(n)
	return n


# ============================================================ peças

func add_tile(placed: PlacedTile) -> void:
	var v := TileView.instantiate_scene()
	_tiles_layer.add_child(v)           # add_child ANTES de setup (Fase 12)
	v.setup_placed(placed, true)
	_views[placed.cell] = v


func tile_view(cell: Vector2i) -> TileView:
	return _views.get(cell, null)


# ============================================================ fantasma

func show_ghost(def: TileDef, rotation: int) -> void:
	_ghost.setup_preview(def, rotation)
	_ghost.visible = true


func rotate_ghost(rotation: int) -> void:
	_ghost.set_tile_rotation(rotation)


func update_ghost(cell: Vector2i, valid: bool) -> void:
	_ghost.position = ViewConfig.cell_to_world(cell)
	_ghost.set_tint(ViewConfig.COLOR_VALID if valid else ViewConfig.COLOR_INVALID)


func hide_ghost() -> void:
	_ghost.visible = false
	
func set_ghost_visible(v: bool) -> void:
	_ghost.visible = v


# ============================================================ destaques de células válidas

func set_valid_cells(cells: Array[Vector2i]) -> void:
	_valid_cells = cells
	queue_redraw()


func _draw() -> void:
	var h := ViewConfig.HALF
	for c in _valid_cells:
		var r := Rect2(ViewConfig.cell_to_world(c) - Vector2(h, h),
				Vector2.ONE * ViewConfig.TILE_SIZE).grow(-6.0)
		draw_rect(r, HIGHLIGHT_FILL)
		draw_rect(r, HIGHLIGHT_BORDER, false, 2.0)


# ============================================================ marcadores de seguidor

## Mostra um marcador em cada feature elegível da peça (índices locais).
func show_markers(placed: PlacedTile, indices: Array[int], color: Color) -> void:
	_marker_cell = placed.cell
	_marker_indices = indices
	_marker_color = color
	_hover_idx = -1
	_marker_layer.queue_redraw()


func clear_markers() -> void:
	_marker_indices = []
	_hover_idx = -1
	_marker_layer.queue_redraw()


## Índice da feature cujo marcador está sob o ponto do mundo, ou -1.
func marker_at(world_pos: Vector2) -> int:
	var best := -1
	var best_dist := _marker_radius()
	for idx in _marker_indices:
		var d := world_pos.distance_to(_marker_world(idx))
		if d <= best_dist:
			best_dist = d
			best = idx
	return best


func _marker_world(idx: int) -> Vector2:
	return _views[_marker_cell].anchor_world(idx)


## Raio em unidades de mundo. Cresce quando o zoom diminui, para o marcador não sumir.
func _marker_radius() -> float:
	var cam := get_viewport().get_camera_2d()
	var z := cam.zoom.x if cam != null else 1.0
	return MARKER_BASE_RADIUS / clampf(z, 0.5, 1.5)


func _process(_delta: float) -> void:
	if _marker_indices.is_empty():
		return
	_hover_idx = marker_at(get_global_mouse_position())
	_marker_layer.queue_redraw()        # redesenha todo frame: acompanha zoom e hover


func _draw_markers() -> void:
	var base := _marker_radius()
	for idx in _marker_indices:
		var p := _marker_layer.to_local(_marker_world(idx))
		var hover := idx == _hover_idx
		var r := base * (1.3 if hover else 1.0)
		var fill := _marker_color
		fill.a = 0.95 if hover else 0.70
		_marker_layer.draw_circle(p, r, fill)
		_marker_layer.draw_arc(p, r, 0.0, TAU, 32, Color.WHITE, 3.0)


# ============================================================ seguidores

## `idx` é o índice local da feature (vem do sinal meeple_placed).
func add_meeple(m: Meeple, placed: PlacedTile, idx: int, color: Color, animate := true) -> void:
	var v := MeepleView.new()
	_meeples_layer.add_child(v)          # add_child ANTES de animar
	v.setup(m, color)
	v.place_at(_views[placed.cell].anchor_world(idx), animate)
	_meeple_nodes[m] = v


## Remove os seguidores do tabuleiro (já devolvidos pelo modelo).
## O registro sai na hora, o nó some ao fim da animação.
func remove_meeples(list: Array[Meeple], animate := true) -> void:
	var order := 0
	for m in list:
		var v: MeepleView = _meeple_nodes.get(m, null)
		_meeple_nodes.erase(m)
		if v == null:
			continue
		if not animate:
			v.queue_free()
			continue
		var delay := RETURN_DELAY + order * RETURN_STAGGER
		if return_target.is_valid():
			var target: Vector2 = return_target.call(m.owner_id)
			v.play_return(target, delay, true)
		else:
			v.play_return(v.position, delay, false)
		order += 1


func meeple_view(m: Meeple) -> MeepleView:
	return _meeple_nodes.get(m, null)


func meeple_count() -> int:
	return _meeple_nodes.size()

# ============================================================ popups de pontuação

## "+N" sobre o centro da região pontuada. `slot` desloca popups da mesma região
## (empate: dois jogadores pontuam o mesmo valor).
func show_score_popup(e: ScoreEvent, color: Color, delay: float, slot := 0) -> void:
	if e.cells.is_empty():
		return
	var sum := Vector2.ZERO
	for c in e.cells:
		sum += ViewConfig.cell_to_world(c)
	var p := sum / e.cells.size()
	p.x += slot * 120.0

	var n := ScorePopup.new()
	n.text = "+%d" % e.points
	n.color = MeepleView.display_color(color) if color.get_luminance() < 0.15 else color
	n.position = p
	_popup_layer.add_child(n)             # add_child ANTES de animar
	var cam := get_viewport().get_camera_2d()
	n.start(delay, cam.zoom.x if cam != null else 1.0)


func popup_count() -> int:
	return _popup_layer.get_child_count()
