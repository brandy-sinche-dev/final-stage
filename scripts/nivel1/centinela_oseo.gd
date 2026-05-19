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

func _physics_process(delta):
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
		# Reduce el knockback del esqueleto fluidamente sin romper el ciclo del motor
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 4)
		if sprite.animation != "hurt" and sprite.sprite_frames.has_animation("hurt"):
			sprite.play("hurt")
	else:
		# PROCESAR INTELIGENCIA ARTIFICIAL SI ESTÁ SANO
		var leo = get_tree().get_first_node_in_group("player")
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

	# 4. EJECUTAR FÍSICA CONSTANTE
	move_and_slide()


func _quedarse_quieto():
	velocity.x = 0
	if sprite.animation != "idle":
		sprite.play("idle")


func _iniciar_ataque():
	esta_atacando = true
	velocity.x = 0
	sprite.play("attack")


func recibir_danio(cantidad: int, origen_golpe_x: float) -> void:
	if esta_herido or esta_muerto:
		return
		
	vida_actual -= cantidad
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
	
	# Desactivamos su hitbox de ataque de forma segura para que no golpee a Leo al morir
	hitbox.set_deferred("disabled", true)
	
	# IMPORTANTE: Asegúrate de que la animación "death" en tu AnimatedSprite2D NO tenga activado el LOOP
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	else:
		print("No se encontró animación de muerte, borrando nodo.")
		queue_free()


func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "attack":
		esta_atacando = false 
		_iniciar_cooldown()
	elif sprite.animation == "hurt":
		esta_herido = false # Termina el dolor de manera natural y reactiva la IA
	elif sprite.animation == "death":
		print("Animación de muerte terminada. Eliminando al Centinela.")
		queue_free() # Ahora sí se borrará ÚNICAMENTE cuando termine el último frame de muerte


func _iniciar_cooldown():
	en_cooldown = true
	await get_tree().create_timer(COOLDOWN_TIEMPO).timeout
	en_cooldown = false


func _process(_delta):
	# 1. Si está muerto, bloqueamos el proceso para que no altere las hitboxes ni gaste recursos
	if esta_muerto:
		return

	# 2. Control de Hitbox milimétrico por frames de animación
	if esta_atacando and sprite.animation == "attack":
		# EJEMPLO: Si tu animación tiene 6 frames (0,1,2,3,4,5), el golpe se activará 
		# solo en los frames finales (4 y 5). Ajusta el número según tus sprites.
		if sprite.frame >= 7:
			hitbox.disabled = false
		else:
			hitbox.disabled = true
	else:
		# Si no está ejecutando la animación de ataque, la hitbox permanece apagada
		hitbox.disabled = true


func _on_hitbox_body_entered(body: Node2D) -> void:
	# Protegemos para que el centinela no haga daño si está herido o muerto en ese frame
	if esta_muerto or esta_herido:
		return
		
	if body.is_in_group("player") and body.has_method("recibir_danio"):
		print("¡El Centinela golpeó a Leo!")
		body.recibir_danio(DANO_ATAQUE, global_position.x)
