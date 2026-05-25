extends Area2D

# Configuracion de que llave necesita esta puerta específica desde el Inspector
@export var llave_requerida_id: String = "key_1"
@export var consume_la_llave: bool = true

@onready var sprite = $AnimatedSprite2D # Por si tienes animación de abrirse
# Configura a qué nivel lleva esta puerta desde el Inspector
@export_file("*.tscn") var siguiente_nivel_ruta: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Conectamos la señal que avisa cuando CUALQUIER animación termina
	sprite.animation_finished.connect(_on_animation_finished)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Le preguntamos a Leo si tiene la llave exacta para ESTA puerta
		if body.tiene_llave(llave_requerida_id):
			print("¡Puerta abierta!")
			
			if consume_la_llave:
				body.gastar_llave(llave_requerida_id)
				
			_abrir_puerta()
		else:
			print("No tienes la llave correcta. Necesitas: ", llave_requerida_id)

func _abrir_puerta() -> void:
	# Aquí pones tu lógica (reproducir animación, desactivar colisiones, etc.)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("open"):
		sprite.play("open")
		# Desactivamos el área para que no se vuelva a activar de forma segura
		set_deferred("monitoring", false)
	else:
		# Si no hay animación, simplemente borramos la puerta del mapa
		queue_free()
		
# La función se ejecuta sola cuando el Sprite termina de animar
func _on_animation_finished() -> void:
	# Si la animación que acaba de terminar es la de abrirse...
	if sprite.animation == "open":
		_cambiar_de_nivel()

# La función segura para cambiar de escena
func _cambiar_de_nivel() -> void:
	if siguiente_nivel_ruta != "":
		print("Cargando siguiente nivel: ", siguiente_nivel_ruta)
		var error = get_tree().change_scene_to_file(siguiente_nivel_ruta)
		if error != OK:
			print("Error: No se pudo cargar la escena del siguiente nivel.")
	else:
		print("Advertencia: No configuraste la ruta del siguiente nivel en el Inspector.")
		queue_free() # Si no hay nivel, solo se borra la puerta
