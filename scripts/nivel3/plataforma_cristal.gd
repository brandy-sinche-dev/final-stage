extends StaticBody2D

@export var distancia_revelado: float = 130.0
@export var alpha_oculto: float = 0.18
@export var alpha_visible: float = 0.90
@export var velocidad_revelado: float = 8.0

@onready var visual: CanvasItem = get_node_or_null("Polygon2D")

func _ready() -> void:
	# Solo capa de suelo/plataforma.
	# Importante: NO usar capa de enemigo ni objetivo de espada.
	collision_layer = 1
	collision_mask = 0
	
	if visual:
		var color := visual.modulate
		color.a = alpha_oculto
		visual.modulate = color

func _process(delta: float) -> void:
	var leo = get_tree().get_first_node_in_group("player")
	if not leo or not visual:
		return
	
	var distancia := global_position.distance_to(leo.global_position)
	var objetivo := alpha_visible if distancia <= distancia_revelado else alpha_oculto
	
	var color := visual.modulate
	color.a = lerp(color.a, objetivo, delta * velocidad_revelado)
	visual.modulate = color
