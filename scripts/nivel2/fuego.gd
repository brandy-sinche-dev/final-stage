extends Area2D

@export var velocidad: float = 200.0
@export var cantidad_dano: int = 15

var direccion: Vector2 = Vector2.RIGHT # Por defecto va a la derecha

@onready var animacion = $AnimatedSprite2D

func _ready():
	animacion.play("fuego")
	# Si la dirección es hacia la izquierda, volteamos el sprite horizontalmente
	if direccion.x < 0:
		animacion.flip_h = true

func _physics_process(delta: float) -> void:
	# Mueve el proyectil continuamente en la dirección asignada
	global_position += direccion * velocidad * delta

# Conecta la señal "body_entered" de este Area2D
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_danio"):
		body.recibir_danio(cantidad_dano, global_position.x)
		queue_free() # Destruye la bola de fuego al golpear a Leo
		
	# Opcional: Si choca contra las paredes del mapa (TileMap), también se destruye
	elif body is TileMap: 
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Se borra si sale de la pantalla
