extends Node2D

# Cargamos la escena del proyectil que creamos antes
@export var bola_fuego_scene: PackedScene = preload("res://scenes/nivel2/bola_fuego.tscn")

@export var hacia_la_izquierda: bool = true
@export var tiempo_disparo: float = 2.0 # Segundos entre cada disparo

@onready var punto_disparo = $Marker2D
@onready var timer = $Timer

func _ready():
	# Configurar el temporizador
	timer.wait_time = tiempo_disparo
	timer.start()
	
	# Ajustar el marcador de posición según la dirección
	if hacia_la_izquierda:
		# Si dispara a la izquierda, el punto de salida debe estar en el lado izquierdo
		punto_disparo.position.x = -abs(punto_disparo.position.x)
		# Opcional: si tu tubo tiene lado, podrías voltear el sprite del tubo aquí
		# $Sprite2D.flip_h = true
	else:
		punto_disparo.position.x = abs(punto_disparo.position.x)

# Conecta la señal "timeout" del Timer a este script
func _on_timer_timeout() -> void:
	disparar()

func disparar():
	if bola_fuego_scene:
		# Creación del objeto en el juego
		var nueva_bola = bola_fuego_scene.instantiate()
		
		# Decidir la dirección del proyectil
		if hacia_la_izquierda:
			nueva_bola.direccion = Vector2.LEFT
		else:
			nueva_bola.direccion = Vector2.RIGHT
			
		# Colocar la bola de fuego exactamente en la boca del cañón
		nueva_bola.global_position = punto_disparo.global_position
		
		# Añadir el proyectil a la escena principal para que se mueva de forma independiente
		get_tree().current_scene.add_child(nueva_bola)
