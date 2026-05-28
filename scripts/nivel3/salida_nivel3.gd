extends Area2D

@export_file("*.tscn") var siguiente_escena: String = ""

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Leo":
		return

	print("Nivel 3 completado")

	if siguiente_escena != "":
		get_tree().change_scene_to_file(siguiente_escena)
