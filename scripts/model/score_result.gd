# res://scripts/model/score_result.gd
class_name ScoreResult
extends RefCounted

var events: Array[ScoreEvent] = []
var released: Array[Meeple] = []        # seguidores devolvidos aos donos
