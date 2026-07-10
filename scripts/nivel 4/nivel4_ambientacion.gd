extends Node2D

const RAYO_SCENE: PackedScene = preload("res://scenes/nivel3/rayo.tscn")

@export var ancho_mundo: float = 2450.0

var tiempo := 0.0

func _ready() -> void:
	randomize()
	_crear_tinte_ambiente()
	_crear_particulas_cueva()
	_crear_rayos_de_fondo()
	call_deferred("_crear_aura_jefe")
	call_deferred("_resaltar_obeliscos")


func _process(delta: float) -> void:
	tiempo += delta

func _crear_tinte_ambiente() -> void:
	var sombra := ColorRect.new()
	sombra.name = "TinteAmbiente"
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sombra.position = Vector2(0, -330)
	sombra.size = Vector2(ancho_mundo, 690)
	sombra.color = Color(0.045, 0.0, 0.075, 0.16)
	sombra.z_index = 10
	add_child(sombra)

	var vineta_superior := ColorRect.new()
	vineta_superior.name = "VinetaSuperior"
	vineta_superior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vineta_superior.position = Vector2(0, -330)
	vineta_superior.size = Vector2(ancho_mundo, 140)
	vineta_superior.color = Color(0.02, 0.0, 0.035, 0.24)
	vineta_superior.z_index = 11
	add_child(vineta_superior)

func _crear_particulas_cueva() -> void:
	var particulas := CPUParticles2D.new()
	particulas.name = "ParticulasCueva"
	particulas.position = Vector2(ancho_mundo * 0.5, 15)
	particulas.z_index = 20
	particulas.amount = 90
	particulas.lifetime = 5.0
	particulas.preprocess = 5.0
	particulas.emitting = true
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas.emission_rect_extents = Vector2(ancho_mundo * 0.5, 230)
	particulas.direction = Vector2(-0.2, -1.0)
	particulas.spread = 95.0
	particulas.gravity = Vector2(0, -4)
	particulas.initial_velocity_min = 8.0
	particulas.initial_velocity_max = 24.0
	particulas.scale_amount_min = 0.25
	particulas.scale_amount_max = 0.75
	particulas.color = Color(0.45, 0.22, 1.0, 0.34)
	add_child(particulas)

func _crear_rayos_de_fondo() -> void:
	var posiciones := [
		Vector2(200, -30),
		Vector2(410, -20),
		Vector2(750, -50),
		Vector2(1120, -45),
		Vector2(1500, -25),
		Vector2(1980, -32),
		Vector2(2200, -40)
	]

	for posicion in posiciones:
		var rayo := RAYO_SCENE.instantiate() as Node2D
		rayo.position = posicion
		rayo.scale = Vector2(randf_range(1.15, 1.65), randf_range(0.9, 1.25))
		rayo.modulate = Color(0.55, 0.18, 1.0, 0.24)
		rayo.z_index = 20
		add_child(rayo)

func _crear_aura_jefe() -> void:
	var jefe := get_node_or_null("JefeFinal") as Node2D
	if jefe == null:
		return

	var aura := CPUParticles2D.new()
	aura.name = "AuraJefe"
	aura.position = Vector2(0, -48)
	aura.z_index = 20
	aura.amount = 45
	aura.lifetime = 1.3
	aura.preprocess = 1.3
	aura.emitting = true
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 34.0
	aura.direction = Vector2(0, -1)
	aura.spread = 80.0
	aura.gravity = Vector2(0, -12)
	aura.initial_velocity_min = 8.0
	aura.initial_velocity_max = 32.0
	aura.scale_amount_min = 0.45
	aura.scale_amount_max = 1.0
	aura.color = Color(0.85, 0.12, 0.95, 0.48)
	jefe.add_child(aura)

func _resaltar_obeliscos() -> void:
	for nodo in get_children():
		if not nodo.name.begins_with("Obelisco"):
			continue

		var brillo := CPUParticles2D.new()
		brillo.name = "BrilloObelisco"
		brillo.position = Vector2(0, -54)
		brillo.z_index = 20
		brillo.amount = 18
		brillo.lifetime = 1.4
		brillo.preprocess = 1.4
		brillo.emitting = true
		brillo.direction = Vector2(0, -1)
		brillo.spread = 45.0
		brillo.gravity = Vector2(0, -8)
		brillo.initial_velocity_min = 6.0
		brillo.initial_velocity_max = 18.0
		brillo.scale_amount_min = 0.25
		brillo.scale_amount_max = 0.55
		brillo.color = Color(0.62, 0.38, 1.0, 0.5)
		nodo.add_child(brillo)
