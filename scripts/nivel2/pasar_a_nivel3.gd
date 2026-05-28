extends Area2D

@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/nivel3/nivel_3.tscn"

var ya_cambio := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if ya_cambio:
		return

	if body.is_in_group("player"):
		ya_cambio = true
		print("Pasando del nivel 2 al nivel 3...")
		get_tree().change_scene_to_file(siguiente_nivel)
