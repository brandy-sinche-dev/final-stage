extends Node2D

@export var escena_hud: PackedScene 

@onready var contenedor_jugadores = $Jugadores
@onready var label_ip: Label = $CanvasLayer_HUD/Control_Olas/Label_ip

func _ready() -> void:
	# CONEXIÓN PARA EL HUD LOCAL:
	# Cada vez que un personaje aparezca en el contenedor (vía red o local), 
	# esta función revisará si nos pertenece para crearle su HUD.
	if contenedor_jugadores:
		contenedor_jugadores.child_entered_tree.connect(_on_jugador_entró_al_contenedor)

	# -------------------------------------------------------------
	# Tu lógica original del Servidor se queda exactamente igual:
	if not multiplayer.is_server():
		return
	if multiplayer.is_server():
		label_ip.text = "IP: " + _obtener_ip_local_actual()
	else:
		# Si es el cliente, podemos ocultarlo o poner un mensaje
		label_ip.text = "Esperando al Host..."
		
	multiplayer.peer_connected.connect(_crear_jugador_en_servidor)
	_crear_jugador_en_servidor(1)

func _obtener_ip_local_actual() -> String:
	var direcciones = IP.get_local_addresses()
	for ip in direcciones:
		if not ":" in ip and (ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.")):
			return ip
	return "127.0.0.1"
	
func _crear_jugador_en_servidor(id: int) -> void:
	var contenedor = get_node_or_null("Jugadores")
	if not contenedor or contenedor.has_node(str(id)):
		return
		
	var escena_jugador = load("res://scenes/leo.tscn")
	var nuevo_leo = escena_jugador.instantiate()
	nuevo_leo.name = str(id)
	
	# Restablecemos sus estados iniciales directamente al instanciarlo
	nuevo_leo.vida_actual = nuevo_leo.max_vida
	nuevo_leo.esta_muerto = false
	nuevo_leo.esta_herido = false
	
	contenedor.add_child(nuevo_leo)
	print("Servidor creó al jugador ", id, " usando su posición nativa.")


#Se ejecuta en Host y Cliente de forma independiente
func _on_jugador_entró_al_contenedor(nodo: Node) -> void:
	await get_tree().process_frame
	
	if nodo is CharacterBody2D:
		# Verificamos si el personaje que acaba de aparecer es el que controla ESTA computadora
		if nodo.is_multiplayer_authority():
			if escena_hud:
				var nuevo_hud = escena_hud.instantiate()
				add_child(nuevo_hud)
				
				if nuevo_hud.has_method("vincular_a_personaje"):
					nuevo_hud.vincular_a_personaje(nodo)
					
				print("MAPA LOCAL: Personaje detectado. HUD generado y vinculado para el ID: ", multiplayer.get_unique_id())
			else:
				print("MAPA ERROR: No has asignado la escena_hud en el Inspector del mapa.")


# =============================================================================
# LÓGICA DE CONTROL GLOBAL DE RECONEXIÓN, MUERTE Y GAME OVER (SOLO SERVIDOR)
# =============================================================================

func _ejecutar_respawn_en_servidor(id_jugador: int) -> void:
	if not multiplayer.is_server():
		return

	# 1. Contamos cuántos jugadores siguen de pie en la partida actual
	var jugadores = get_tree().get_nodes_in_group("player")
	var jugadores_vivos = 0
	
	for j in jugadores:
		if j and not j.esta_muerto:
			jugadores_vivos += 1
			
	print("Servidor detecta jugadores vivos restantes: ", jugadores_vivos)
	
	# 2. CASO A: Aún queda un compañero vivo (Entra modo espectador local)
	if jugadores_vivos > 0:
		print("El jugador ", id_jugador, " se queda espectando hasta que caiga el equipo.")
		return # Detiene el nacimiento. No se le crea cuerpo nuevo todavía.

	# 3. CASO B: GAME OVER (Todos murieron) -> Reinicio Absoluto
	print("GAME OVER: Todos han muerto. Limpiando sala y reiniciando oleada...")
	_reiniciar_logica_de_juego_local()


func _reiniciar_logica_de_juego_local() -> void:
	# A) Borramos los enemigos actuales en pantalla (Pon el nombre real de tu grupo de enemigos)
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if is_instance_valid(e):
			e.queue_free()
			
	# B) Borramos los cuerpos viejos y huerfanos de todos los jugadores
	if contenedor_jugadores:
		for hijo in contenedor_jugadores.get_children():
			hijo.queue_free()
			
	# Esperamos un frame del ciclo para que Godot limpie los nodos de la memoria correctamente
	await get_tree().process_frame
	
	# C) Volvemos a instanciar a los jugadores que siguen conectados a la sesión
	if multiplayer.multiplayer_peer != null:
		var pares_conectados = multiplayer.get_peers()
		
		# Revivimos al Host principal (ID 1)
		_crear_jugador_en_servidor(1)
		
		# Revivimos a todos los clientes que estén conectados en la partida
		for peer_id in pares_conectados:
			_crear_jugador_en_servidor(peer_id)
	else:
		# Si estás probando tú solo en offline
		_crear_jugador_en_servidor(1)
		
	# D) Reiniciamos las oleadas o el generador de enemigos de tu mapa
	# Modifica "reiniciar_oleada_actual" si tu función se llama de otra forma en este script
	if has_method("reiniciar_oleada_actual"):
		call_deferred("reiniciar_oleada_actual")
