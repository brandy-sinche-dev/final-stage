extends CharacterBody2D

@export var velocidad: float = 90.0
@export var velocidad_regreso: float = 75.0
@export var max_vida: int = 60
@export var dano_contacto: int = 18
@export var distancia_deteccion: float = 360.0
@export var distancia_ataque: float = 35.0
@export var retardo_imitacion: float = 0.75
@export var knockback_fuerza: float = 160.0
@export var cooldown_ataque: float = 0.85
@export var duracion_ataque_segura: float = 0.65
@export var duracion_danio_segura: float = 0.45
@export var tolerancia_inicio: float = 10.0

# Zona de la plataforma
@export var zona_plataforma_path: NodePath
@export var regresar_si_leo_sale_zona: bool = true

var vida_actual: int
var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var posicion_inicio: Vector2

enum Estados { ESPERANDO, IMITANDO, REGRESANDO, ATACANDO, HERIDO, MUERTO }
var estado_actual = Estados.ESPERANDO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $Area2D
@onready var hitbox_ataque: CollisionShape2D = $Area2D/CollisionShape2D
@onready var detector_suelo: RayCast2D = get_node_or_null("DetectorSuelo")

var zona_plataforma: Area2D = null
var leo_en_zona_plataforma: bool = true

var historial_posiciones: Array = []
var tiempo_estela: float = 0.0
var puede_atacar: bool = true
var area_ataque_x_base: float = 45.0

# Define qué llave suelta este enemigo en el Inspector
@export var llave_a_soltar: String = "key_1"
# Variable para recordar a quién estamos imitando actualmente
var jugador_objetivo: CharacterBody2D = null

func _ready() -> void:
	vida_actual = max_vida
	posicion_inicio = global_position
	
	collision_layer = 4
	collision_mask = 1
	
	if area_ataque:
		area_ataque.collision_layer = 0
		area_ataque.collision_mask = 2
		if abs(area_ataque.position.x) > 0:
			area_ataque_x_base = abs(area_ataque.position.x)
		else:
			area_ataque.position.x = area_ataque_x_base
	
	if hitbox_ataque:
		hitbox_ataque.disabled = true
	
	if detector_suelo:
		detector_suelo.enabled = true
		detector_suelo.collision_mask = 1
		detector_suelo.target_position = Vector2(45, 90)
	
	if zona_plataforma_path != NodePath(""):
		zona_plataforma = get_node_or_null(zona_plataforma_path) as Area2D
	
	if zona_plataforma:
		leo_en_zona_plataforma = false
		zona_plataforma.monitoring = true
		zona_plataforma.monitorable = true
		zona_plataforma.collision_layer = 0
		zona_plataforma.collision_mask = 2
		zona_plataforma.body_entered.connect(_on_zona_plataforma_body_entered)
		zona_plataforma.body_exited.connect(_on_zona_plataforma_body_exited)
		call_deferred("_actualizar_estado_inicial_zona")
	else:
		leo_en_zona_plataforma = true
	
	sprite.modulate = Color(1, 1, 1, 1)
	_reproducir("walk")

func _actualizar_estado_inicial_zona() -> void:
	if zona_plataforma == null:
		return
	leo_en_zona_plataforma = false
	for body in zona_plataforma.get_overlapping_bodies():
		if body.is_in_group("player"):
			leo_en_zona_plataforma = true
			return

