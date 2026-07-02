extends ParallaxLayer

# Velocidad a la que se moverá la capa sola (en píxeles por segundo)
# Un número positivo moverá el fondo hacia la derecha, uno negativo hacia la izquierda
@export var velocidad_autonoma: float = -3.0

func _process(delta: float) -> void:
	# Desplazamos la posición base de la capa en el eje X constantemente
	motion_offset.x += velocidad_autonoma * delta
