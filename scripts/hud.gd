extends CanvasLayer 

# Desde el CanvasLayer entramos a HUD -> ContenedorVida -> barravida
@onready var barra_vida = $"HUD/ContenedorVida/BarraVida"

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


func _vincular_jugador_local() -> void:
	# 🌟 LA CLAVE: Buscamos si existe la carpeta de red en la escena actual
	var carpeta_jugadores = get_node_or_null("../Jugadores")

	# 1. MODO SOLITARIO (Si la carpeta "Jugadores" NO existe en el mapa)
	if carpeta_jugadores == null:
		# Intento A: Buscar por grupo "player"
		var leo = get_tree().get_first_node_in_group("player")
		
		# Intento B: Buscar cualquier CharacterBody2D en la escena
		if leo == null:
			var todos_los_cb2d = get_tree().get_root().find_children("*", "CharacterBody2D", true, false)
			if todos_los_cb2d.size() > 0:
				leo = todos_los_cb2d[0]
		
		if leo:
			mi_personaje = leo
			barra_vida.max_value = mi_personaje.max_vida
			barra_vida.value = mi_personaje.vida_actual
			print("HUD (Solitario Forzado): Conectado con éxito a: ", mi_personaje.name)
		else:
			print("HUD ERROR (Solitario): No se encontró ningún CharacterBody2D.")
		return # 🛑 CORTA AQUÍ. Impide por completo que entre al bucle del jugador '1'

	# =========================================================================
	# 2. MODO MULTIJUGADOR COOPERATIVO (100% ORIGINAL - INTACTO)
	# =========================================================================
	var mi_id = multiplayer.get_unique_id()
	
	# Usamos la variable que ya encontramos arriba de forma segura
	mi_personaje = carpeta_jugadores.get_node_or_null(str(mi_id))
	
	if mi_personaje:
		barra_vida.max_value = mi_personaje.max_vida
		barra_vida.value = mi_personaje.vida_actual
		print("HUD (Online): Conectado con éxito al personaje local con ID de red: ", mi_id)
	else:
		print("HUD ADVERTENCIA: Aún no encuentro al jugador local '", mi_id, "'. Reintentando...")
		await get_tree().physics_frame
		_vincular_jugador_local()	


func actualizar_vida(vida_nueva: int) -> void:
	if barra_vida:
		# Esto te dirá exactamente desde dónde viene la llamada
		print_debug("HUD: Actualizando a ", vida_nueva, " desde: ", get_stack()[1].function)
		barra_vida.value = vida_nueva