func _physics_process(delta: float) -> void:
	# 🌟 GENERAR ESTELA: Esto es un efecto visual local, corre en todas las PCs
	_crear_estela(delta)

	# 🌟 REGLA DE RED: La física y las decisiones del Eco SOLO corren en el Servidor
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return

	if estado_actual == Estados.MUERTO:
		velocity.x = move_toward(velocity.x, 0, velocidad * delta)
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y += gravedad * delta
	
	if estado_actual == Estados.HERIDO:
		velocity.x = move_toward(velocity.x, 0, velocidad * delta * 5)
		move_and_slide()
		return
	
	if estado_actual == Estados.ATACANDO:
		velocity.x = 0
		move_and_slide()
		return
	
	# 🌟 IA COOPERATIVA: Buscamos dinámicamente al jugador más cercano
	jugador_objetivo = _obtener_jugador_mas_cercano()
	
	if jugador_objetivo == null:
		_regresar_a_inicio(delta)
		move_and_slide()
		return
	
	if regresar_si_leo_sale_zona and zona_plataforma != null and not leo_en_zona_plataforma:
		historial_posiciones.clear()
		_regresar_a_inicio(delta)
		move_and_slide()
		return
	
	var distancia_total: float = global_position.distance_to(jugador_objetivo.global_position)
	
	if distancia_total > distancia_deteccion:
		_regresar_a_inicio(delta)
		move_and_slide()
		return
	
	estado_actual = Estados.IMITANDO
	
	# Guardamos y seguimos el rastro del jugador objetivo actual
	_guardar_posicion_de_leo(jugador_objetivo)
	var posicion_objetivo: Vector2 = _obtener_posicion_retrasada(jugador_objetivo.global_position)
	
	var diferencia_x: float = posicion_objetivo.x - global_position.x
	var distancia_x: float = abs(jugador_objetivo.global_position.x - global_position.x)
	var distancia_y: float = abs(jugador_objetivo.global_position.y - global_position.y)
	
	if distancia_x <= distancia_ataque and distancia_y <= 60 and puede_atacar:
		_iniciar_ataque()
	else:
		if abs(diferencia_x) > 8:
			var direccion: float = sign(diferencia_x)
			_actualizar_direccion_visual(direccion)
			
			if _hay_suelo_adelante(direccion):
				velocity.x = direccion * velocidad
			else:
				_regresar_a_inicio(delta)
			
			_reproducir("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, velocidad * delta)
			_reproducir("walk")
	
	move_and_slide()

# 🌟 FUNCIÓN AUXILIAR COOPERATIVA
func _obtener_jugador_mas_cercano() -> CharacterBody2D:
	var jugadores = get_tree().get_nodes_in_group("player")
	var cercano: CharacterBody2D = null
	var menor_dist: float = 999999.0
	for j in jugadores:
		if j and not j.esta_muerto:
			var dist = global_position.distance_to(j.global_position)
			if dist < menor_dist:
				menor_dist = dist
				cercano = j
	return cercano

func _regresar_a_inicio(delta: float) -> void:
	estado_actual = Estados.REGRESANDO
	var diferencia_inicio: float = posicion_inicio.x - global_position.x
	
	if abs(diferencia_inicio) <= tolerancia_inicio:
		velocity.x = move_toward(velocity.x, 0, velocidad_regreso * delta * 4)
		estado_actual = Estados.ESPERANDO
		_reproducir("walk")
		return
	
	var direccion: float = sign(diferencia_inicio)
	_actualizar_direccion_visual(direccion)
	
	if _hay_suelo_adelante(direccion):
		velocity.x = direccion * velocidad_regreso
	else:
		velocity.x = 0
	
	_reproducir("walk")

func _actualizar_direccion_visual(direccion: float) -> void:
	if direccion == 0:
		return
	sprite.flip_h = direccion < 0
	if area_ataque:
		area_ataque.position.x = area_ataque_x_base * direccion

func _hay_suelo_adelante(direccion: float) -> bool:
	if detector_suelo == null:
		return true
	detector_suelo.target_position = Vector2(45 * direccion, 90)
	detector_suelo.force_raycast_update()
	return detector_suelo.is_colliding()

func _guardar_posicion_de_leo(target: Node2D) -> void:
	var tiempo_actual: float = Time.get_ticks_msec() / 1000.0
	historial_posiciones.append({
		"tiempo": tiempo_actual,
		"posicion": target.global_position
	})
	while historial_posiciones.size() > 100:
		historial_posiciones.pop_front()

func _obtener_posicion_retrasada(posicion_actual: Vector2) -> Vector2:
	var tiempo_objetivo: float = Time.get_ticks_msec() / 1000.0 - retardo_imitacion
	for dato in historial_posiciones:
		if dato["tiempo"] >= tiempo_objetivo:
			return dato["posicion"]
	return posicion_actual

func _iniciar_ataque() -> void:
	if estado_actual == Estados.ATACANDO or estado_actual == Estados.HERIDO or estado_actual == Estados.MUERTO:
		return
	
	estado_actual = Estados.ATACANDO
	puede_atacar = false
	velocity.x = 0
	
	if hitbox_ataque:
		hitbox_ataque.set_deferred("disabled", false)
	
	_reproducir("attack")
	
	await get_tree().create_timer(duracion_ataque_segura).timeout
	
	if estado_actual == Estados.ATACANDO:
		if hitbox_ataque:
			hitbox_ataque.set_deferred("disabled", true)
		estado_actual = Estados.IMITANDO
	
	await get_tree().create_timer(cooldown_ataque).timeout
	if estado_actual != Estados.MUERTO:
		puede_atacar = true

func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	# 🌟 RED RPC: Si el Cliente golpea al Eco, redirige el daño al Servidor maestro
	if multiplayer.multiplayer_peer != null:
		if not multiplayer.is_server():
			sincronizar_danio_eco.rpc_id(1, cantidad, origen_danio_x)
			return

	if estado_actual == Estados.HERIDO or estado_actual == Estados.MUERTO:
		return
	
	vida_actual -= cantidad
	print("Eco de Sombra recibió daño. Vida restante: ", vida_actual)
	
	if vida_actual <= 0:
		_morir()
		return
	
	estado_actual = Estados.HERIDO
	if hitbox_ataque:
		hitbox_ataque.set_deferred("disabled", true)
	
	var direccion_retroceso: float = 1.0 if global_position.x > origen_danio_x else -1.0
	velocity = Vector2(direccion_retroceso * knockback_fuerza, -120.0)
	_reproducir("danio")
	
	await get_tree().create_timer(duracion_danio_segura).timeout
	if estado_actual == Estados.HERIDO:
		estado_actual = Estados.IMITANDO

# 🌟 RPC EXCLUSIVO PARA EL DAÑO DEL ECO
@rpc("any_peer", "call_local", "reliable")
func sincronizar_danio_eco(cantidad: int, origen_x: float) -> void:
	if multiplayer.is_server():
		recibir_danio(cantidad, origen_x)

func _morir() -> void:
	if estado_actual == Estados.MUERTO:
		return
	estado_actual = Estados.MUERTO
	if hitbox_ataque:
		hitbox_ataque.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	_reproducir("death")
		# Entregamos la llave si es servidor O si no hay red (solitario)
	if llave_a_soltar != "":
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			print("Entregando llave en entorno seguro...")
			_entregar_llave_al_asesino()
		else:
			print("Soy cliente, no tengo autoridad para dar llaves.")




func _entregar_llave_al_asesino() -> void:
	var jugadores = get_tree().get_nodes_in_group("player")
	var entregada = false
	
	for j in jugadores:
		# Aumentamos a 250px para ser más flexibles
		var distancia = global_position.distance_to(j.global_position)
		print("Distancia al jugador: ", distancia) # DEBUG: Mira esto en la consola
		if distancia < 250.0:
			if j.has_method("agregar_llave"):
				j.agregar_llave(llave_a_soltar)
				print("¡LLAVE ENTREGADA CON ÉXITO!")
				entregada = true
				break
	if not entregada:
		print("No se encontró jugador cerca para entregar la llave.")

	
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if estado_actual == Estados.MUERTO and sprite.animation == "death":
		_borrar_enemigo_red()
		return
	
	if sprite.animation == "attack":
		if hitbox_ataque:
			hitbox_ataque.set_deferred("disabled", true)
		if estado_actual == Estados.ATACANDO:
			estado_actual = Estados.IMITANDO
	elif sprite.animation == "danio":
		if estado_actual == Estados.HERIDO:
			estado_actual = Estados.IMITANDO

# 🌟 ELIMINACIÓN CENTRALIZADA EN RED
func _borrar_enemigo_red() -> void:
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			queue_free()
	else:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if estado_actual != Estados.ATACANDO:
		return
	
	if body.is_in_group("player") and body.has_method("recibir_danio"):
		# 🌟 CONTROL DE DAÑO CENTRALIZADO: Solo el Host dictamina el golpe al jugador
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			if CombateManager.solicitar_permiso_danio():
				print("El Eco de Sombra golpeó a un jugador")
				body.recibir_danio(dano_contacto, global_position.x)

func _on_zona_plataforma_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# En multijugador, si CUALQUIER jugador entra a la zona, el Eco se activa
		leo_en_zona_plataforma = true

func _on_zona_plataforma_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Verificamos si aún queda el OTRO jugador dentro de la zona antes de apagarla
		await get_tree().process_frame
		if zona_plataforma:
			var quedan_jugadores = false
			for b in zona_plataforma.get_overlapping_bodies():
				if b.is_in_group("player") and not b.esta_muerto:
					quedan_jugadores = true
					break
			leo_en_zona_plataforma = quedan_jugadores
		else:
			leo_en_zona_plataforma = false
		
		if not leo_en_zona_plataforma:
			historial_posiciones.clear()

func _crear_estela(delta: float) -> void:
	tiempo_estela -= delta
	if tiempo_estela > 0:
		return
	tiempo_estela = 0.15
	if sprite.sprite_frames == null:
		return
	
	var textura: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if textura == null:
		return
	
	var sombra := Sprite2D.new()
	sombra.texture = textura
	sombra.global_position = sprite.global_position
	sombra.global_scale = sprite.global_scale
	sombra.flip_h = sprite.flip_h
	sombra.modulate = Color(0.65, 0.05, 0.95, 0.25)
	sombra.z_index = sprite.z_index - 1
	
	get_tree().current_scene.add_child(sombra)
	
	var tween := sombra.create_tween()
	tween.tween_property(sombra, "modulate:a", 0.0, 0.35)
	tween.tween_callback(sombra.queue_free)

func _reproducir(nombre_animacion: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(nombre_animacion):
		if sprite.animation != nombre_animacion:
			sprite.play(nombre_animacion)
