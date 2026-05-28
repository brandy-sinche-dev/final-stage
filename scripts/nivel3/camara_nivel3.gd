extends Camera2D

@export var jugador_path: NodePath

@export var limite_izquierda: int = 0
@export var limite_derecha: int = 2600
@export var limite_arriba: int = -120
@export var limite_abajo: int = 480

@export var suavizado: bool = true
@export var velocidad_suavizado: float = 6.0
@export var offset_camara: Vector2 = Vector2(0, -20)

var jugador: Node2D

func _ready() -> void:
	if jugador_path != NodePath(""):
		jugador = get_node_or_null(jugador_path) as Node2D
	
	enabled = true
	make_current()
	
	limit_enabled = true
	limit_left = limite_izquierda
	limit_right = limite_derecha
	limit_top = limite_arriba
	limit_bottom = limite_abajo
	
	position_smoothing_enabled = suavizado
	position_smoothing_speed = velocidad_suavizado
	
	if jugador:
		global_position = jugador.global_position + offset_camara
	
	reset_smoothing()

func _physics_process(delta: float) -> void:
	if jugador == null:
		return
	
	var objetivo: Vector2 = jugador.global_position + offset_camara
	
	if suavizado:
		global_position = global_position.lerp(objetivo, min(1.0, velocidad_suavizado * delta))
	else:
		global_position = objetivo
