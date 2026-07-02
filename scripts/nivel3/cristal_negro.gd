extends StaticBody2D

@export var vida: int = 30

func _ready() -> void:
	collision_layer = 5
	collision_mask = 0

func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	vida -= cantidad
	print("Cristal negro golpeado. Vida restante: ", vida)

	if vida <= 0:
		queue_free()
