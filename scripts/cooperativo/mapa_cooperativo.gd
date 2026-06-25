extends Node2D

# Cargamos la escena de Leo en memoria
var escena_jugador = preload("res://scenes/leo.tscn") # Asegúrate de que esta sea tu ruta real

func _ready() -> void:
	# Solo el Servidor (Host) tiene la autoridad de instanciar cuerpos físicos en red
	if not multiplayer.is_server():
		return
		
	# 1. PASO CLAVE: Primero conectamos la señal para futuros peers que se unan más tarde
	multiplayer.peer_connected.connect(_instanciar_jugador)
	
	# 2. PASO DE SEGURIDAD: Si algún cliente ya se conectó mientras cargábamos, lo instanciamos de una vez
	for id in multiplayer.get_peers():
		_instanciar_jugador(id)
		
	# 3. TRUCO DE INGENIERÍA: Esperamos a que las escenas se estabilicen un frame antes de crear al Host
	await get_tree().physics_frame
	
	# 4. Creamos al Jugador 1 (El Host siempre tiene el ID 1)
	_instanciar_jugador(1)


func _instanciar_jugador(id: int) -> void:
	if has_node(str(id)):
		return
		
	var nuevo_leo = escena_jugador.instantiate()
	
	# REGLA DE ORO: El nombre DEBE ser el ID. 
	# Al llamarse igual que el ID, el script interno sabrá qué autoridad ponerse.
	nuevo_leo.name = str(id)
	
	nuevo_leo.global_position = Vector2(100, 200)
	
	# Lo añadimos directamente. La autoridad se manejará sola por dentro.
	add_child(nuevo_leo)
	print("¡Nodo creado en el mapa con nombre/ID: ", id, "!")
