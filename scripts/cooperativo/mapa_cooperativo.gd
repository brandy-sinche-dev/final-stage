extends Node2D


func _ready() -> void:
	# Solo el Servidor controla el nacimiento inicial
	if not multiplayer.is_server():
		return
		
	# Conectamos la señal nativa. Cuando un peer se conecte de verdad,
	# llamamos a la función que lo creará en el servidor.
	multiplayer.peer_connected.connect(_crear_jugador_en_servidor)
	
	# Creamos al Host (Jugador 1)
	_crear_jugador_en_servidor(1)

func _crear_jugador_en_servidor(id: int) -> void:
	var contenedor = get_node_or_null("Jugadores")
	if not contenedor or contenedor.has_node(str(id)):
		return
		
	var escena_jugador = load("res://scenes/leo.tscn")
	var nuevo_leo = escena_jugador.instantiate()
	nuevo_leo.name = str(id)
	
	# 🌟 NO MODIFICAMOS NINGUNA POSICIÓN AQUÍ.
	# Dejamos que nazca con la posición exacta que tiene guardada el archivo .tscn
	contenedor.add_child(nuevo_leo)
	print("Servidor creó al jugador ", id, " usando su posición nativa.")
