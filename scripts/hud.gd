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
	# 1. Si estás jugando solo offline
	if multiplayer.multiplayer_peer == null:
		var leo = get_tree().get_first_node_in_group("player")
		if leo:
			mi_personaje = leo
			barra_vida.max_value = mi_personaje.max_vida
			barra_vida.value = mi_personaje.vida_actual
			print("HUD (Offline): Conectado a Leo. Vida: ", barra_vida.value)
		return

	# 2. MODO MULTIJUGADOR COOPERATIVO
	# Obtenemos el ID de red único de ESTA computadora local
	var mi_id = multiplayer.get_unique_id()
	
	# Buscamos en el contenedor "Jugadores" al personaje que se llame igual a nuestro ID
	# (Recuerda que en tu script de mapa los instancias como: nuevo_leo.name = str(id))
	mi_personaje = get_node_or_null("../Jugadores/" + str(mi_id))
	
	if mi_personaje:
		barra_vida.max_value = mi_personaje.max_vida
		barra_vida.value = mi_personaje.vida_actual
		print("HUD (Online): Conectado con éxito al personaje local con ID de red: ", mi_id)
	else:
		print("HUD ADVERTENCIA: Aún no encuentro al jugador local '", mi_id, "'. Reintentando...")
		# Si por el lag de red aún no ha nacido, esperamos un frame y volvemos a buscar
		await get_tree().physics_frame
		_vincular_jugador_local()


func actualizar_vida(vida_nueva: int) -> void:
	if barra_vida:
		print("HUD: Actualizando barra visual a: ", vida_nueva)
		barra_vida.value = vida_nueva
