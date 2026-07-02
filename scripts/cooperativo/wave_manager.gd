extends Node

# Precarga de enemigos
const ENEMIGO_LVL1 = preload("res://scenes/nivel1/centinela_oseo.tscn")
const ENEMIGO_LVL2 = preload("res://scenes/nivel2/enemigo_n2.tscn")
const ENEMIGO_LVL3 = preload("res://scenes/nivel3/eco_sombra.tscn")

@onready var spawn_points = $"../SpawnPoints".get_children()
@onready var enemies_container = $"../EnemiesContainer"
@onready var wave_timer = $Timer

# Referencias de la interfaz en pantalla
@onready var label_ola = $"../CanvasLayer_HUD/Control_Olas/Label_Ola"
@onready var label_enemigos = $"../CanvasLayer_HUD/Control_Olas/Label_Enemigos"

# Configuración del flujo de oleadas
var ola_actual: int = 0
var enemigos_vivos: int = 0

# Definición de las olas
var configuracion_olas: Dictionary = {
	1: {
		"enemigos": [ENEMIGO_LVL1],
		"cantidad": 4,
		"puntos_spawn": [0, 1]
	},
	2: {
		"enemigos": [ENEMIGO_LVL1, ENEMIGO_LVL2],
		"cantidad": 6,
		"puntos_spawn": [0, 1, 2]
	},
	3: {
		"enemigos": [ENEMIGO_LVL2, ENEMIGO_LVL3],
		"cantidad": 8,
		"puntos_spawn": [1, 2]
	}
}

func _ready() -> void:
	# 🌟 NUEVO: Si soy un Cliente (Jugador 2), apago este script.
	# El cliente no necesita temporizadores ni calcular qué enemigo va a salir.
	if not multiplayer.is_server():
		wave_timer.stop() # Apagamos su timer local
		print("--- CLIENTE: Esperando órdenes de oleadas del Servidor ---")
		_actualizar_interfaz_pantalla()
		return
		
	# Todo lo de abajo solo lo hace el SERVIDOR (Jugador 1)
	wave_timer.timeout.connect(_iniciar_siguiente_ola)
	wave_timer.start(3.0)
	print("--- SERVIDOR: Controlando el flujo de Oleadas ---")
	_actualizar_interfaz_pantalla()


func _iniciar_siguiente_ola() -> void:
	# Como pusimos el bloqueo en el _ready, sabemos que aquí SOLO entra el Servidor
	wave_timer.stop()
	ola_actual += 1
	
	if not configuracion_olas.has(ola_actual):
		# 🌟 NUEVO: El servidor le avisa al cliente que ganaron
		_notificar_victoria_en_red.rpc()
		return
		
	var datos_ola = configuracion_olas[ola_actual]
	if spawn_points.is_empty(): return
	
	enemigos_vivos = datos_ola["cantidad"]
	
	# 🌟 NUEVO: El servidor le ordena al cliente actualizar sus textos en pantalla
	_sincronizar_hud_cliente.rpc(ola_actual, enemigos_vivos)
	
	for i in range(datos_ola["cantidad"]):
		var lista_enemigos: Array = datos_ola["enemigos"]
		var escena_enemigo = lista_enemigos.pick_random()
		if escena_enemigo == null:
			enemigos_vivos -= 1
			_sincronizar_hud_cliente.rpc(ola_actual, enemigos_vivos)
			continue

		var indices_spawn: Array = datos_ola["puntos_spawn"]
		var indice_elegido = indices_spawn.pick_random()
		var punto_spawn: Marker2D = spawn_points[indice_elegido]
		
		var clon_enemigo = escena_enemigo.instantiate()
		
		# 🌟 REGLA DE ORO: Al llamarse por su ID de red o un nombre único, 
		# el Spawner sabrá cómo replicarlo exactamente igual en el cliente.
		clon_enemigo.name = "Enemigo_" + str(ola_actual) + "_" + str(i)
		clon_enemigo.tree_exited.connect(_on_enemigo_eliminado)
		
		enemies_container.add_child(clon_enemigo)
		clon_enemigo.global_position = punto_spawn.global_position
		
		await get_tree().create_timer(0.1).timeout


func _on_enemigo_eliminado() -> void:
	if not is_inside_tree() or wave_timer == null: return

	enemigos_vivos -= 1
	print("Enemigo derrotado en Servidor. Vivos restantes: ", enemigos_vivos)
	
	# El servidor actualiza al cliente cada vez que muere un monstruo
	_sincronizar_hud_cliente.rpc(ola_actual, enemigos_vivos)

	if enemigos_vivos <= 0:
		print("¡Oleada ", ola_actual, " limpia!")
		wave_timer.start(5.0)


# 🌟 NUEVOS RPCs: Funciones mágicas para controlar la pantalla del Jugador 2 de forma remota

@rpc("any_peer", "call_local", "reliable")
func _sincronizar_hud_cliente(ola: int, vivos: int) -> void:
	# Esto se ejecuta en ambas PCs para que los textos apunten al mismo número
	ola_actual = ola
	enemigos_vivos = vivos
	if label_ola: label_ola.text = "Ola: " + str(ola)
	if label_enemigos: label_enemigos.text = "Enemigos: " + str(vivos)

@rpc("any_peer", "call_local", "reliable")
func _notificar_victoria_en_red() -> void:
	if label_ola: label_ola.text = "¡VICTORIA!"
	if label_enemigos: label_enemigos.text = "Felicidades"
func _actualizar_interfaz_pantalla() -> void:
	# Evita crasheos si la UI se destruye antes que el spawner
	if not is_inside_tree(): return 
	
	if label_ola != null:
		label_ola.text = "Ola: " + str(ola_actual)
		
	if label_enemigos != null:
		if ola_actual == 0:
			label_enemigos.text = "Preparándose..."
		else:
			label_enemigos.text = "Enemigos: " + str(enemigos_vivos)
