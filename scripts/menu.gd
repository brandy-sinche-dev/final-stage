extends Control

# Obtenemos las referencias de los contenedores
@onready var contenedor_principal: VBoxContainer = $ContenedorPrincipal
@onready var contenedor_niveles: VBoxContainer = $ContenedorNiveles
@onready var contenedor_cooperativo: VBoxContainer = $ContenedorCooperativo
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var music_fondo: AudioStreamPlayer = $Musica_fondo # Ajustado a nombre correcto
@onready var fade_screen: ColorRect = $CanvasLayer/Transicion
# El campo de texto para la IP
@onready var input_ip: LineEdit = $ContenedorCooperativo/HBoxContainer/InputIP
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Configuracion para multijugador
const PORT = 1024
var ip_automatica_host: String = "127.0.0.1"

func _ready() -> void:
	fade_screen.modulate.a = 0.0
	contenedor_principal.visible = true
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = false
	music_fondo.play()
	
	$AnimationPlayer2.play("intro")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	_conectar_botones(self)

# Detecta la IP real de tu máquina en la red local (Mantenemos tu lógica maestra)
func _obtener_ip_local_actual() -> String:
	var direcciones = IP.get_local_addresses()
	for ip in direcciones:
		if not ":" in ip and (ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.")):
			return ip
	return "127.0.0.1"

#-----------SONIDO DE BOTONES (Estructura limpia)-----------------
func _reproducir_click() -> void:
	SoundManager.reproducir_click()
	
func _conectar_botones(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Button:
			hijo.pressed.connect(_reproducir_click)
		_conectar_botones(hijo)

func _cambiar_escena_con_fade(ruta_escena: String) -> void:
	# Bloqueamos el mouse para que no se puedan presionar botones mientras se oscurece la pantalla
	fade_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	# Reproduce la animación que creaste en el AnimationPlayer
	animation_player.play("fade_out")
	# Espera a que termine de ponerse negro antes de cambiar
	await animation_player.animation_finished
	# Realiza el cambio de escena
	get_tree().change_scene_to_file(ruta_escena)

#-----------CONFIGURACION DE BOTONES-----------------
func _on_play_pressed():
	_cambiar_escena_con_fade("res://scenes/nivel1/intro_historia.tscn")

func _on_niveles_pressed() -> void:
	contenedor_principal.visible = false
	contenedor_cooperativo.visible = false
	contenedor_niveles.visible = true
	
	$AnimationPlayer2.play("intro_op")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_nivel_1_pressed() -> void:
	_cambiar_escena_con_fade("res://scenes/nivel1/nivel_1.tscn")

func _on_nivel_2_pressed() -> void:
	_cambiar_escena_con_fade("res://scenes/nivel2/nivel_2.tscn")

func _on_nivel_3_pressed() -> void:
	_cambiar_escena_con_fade("res://scenes/nivel3/nivel_3.tscn")

func _on_nivel_4_pressed() -> void:
	_cambiar_escena_con_fade("res://scenes/nivel 4/nivel 4.tscn")

func _on_cooperativo_pressed() -> void:
	contenedor_principal.visible = false
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = true
	
	$AnimationPlayer2.play("intro_coop")

func _on_regresar_pressed() -> void:
	contenedor_principal.visible = true
	contenedor_niveles.visible = false
	contenedor_cooperativo.visible = false
	
	$AnimationPlayer2.play("intro")

func _on_tutorial_pressed() -> void:
	_cambiar_escena_con_fade("res://scenes/tutorial/tutorial.tscn")

#--------CONFIGURACION DE BOTONES DEL MULTIJUGADOR------------

# Al presionar HOST: Creamos el servidor
func _on_crear_servidor_pressed() -> void:
	PlayerData.es_partida_local = false
	await _hacer_fade_out()
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
	PlayerData.es_partida_local = false
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
	get_tree().call_deferred("change_scene_to_file", "res://scenes/cooperativo/mapa_cooperativo.tscn")

# Nueva función para manejar el efecto
func _hacer_fade_out():
	var tween = create_tween()
	# Animamos el canal alpha (a) del color del rect de 0 a 1
	tween.tween_property(fade_screen, "modulate:a", 1.0, 0.5) 
	await tween.finished
	



	
