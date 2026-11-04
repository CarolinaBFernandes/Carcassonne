class_name Meeple
extends Node2D

const TAM_TILE := 128.0

var dono = null
var tipoSegmento: int = FeatureTile.Tipo.CAMPO
var featureTile = null

var _sprite: Sprite2D

static func nome_tipo(tipo_seg: int) -> String:
	match tipo_seg:
		FeatureTile.Tipo.CIDADE: return "cavaleiro"
		FeatureTile.Tipo.ESTRADA: return "ladrao"
		FeatureTile.Tipo.MOSTEIRO: return "monge"
		_: return "fazendeiro"

func configurar(jogador, tipo_seg: int) -> void:
	dono = jogador
	tipoSegmento = tipo_seg

func _ready() -> void:
	z_as_relative = false
	z_index = 40
	_construir_sprite()

func _construir_sprite() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	var cor_nome := "blue"
	if dono != null:
		cor_nome = dono.corArquivo
	var caminho := "res://assets/meeple/%s-meeple.png" % cor_nome
	if ResourceLoader.exists(caminho):
		var tex: Texture2D = load(caminho)
		_sprite.texture = tex
		var alvo := TAM_TILE * 0.24
		_sprite.scale = Vector2.ONE * (alvo / float(tex.get_width()))
	add_child(_sprite)

func posicionar(ft) -> void:
	featureTile = ft
	position = ft.ancora_norm * TAM_TILE if ft != null else Vector2(TAM_TILE * 0.5, TAM_TILE * 0.5)

func devolver_animado() -> void:
	if not is_inside_tree():
		queue_free()
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
