extends CharacterBody2D

@export var velocidad: float = 55.0
@export var max_vida: int = 180
@export var dano_ataque: int = 28
@export var distancia_deteccion: float = 520.0
@export var distancia_ataque: float = 70.0
@export var tolerancia_altura_ataque: float = 60.0
@export var cooldown_ataque: float = 1.15
@export var knockback_fuerza: float = 120.0

enum Estados { IDLE, PERSIGUIENDO, ATACANDO, HERIDO, MUERTO }

var vida_actual: int
var estado_actual = Estados.IDLE
var puede_atacar := true
var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var posicion_ataque_base := 54.0
var esta_muriendo:bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $AreaAtaque
@onready var hitbox_ataque: CollisionShape2D = $AreaAtaque/CollisionShape2D
@onready var barra_vida: ProgressBar = get_node_or_null("BarraVida")
@onready var sonido_ataque = $AudioStreamPlayer
@onready var timer_espera: Timer = $Timer

func _ready() -> void:
	vida_actual = max_vida
	add_to_group("enemigos")
	if area_ataque:
		area_ataque.collision_layer = 0
		area_ataque.collision_mask = 2
		posicion_ataque_base = abs(area_ataque.position.x)
	if hitbox_ataque:
		hitbox_ataque.disabled = true
	if barra_vida:
		barra_vida.max_value = max_vida
		barra_vida.value = vida_actual
	_reproducir("idle")

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return

	if estado_actual == Estados.MUERTO:
		velocity.x = move_toward(velocity.x, 0, velocidad * delta)
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravedad * delta

	if estado_actual == Estados.HERIDO:
		velocity.x = move_toward(velocity.x, 0, velocidad * delta * 4)
		move_and_slide()
		return

	if estado_actual == Estados.ATACANDO:
		velocity.x = 0
		move_and_slide()
		return

	var jugador = _obtener_jugador_mas_cercano()
	if jugador == null:
		_quedarse_quieto()
		move_and_slide()
		return

	var diferencia = jugador.global_position - global_position
	var distancia_total = global_position.distance_to(jugador.global_position)
	var direccion = sign(diferencia.x)

	if direccion != 0:
		_actualizar_direccion_visual(direccion)

	if distancia_total > distancia_deteccion:
		_quedarse_quieto()
	elif abs(diferencia.x) <= distancia_ataque and abs(diferencia.y) <= tolerancia_altura_ataque and puede_atacar:
		_iniciar_ataque()
	else:
		estado_actual = Estados.PERSIGUIENDO
		velocity.x = direccion * velocidad
		_reproducir("walk")

	move_and_slide()

func _process(_delta: float) -> void:
	if estado_actual == Estados.ATACANDO and sprite.animation == "attack":
		var ataque_activo = sprite.frame >= 4 and sprite.frame <= 7
		hitbox_ataque.disabled = not ataque_activo
	else:
		hitbox_ataque.disabled = true

func _obtener_jugador_mas_cercano() -> CharacterBody2D:
	var jugadores = get_tree().get_nodes_in_group("player")
	var jugador_cercano: CharacterBody2D = null
	var menor_distancia := INF

	for jugador in jugadores:
		if jugador and not jugador.esta_muerto:
			var distancia = global_position.distance_to(jugador.global_position)
			if distancia < menor_distancia:
				menor_distancia = distancia
				jugador_cercano = jugador

	return jugador_cercano

func _actualizar_direccion_visual(direccion: float) -> void:
	# El sprite base del Bringer of Death mira a la izquierda.
	sprite.flip_h = direccion > 0
	area_ataque.position.x = posicion_ataque_base * direccion

func _quedarse_quieto() -> void:
	estado_actual = Estados.IDLE
	velocity.x = 0
	_reproducir("idle")

func _iniciar_ataque() -> void:
	estado_actual = Estados.ATACANDO
	puede_atacar = false
	velocity.x = 0
	print("¡SISTEMA: Intentando reproducir sonido de ataque!")
	if multiplayer.multiplayer_peer != null:
		reproducir_sonido_red.rpc("ataque")
	else:
		if sonido_ataque:
			sonido_ataque.play()
	_reproducir("attack")

