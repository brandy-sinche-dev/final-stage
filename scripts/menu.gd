extends Control

# Obtenemos las referencias de los contenedores
@onready var contenedor_principal: VBoxContainer = $ContenedorPrincipal
@onready var contenedor_niveles: VBoxContainer = $ContenedorNiveles
@onready var contenedor_cooperativo: VBoxContainer = $ContenedorCooperativo
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var music_fondo: AudioStreamPlayer = $MusicaFondo

# El campo de texto para la IP
@onready var input_ip: LineEdit = $ContenedorCooperativo/HBoxContainer/InputIP

# Configuracion para multijugador
const PORT = 1024
var ip_automatica_host: String = "127.0.0.1"

func _ready() -> void:
	contenedor_principal.visible = true
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = false
	music_fondo.play()
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	_conectar_botones(self)

# Detecta la IP real de tu máquina en la red local
func _obtener_ip_local_actual() -> String:
	var direcciones = IP.get_local_addresses()
	
	for ip in direcciones:
		# Filtramos: ignoramos IPv6 (las que tienen ':') y nos quedamos con las de red local comunes (192.168.x.x o 10.x.x.x)
		if not ":" in ip and (ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.")):
			return ip
			
	# Si no encuentra ninguna de red local activa, devuelve la IP de bucle por defecto
	return "127.0.0.1"

#-----------SONIDO DE BOTONES-----------------
func _reproducir_click() -> void:
	SoundManager.reproducir_click()
	
func _conectar_botones(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Button:
			hijo.pressed.connect(_reproducir_click)
		_conectar_botones(hijo)

#-----------CONFIGURACION DE BOTONES-----------------
func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel1/intro_historia.tscn")

func _on_niveles_pressed() -> void:
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
	contenedor_principal.visible = false
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = true

func _on_regresar_pressed() -> void:
	contenedor_principal.visible = true
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = false

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")

#--------CONFIGURACION DE BOTONES DEL MULTIJUGADOR------------

# Al presionar HOST: Creamos el servidor
func _on_crear_servidor_pressed() -> void:
	# Detectamos la IP automáticamente antes de abrir el server
	ip_automatica_host = _obtener_ip_local_actual()
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		print("No se pudo crear el servidor")
		return
	multiplayer.multiplayer_peer = peer
	
	print("==========================================")
	print("SERVIDOR INICIADO")
	print("Dile al Jugador 2 que se conecte a esta IP: ", ip_automatica_host)
	print("==========================================")
	
	print("Servidor abierto. Esperando al Jugador 2...")
	
	await get_tree().create_timer(0.15).timeout
	_cambiar_a_mapa_multijugador()

# 🌟 MODIFICADO: Al presionar JOIN/BUSCAR, lee lo que escribió el usuario
func _on_buscar_servidor_pressed() -> void:
	# .strip_edges() elimina espacios en blanco accidentales al inicio o final
	var ip_destino: String = input_ip.text.strip_edges()
	
	# Validación: Si el jugador no escribió nada, usamos la IP por defecto de respaldo
	if ip_destino == "":
		ip_destino = _obtener_ip_local_actual()
		print("Campo vacío. Intentando conectar a la IP por defecto: ", ip_destino)
	else:
		print("Intentando conectar a la IP ingresada: ", ip_destino)
		
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_destino, PORT)
	if error != OK:
		print("No se pudo intentar la conexión")
		return
	multiplayer.multiplayer_peer = peer
	print("Conectándose al Host...")

func _on_player_connected(id: int) -> void:
	print("¡Jugador conectado con ID de red: ", id)
	
	if not multiplayer.is_server():
		print("¡Conexión exitosa! Cargando el mapa para el Cliente...")
		_cambiar_a_mapa_multijugador()

func _on_player_disconnected(id: int) -> void:
	print("Jugador desconectado: ", id)

func _cambiar_a_mapa_multijugador() -> void:
	get_tree().change_scene_to_file("res://scenes/cooperativo/mapa_cooperativo.tscn")
