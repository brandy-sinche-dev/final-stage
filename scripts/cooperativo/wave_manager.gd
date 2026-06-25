extends Node

# Precarga de enemigos
const ENEMIGO_LVL1 = preload("res://scenes/nivel1/centinela_oseo.tscn")
const ENEMIGO_LVL2 = preload("res://scenes/nivel2/enemigo_n2.tscn")
const ENEMIGO_LVL3 = preload("res://scenes/nivel3/eco_sombra.tscn")

@onready var spawn_points = $"../SpawnPoints".get_children()
@onready var enemies_container = $"../EnemiesContainer"
@onready var wave_timer = $Timer

# 🌟 NUEVAS REFERENCIAS: Nodos de la interfaz en pantalla
# Asegúrate de que los nombres coincidan exactamente con tu árbol de escenas
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
	wave_timer.timeout.connect(_iniciar_siguiente_ola)
	wave_timer.start(3.0)
	print("--- MODO COOPERATIVO: Preparando Oleadas ---")
	
	# Inicializamos la interfaz en limpio antes de arrancar
	_actualizar_interfaz_pantalla()

func _iniciar_siguiente_ola() -> void:
	wave_timer.stop()
	ola_actual += 1
	
	if not configuracion_olas.has(ola_actual):
		print("¡Felicidades! Han completado todas las oleadas.")
		label_ola.text = "¡VICTORIA!"
		label_enemigos.text = "Felicidades"
		return
		
	print("====== INICIANDO OLA: ", ola_actual, " ======")
	var datos_ola = configuracion_olas[ola_actual]
	
	if spawn_points.is_empty():
		print("❌ ERROR: No se encontraron nodos hijos en SpawnPoints.")
		return
	
	# Actualizamos el número de ola en pantalla
	_actualizar_interfaz_pantalla()
	
	for i in range(datos_ola["cantidad"]):
		var lista_enemigos: Array = datos_ola["enemigos"]
		var escena_enemigo = lista_enemigos.pick_random()
		
		if escena_enemigo == null:
			continue

		var indices_spawn: Array = datos_ola["puntos_spawn"]
		var indice_elegido = indices_spawn.pick_random()
		var punto_spawn: Marker2D = spawn_points[indice_elegido]
		
		var clon_enemigo = escena_enemigo.instantiate()
		
		enemies_container.add_child(clon_enemigo)
		clon_enemigo.global_position = punto_spawn.global_position
		
		if "z_index" in clon_enemigo:
			clon_enemigo.z_index = 10 
		
		if "visible" in clon_enemigo:
			clon_enemigo.visible = true
		
		clon_enemigo.tree_exited.connect(_on_enemigo_eliminado)
		
		enemigos_vivos += 1
		# Actualizamos los enemigos vivos en pantalla a medida que van naciendo
		_actualizar_interfaz_pantalla()
		
		await get_tree().create_timer(0.1).timeout

func _on_enemigo_eliminado() -> void:
	enemigos_vivos -= 1
	print("Enemigo derrotado. Vivos restantes: ", enemigos_vivos)
	
	if not is_inside_tree() or wave_timer == null or not wave_timer.is_inside_tree():
		return

	# Actualizamos la interfaz porque un enemigo murió
	_actualizar_interfaz_pantalla()

	if enemigos_vivos <= 0:
		print("¡Oleada ", ola_actual, " limpia!")
		label_enemigos.text = "¡Oleada limpia!"
		wave_timer.start(5.0)

# 🌟 NUEVA FUNCIÓN: Refresca el texto visual del juego de forma dinámica
func _actualizar_interfaz_pantalla() -> void:
	if label_ola != null:
		label_ola.text = "Ola: " + str(ola_actual)
		
	if label_enemigos != null:
		if ola_actual == 0:
			label_enemigos.text = "Preparándose..."
		else:
			label_enemigos.text = "Enemigos: " + str(enemigos_vivos)