func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		sincronizar_danio_jefe.rpc_id(1, cantidad, origen_danio_x)
		return

	if estado_actual == Estados.HERIDO or estado_actual == Estados.MUERTO:
		return

	vida_actual -= cantidad
	if barra_vida:
		barra_vida.value = vida_actual
	print("Jefe final recibió daño. Vida restante: ", vida_actual)

	if vida_actual <= 0:
		_morir()
		return

	estado_actual = Estados.HERIDO
	puede_atacar = true
	if hitbox_ataque:
		hitbox_ataque.set_deferred("disabled", true)

	var direccion_retroceso = 1.0 if global_position.x > origen_danio_x else -1.0
	velocity = Vector2(direccion_retroceso * knockback_fuerza, -90.0)
	_reproducir("hurt")

@rpc("any_peer", "call_local", "reliable")
func sincronizar_danio_jefe(cantidad: int, origen_x: float) -> void:
	if multiplayer.is_server():
		recibir_danio(cantidad, origen_x)

@rpc("any_peer", "call_local", "reliable")
func reproducir_sonido_red(tipo_sonido: String) -> void:
	if tipo_sonido == "ataque":
		if sonido_ataque:
			sonido_ataque.play()

func _morir() -> void:
	if estado_actual == Estados.MUERTO:
		return
	estado_actual = Estados.MUERTO
	velocity = Vector2.ZERO
	
	if hitbox_ataque:
		hitbox_ataque.set_deferred("disabled", true)
	if barra_vida:
		barra_vida.visible = false
		
	_reproducir("death")
	
	# 1. Esperamos a que termine la animación de muerte
	if $AnimatedSprite2D.has_signal("animation_finished"):
		await $AnimatedSprite2D.animation_finished
	else:
		await get_tree().create_timer(2.0).timeout
	
	# 2. Pausa dramática viendo al jefe derrotado
	timer_espera.start()
	await timer_espera.timeout 
	
	# 3. FUNDIDO A NEGRO AUTOMÁTICO E INFALIBLE
	var canvas_transicion = CanvasLayer.new()
	canvas_transicion.layer = 128 
	get_tree().root.add_child(canvas_transicion)
	
	var rect_negro = ColorRect.new()
	rect_negro.color = Color.BLACK
	rect_negro.modulate.a = 0.0 
	rect_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_transicion.add_child(rect_negro)
	
	# Animamos el fundido a negro en 1.5 segundos
	var tween = create_tween()
	tween.tween_property(rect_negro, "modulate:a", 1.0, 1.5)
	await tween.finished
	
	# 4. Limpiamos el nodo negro ANTES de cambiar de escena para que el menú no nazca oscuro
	canvas_transicion.queue_free()
	
	# 5. Cambiamos al menú principal
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		if hitbox_ataque:
			hitbox_ataque.set_deferred("disabled", true)
		if estado_actual == Estados.ATACANDO:
			estado_actual = Estados.IDLE
		_iniciar_cooldown()
	elif sprite.animation == "hurt":
		if estado_actual == Estados.HERIDO:
			estado_actual = Estados.IDLE
	elif sprite.animation == "death":
		#_borrar_jefe_red()
		pass

func _iniciar_cooldown() -> void:
	await get_tree().create_timer(cooldown_ataque).timeout
	if estado_actual != Estados.MUERTO:
		puede_atacar = true

func _on_area_ataque_body_entered(body: Node2D) -> void:
	if estado_actual != Estados.ATACANDO:
		return

	if body.is_in_group("player") and body.has_method("recibir_danio"):
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			if CombateManager.solicitar_permiso_danio():
				body.recibir_danio(dano_ataque, global_position.x)

func _borrar_jefe_red() -> void:
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			queue_free()
	else:
		queue_free()

func _reproducir(animacion: String) -> void:
	if sprite.animation != animacion:
		sprite.play(animacion)
