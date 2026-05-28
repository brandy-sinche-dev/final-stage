extends Area2D

@export var impulso_y: float = -520.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Leo":
		body.velocity.y = impulso_y
