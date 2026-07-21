extends CanvasLayer 

# Desde el CanvasLayer entramos a HUD -> ContenedorVida -> barravida
@onready var barra_vida = $"HUD/ContenedorVida/BarraVida"
@onready var icono_llave = $"HUD/ContenedorLlave/TextureRect2"

@onready var contenedor_corazones = $"HUD/ContenedorCorazones"

var mi_personaje: CharacterBody2D = null

func _ready() -> void:
	print("--- ¡ALERTA! El HUD en CanvasLayer ha iniciado correctamente ---")
	
	if barra_vida == null:
		print("HUD ERROR: No se encontró el nodo 'BarraVida'. Revisa las mayúsculas en la ruta.")
		return
		
	# Agregamos el HUD a un grupo para que el personaje local lo encuentre fácil al recibir daño
	add_to_group("hud")
	
	# Le damos un pequeño momento a Godot (0.2 segundos) para que los jugadores de red terminen de nacer
	await get_tree().create_timer(0.2).timeout
	_vincular_jugador_local()
	if icono_llave:
		icono_llave.visible = false


func _vincular_jugador_local() -> void:
	var carpeta_jugadores = get_node_or_null("../Jugadores")

	# 1. BÚSQUEDA DEL PERSONAJE (Independiente del modo)
	if carpeta_jugadores == null:
		mi_personaje = get_tree().get_first_node_in_group("player")
	else:
		var mi_id = multiplayer.get_unique_id()
		mi_personaje = carpeta_jugadores.get_node_or_null(str(mi_id))

	# 2. CONFIGURACIÓN COMPARTIDA (Se ejecuta siempre que encontremos a Leo)
	if mi_personaje:
		# Configurar Vida
		barra_vida.max_value = mi_personaje.max_vida
		barra_vida.value = mi_personaje.vida_actual
		# 🌟 LÓGICA DE LLAVE (Ahora fuera de los IFs de red) 
		if mi_personaje.has_signal("llave_recolectada") and PlayerData.es_partida_local:
			# Nos aseguramos de no conectar dos veces si el HUD reintenta la conexión
			if not mi_personaje.llave_recolectada.is_connected(_on_llave_recibida):
				mi_personaje.llave_recolectada.connect(_on_llave_recibida) 
		# Verificación inicial
		if mi_personaje.tiene_llave("key_1") and PlayerData.es_partida_local:
			icono_llave.visible = true
		
		if contenedor_corazones:
			contenedor_corazones.visible = (PlayerData.es_partida_local)
		
		# 🌟 LÓGICA DE CORAZONES
		# Esperar un frame físico para que el personaje 
		# termine de cargar sus datos (corazones_restantes) desde el Autoload
		await get_tree().physics_frame
		
		# Ahora llamamos a la actualización con los datos ya cargados
		if contenedor_corazones and contenedor_corazones.visible:
			actualizar_corazones_visual(mi_personaje.corazones_restantes)
		print("HUD: Vinculado exitosamente a ", mi_personaje.name)
	else:
		null
		await get_tree().physics_frame
		_vincular_jugador_local()


func _on_llave_recibida(id: String) -> void:
		if icono_llave:
			icono_llave.visible = true
			print("HUD: Mostrando icono de llave: ", id)

func actualizar_vida(vida_nueva: int) -> void:
	if barra_vida:
		# Esto te dirá exactamente desde dónde viene la llamada
		print_debug("HUD: Actualizando a ", vida_nueva, " desde: ", get_stack()[1].function)
		barra_vida.value = vida_nueva
	if mi_personaje and contenedor_corazones and contenedor_corazones.visible:
		actualizar_corazones_visual(mi_personaje.corazones_restantes)

func actualizar_corazones_visual(cantidad: int) -> void:
	if contenedor_corazones:
		var index = 0
		for hijo in contenedor_corazones.get_children():
			# Solo actuamos si el nodo es un TextureRect (tu corazón)
			if hijo is TextureRect:
				hijo.visible = index < cantidad
				index += 1
