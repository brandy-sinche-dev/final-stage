extends Area2D

# 🌟 La clave de la reutilización: asignas el ID desde el Inspector de Godot
@export var llave_id: String = "key_1"

func _ready() -> void:
	# Conectamos la señal de colisión por código de forma limpia
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que la tocó es el jugador (Leo)
	if body.is_in_group("player") and body.has_method("agregar_llave"):
		body.agregar_llave(llave_id) # Le damos la llave a Leo
		print("¡Llave recolectada!: ", llave_id)
		queue_free() # La llave desaparece del mapa
