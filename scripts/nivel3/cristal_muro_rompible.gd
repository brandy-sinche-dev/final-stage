extends StaticBody2D

@export var vida: int = 45
@export var visual_node_path: NodePath
@export var duracion_romper: float = 0.35

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var visual: Node2D
var escala_original: Vector2
var rompiendose := false
var visual_externo := false

func _ready() -> void:
	# Capa 1: bloquea a Leo.
	# Capa 3: permite que la espada lo detecte.
	collision_layer = 5
	collision_mask = 0
	
	if visual_node_path != NodePath(""):
		visual = get_node_or_null(visual_node_path) as Node2D
	
	if visual == null:
		visual = get_node_or_null("Sprite2D") as Node2D
	
	if visual:
		escala_original = visual.scale
		visual_externo = not is_ancestor_of(visual)

func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	if rompiendose:
		return
	
	vida -= cantidad
	print("Cristal muro golpeado. Vida restante: ", vida)
	
	_animar_golpe(origen_danio_x)
	
	if vida <= 0:
		_romper()

func _animar_golpe(origen_danio_x: float) -> void:
	if visual == null:
		return
	
	var direccion: float = 1.0 if global_position.x > origen_danio_x else -1.0
	var posicion_original: Vector2 = visual.position
	
	var tween := create_tween()
	tween.tween_property(visual, "position:x", posicion_original.x + 8.0 * direccion, 0.04)
	tween.tween_property(visual, "position:x", posicion_original.x - 5.0 * direccion, 0.04)
	tween.tween_property(visual, "position:x", posicion_original.x, 0.04)

func _romper() -> void:
	if rompiendose:
		return
	
	rompiendose = true
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	if visual:
		var tween := create_tween()
		tween.parallel().tween_property(visual, "modulate:a", 0.0, duracion_romper)
		tween.parallel().tween_property(visual, "scale", escala_original * 1.15, duracion_romper)
		await tween.finished
		
		if visual_externo and is_instance_valid(visual):
			visual.queue_free()
	
	queue_free()
