class_name FeatureData extends Resource
enum Type { CITY, ROAD, FIELD, MONASTERY }
@export var type: Type
@export var sides: Array[int] = []        # CITY/ROAD: lados que toca
@export var half_ports: Array[int] = []   # FIELD: portas (0-7)
@export var has_shield: bool = false      # CITY
@export var adjacent_cities: Array[int] = [] # FIELD: índices (na mesma peça) de cidades vizinhas
@export var meeple_anchor: Vector2        # posição local do marcador de seguidor
