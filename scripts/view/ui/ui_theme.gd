# res://scripts/view/ui/ui_theme.gd
class_name UITheme
extends RefCounted

const PANEL_BG := Color(0.13, 0.16, 0.14, 0.93)
const BUTTON_BG := Color(0.24, 0.29, 0.25)
const BUTTON_HOVER := Color(0.31, 0.38, 0.32)
const BUTTON_PRESSED := Color(0.18, 0.22, 0.19)
const ACCENT := Color(0.96, 0.80, 0.32)
const TEXT := Color(0.95, 0.95, 0.92)
const TEXT_DIM := Color(0.68, 0.71, 0.68)
const BORDER := Color(1, 1, 1, 0.14)
const ERROR := Color(1.0, 0.45, 0.40)

static var _shared: Theme = null


## Theme único reaproveitado por todas as telas.
static func shared() -> Theme:
	if _shared == null:
		_shared = create()
	return _shared


static func box(bg: Color, border := Color(0, 0, 0, 0), border_w := 0,
		radius := 10, margin := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


## Texto preto sobre cor clara, branco sobre cor escura.
static func contrast_text(c: Color) -> Color:
	return Color.BLACK if c.get_luminance() > 0.5 else Color.WHITE


static func create() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	# Para usar uma fonte própria: t.default_font = load("res://assets/fonts/minha.ttf")

	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", box(PANEL_BG, BORDER, 1, 14, 14))

	t.set_stylebox("normal", "Button", box(BUTTON_BG, BORDER, 1, 10, 12))
	t.set_stylebox("hover", "Button", box(BUTTON_HOVER, BORDER, 1, 10, 12))
	t.set_stylebox("pressed", "Button", box(BUTTON_PRESSED, BORDER, 1, 10, 12))
	t.set_stylebox("disabled", "Button", box(BUTTON_BG.darkened(0.35), BORDER, 1, 10, 12))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), ACCENT, 2, 10, 12))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)

	t.set_stylebox("normal", "LineEdit", box(Color(0.08, 0.10, 0.09), BORDER, 1, 8, 8))
	t.set_stylebox("focus", "LineEdit", box(Color(0.08, 0.10, 0.09), ACCENT, 2, 8, 8))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	t.set_color("caret_color", "LineEdit", ACCENT)

	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	return t
