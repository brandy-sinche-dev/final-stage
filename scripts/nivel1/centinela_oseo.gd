extends CharacterBody2D

@export var SPEED = 110.0
@export var DISTANCIA_ATAQUE = 16.0 
@export var DISTANCIA_DETECCION = 250.0
@export var COOLDOWN_TIEMPO = 0.8
@export var TOLERANCIA_ALTURA_ATAQUE = 24.0
@export var DANO_ATAQUE = 10

# Sistema de Vida del Enemigo
@export var vida_maxima: int = 50
var vida_actual: int = vida_maxima
var esta_herido = false
var esta_muerto = false
@export var knockback_fuerza: float = 180.0

@onready var sprite = $Visuals/AnimatedSprite2D
@onready var visuals = $Visuals
@onready var hitbox = $Visuals/Hitbox/CollisionShape2D

@onready var ray_frontal = $RayCastFront  
@onready var ray_back = $RayCastBack      

var esta_atacando = false
var en_cooldown = false

# Efectos de sonido
@onready var sonido_atacado: AudioStreamPlayer2D = $EffectsSounds/sound_atacado
@onready var sonido_ataque: AudioStreamPlayer2D = $EffectsSounds/sound_ataque


func _physics_process(delta):
	# 🌟 REGLA DE MULTIJUGADOR: La IA y las físicas del enemigo SOLO corren en el Servidor.
	# Si estamos online y no somos el servidor, dejamos que el Sincronizador maneje la posición y animaciones.
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return

	# 1. CONTROL DE MUERTE
	if esta_muerto:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		move_and_slide()
		return

	# 2. GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. CONTROL DE COMPORTAMIENTO IA VS HERIDO
	if esta_herido:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 4)
		if sprite.animation != "hurt" and sprite.sprite_frames.has_animation("hurt"):
			sprite.play("hurt")
	else:
		# 🌟 SOLUCIÓN IA MULTIJUGADOR: Buscamos al jugador más cercano
		var leo = _obtener_jugador_mas_cercano()
		if not leo:
			_quedarse_quieto()
			move_and_slide()
			return

		if esta_atacando:
			velocity.x = 0
		else:
			var diff_x = leo.global_position.x - global_position.x
			var diff_y = abs(leo.global_position.y - global_position.y)
			var direccion = sign(diff_x)
			var distancia_x = abs(diff_x)
			var distancia_total = global_position.distance_to(leo.global_position)

			if direccion != 0:
				visuals.scale.x = direccion

			# MÁQUINA DE DECISIONES DE LA IA
			if distancia_total > DISTANCIA_DETECCION:
				_quedarse_quieto()
			elif distancia_x <= DISTANCIA_ATAQUE and diff_y <= TOLERANCIA_ALTURA_ATAQUE:
				if not en_cooldown:
					_iniciar_ataque()
				else:
					_quedarse_quieto()
			else:
				var hay_suelo = ray_frontal.is_colliding() if direccion > 0 else ray_back.is_colliding()
				if not hay_suelo and is_on_floor():
					_quedarse_quieto()
				else:
					velocity.x = direccion * SPEED
					if sprite.animation != "walk":
						sprite.play("walk")

	# 4. EJECUTAR FÍSICA CONSTANTE (Solo Servidor o Solitario)
	move_and_slide()


# 🌟 NUEVA FUNCIÓN: Devuelve dinámicamente al jugador más cercano que esté vivo
func _obtener_jugador_mas_cercano() -> CharacterBody2D:
	var jugadores = get_tree().get_nodes_in_group("player")
	var jugador_cercano: CharacterBody2D = null
	var menor_distancia: float = 999999.0

	for j in jugadores:
		# Validamos que el jugador exista y no esté muerto
		if j and not j.esta_muerto:
			var dist = global_position.distance_to(j.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				jugador_cercano = j
				
	return jugador_cercano


func _quedarse_quieto():
	velocity.x = 0
	if sprite.animation != "idle":
		sprite.play("idle")


func _iniciar_ataque():
	sonido_ataque.play()
	esta_atacando = true
	velocity.x = 0
	sprite.play("attack")


func recibir_danio(cantidad: int, origen_golpe_x: float) -> void:
	# Si estamos jugando en red...
	if multiplayer.multiplayer_peer != null:
		# Si el golpe lo detectó el cliente, le envía un RPC al servidor para que procese el daño real
		if not multiplayer.is_server():
			sincronizar_danio_enemigo.rpc_id(1, cantidad, origen_golpe_x)
			return
			
	# Lógica interna del Servidor (o modo solitario offline)
	if esta_herido or esta_muerto:
		return
		
	vida_actual -= cantidad
	sonido_atacado.play()
	print("Vida del Centinela: ", vida_actual)
	
	if vida_actual <= 0:
		_morir()
		return
		
	esta_herido = true
	esta_atacando = false 
	
	var direccion_retroceso = 1.0 if global_position.x > origen_golpe_x else -1.0
	velocity = Vector2(direccion_retroceso * knockback_fuerza, -100.0)
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")


func _morir() -> void:
	esta_muerto = true
	esta_atacando = false
	esta_herido = false
	velocity = Vector2.ZERO
	
	hitbox.set_deferred("disabled", true)
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	else:
		print("No se encontró animación de muerte, borrando nodo de forma segura.")
		_borrar_enemigo_red()


func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "attack":
		esta_atacando = false 
		_iniciar_cooldown()
	elif sprite.animation == "hurt":
		esta_herido = false 
	elif sprite.animation == "death":
		print("Animación de muerte terminada. Solicitando eliminación segura.")
		_borrar_enemigo_red()


# 🌟 NUEVA FUNCIÓN: Garantiza que solo el servidor elimine el nodo en red
func _borrar_enemigo_red() -> void:
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			queue_free() # El servidor lo borra, el MultiplayerSpawner limpia al Cliente y avanza la ola
	else:
		queue_free() # Si juegas solo offline


func _iniciar_cooldown():
	en_cooldown = true
	await get_tree().create_timer(COOLDOWN_TIEMPO).timeout
	en_cooldown = false


func _process(_delta):
	# Permitimos que corra en Clientes únicamente para el control estricto visual de la hitbox local
	if esta_muerto:
		return

	if esta_atacando and sprite.animation == "attack":
		if sprite.frame >= 7:
			hitbox.disabled = false
		else:
			hitbox.disabled = true
	else:
		hitbox.disabled = true


func _on_hitbox_body_entered(body: Node2D) -> void:
	if esta_muerto or esta_herido:
		return
		
	if body.is_in_group("player") and body.has_method("recibir_danio"):
		# 🌟 CONTROL DE DAÑO SEGURO: El Servidor calcula el daño real para evitar duplicados
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			print("¡El Centinela golpeó a un jugador!")
			body.recibir_danio(DANO_ATAQUE, global_position.x)
			
# 🌟 NUEVO RPC: El Cliente le avisa al Servidor que el enemigo fue golpeado
@rpc("any_peer", "call_local", "reliable")
func sincronizar_danio_enemigo(cantidad: int, origen_x: float) -> void:
	if multiplayer.is_server():
		recibir_danio(cantidad, origen_x)
