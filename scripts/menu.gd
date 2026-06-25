extends Control

# Obtenemos las referencias de los dos contenedores
@onready var contenedor_principal: VBoxContainer = $ContenedorPrincipal
@onready var contenedor_niveles: VBoxContainer = $ContenedorNiveles
@onready var contenedor_cooperativo: VBoxContainer = $ContenedorCooperativo

# Configuracion para multijugador
const PORT = 1024
const DEFAULT_IP = "192.168.18.30" # CREAR UN HOTSPOT CON LA PC DE LA UNI Y USAR LA IP DE LA OTRA PC

func _ready() -> void:
	# Nos aseguramos de que al arrancar el juego, los niveles estén ocultos
	contenedor_principal.visible = true
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = false
	
	# Conectamos las señales nativas de red de Godot
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)




#-----------CONFIGURACION DE BOTONES-----------------
func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel1/intro_historia.tscn")


func _on_niveles_pressed() -> void:
	# Ocultamos el menú principal y mostramos los niveles
	contenedor_principal.visible = false
	contenedor_cooperativo.visible = false
	contenedor_niveles.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_nivel_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel1/nivel_1.tscn")


func _on_nivel_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel2/nivel_2.tscn")


func _on_nivel_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel3/nivel_3.tscn")


func _on_nivel_4_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel 4/nivel 4.tscn")

func _on_cooperativo_pressed() -> void:
	# Ocultamos el menú principal y mostramos los niveles
	contenedor_principal.visible = false
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = true


func _on_regresar_pressed() -> void:
	# Ocultamos los niveles y mostramos el menu principal
	contenedor_principal.visible = true
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = false


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")

	
	

#--------CONFIGURACION DE BOTONES DEL MULTIJUGADOR------------

# Al presionar HOST: Creamos el servidor
func _on_crear_servidor_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		print("No se pudo crear el servidor")
		return
	multiplayer.multiplayer_peer = peer
	print("Servidor abierto. Esperando al Jugador 2...")
	
	# El Host se va directo al mapa a preparar las cosas
	_cambiar_a_mapa_multijugador()

# Al presionar JOIN: Nos conectamos al servidor
func _on_buscar_servidor_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_IP, PORT)
	if error != OK:
		print("No se pudo intentar la conexión")
		return
	multiplayer.multiplayer_peer = peer
	print("Conectándose al Host...")

func _on_player_connected(id: int) -> void:
	print("¡Jugador conectado con ID de red: ", id)
	
	# 🌟 LA CORRECCIÓN CLAVE:
	# Si yo soy el Cliente (es decir, NO soy el servidor) y detecto que me conecté,
	# me obligo a mí mismo a cargar la escena del mapa para alcanzar al Host.
	if not multiplayer.is_server():
		print("¡Conexión exitosa! Cargando el mapa para el Cliente...")
		_cambiar_a_mapa_multijugador()

func _on_player_disconnected(id: int) -> void:
	print("Jugador desconectado: ", id)

func _cambiar_a_mapa_multijugador() -> void:
	# Asegúrate de que esta ruta sea exactamente la de tu mapa de pruebas actual
	get_tree().change_scene_to_file("res://scenes/cooperativo/mapa_cooperativo.tscn")
