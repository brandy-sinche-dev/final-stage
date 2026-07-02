extends StaticBody2D

@export var visual_node_path: NodePath
@export var tiempo_antes_de_desaparecer: float = 0.45
@export var tiempo_oculta: float = 2.0
@export var reaparece: bool = true
@export var duracion_animacion: float = 0.25

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var detector: Area2D = get_node_or_null("DetectorJugador")
@onready var detector_shape: CollisionShape2D = get_node_or_null("DetectorJugador/CollisionShape2D")

var visual: CanvasItem
var escala_original: Vector2
var desapareciendo := false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	
	if visual_node_path != NodePath(""):
		visual = get_node_or_null(visual_node_path) as CanvasItem
	
	if visual == null:
		visual = get_node_or_null("Sprite2D") as CanvasItem
	
	if visual == null:
		visual = get_node_or_null("Polygon2D") as CanvasItem
	
	if visual:
		escala_original = visual.scale
	
	if detector:
		detector.collision_layer = 0
		detector.collision_mask = 2
		detector.body_entered.connect(_on_detector_body_entered)

func _on_detector_body_entered(body: Node2D) -> void:
	if desapareciendo:
		return
	
	if body.is_in_group("player"):
		_desaparecer()

func _desaparecer() -> void:
	desapareciendo = true
	
	if visual:
		for i in range(3):
			var parpadeo := create_tween()
			parpadeo.tween_property(visual, "modulate:a", 0.35, 0.07)
			parpadeo.tween_property(visual, "modulate:a", 1.0, 0.07)
			await parpadeo.finished
	
	await get_tree().create_timer(tiempo_antes_de_desaparecer).timeout
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	if detector_shape:
		detector_shape.set_deferred("disabled", true)
	
	if visual:
		var desaparecer := create_tween()
		desaparecer.parallel().tween_property(visual, "modulate:a", 0.0, duracion_animacion)
		desaparecer.parallel().tween_property(visual, "scale", escala_original * 0.92, duracion_animacion)
		await desaparecer.finished
	
	if not reaparece:
		return
	
	await get_tree().create_timer(tiempo_oculta).timeout
	
	if visual:
		visual.scale = escala_original
		var aparecer := create_tween()
		aparecer.tween_property(visual, "modulate:a", 1.0, duracion_animacion)
		await aparecer.finished
	
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	
	if detector_shape:
		detector_shape.set_deferred("disabled", false)
	
	desapareciendo = false
