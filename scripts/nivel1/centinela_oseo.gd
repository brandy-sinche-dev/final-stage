extends CharacterBody2D

@export var SPEED = 110.0
@export var DISTANCIA_ATAQUE = 16.0 # Distancia corta requerida
@export var COOLDOWN_TIEMPO = 0.8

@onready var sprite = $Visuals/AnimatedSprite2D
@onready var visuals = $Visuals
@onready var hitbox = $Visuals/Hitbox/CollisionShape2D

var esta_atacando = false
var en_cooldown = false

func _physics_process(delta):
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 1. BUSCAR A LEO
	var leo = get_tree().get_first_node_in_group("player")
	
	if not leo:
		velocity.x = 0
		sprite.play("idle")
		move_and_slide()
		return

	# 2. LÓGICA DE ESTADOS
	if esta_atacando:
		# Mientras ataca, no procesamos nada más
		velocity.x = 0
	else:
		var diff_x = leo.global_position.x - global_position.x
		var direccion = sign(diff_x)
		var distancia = abs(diff_x)

		# Girar visuales siempre que no esté atacando
		if direccion != 0:
			visuals.scale.x = direccion

		# 3. COMPORTAMIENTO
		if distancia <= DISTANCIA_ATAQUE and not en_cooldown:
			# SOLO ATACA SI ESTÁ A 16px O MENOS
			_iniciar_ataque()
		elif distancia > DISTANCIA_ATAQUE:
			# SI ESTÁ LEJOS, LO SIGUE SIEMPRE
			velocity.x = direccion * SPEED
			sprite.play("walk")
		else:
			# Si está cerca pero en espera (cooldown)
			velocity.x = 0
			sprite.play("idle")

	move_and_slide()

func _iniciar_ataque():
	esta_atacando = true
	velocity.x = 0
	sprite.play("attack")

# SEÑAL DEL ANIMATEDSPRITE2D (VITAL)
func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "attack":
		esta_atacando = false # DESBLOQUEA al enemigo para que vuelva a seguir
		_iniciar_cooldown()

func _iniciar_cooldown():
	en_cooldown = true
	await get_tree().create_timer(COOLDOWN_TIEMPO).timeout
	en_cooldown = false

func _process(_delta):
	# Activar hitbox solo en el impacto visual
	if esta_atacando and sprite.animation == "attack":
		hitbox.disabled = not (sprite.frame >= 3 and sprite.frame <= 5)
	else:
		hitbox.disabled = true
