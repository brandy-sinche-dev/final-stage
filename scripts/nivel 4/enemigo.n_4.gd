extends CharacterBody2D


@export var velocidad: float = 60.0
@export var max_vida: int = 45
var vida_actual: int = max_vida
@export var dano_espada: int = 20
@export var knockback_fuerza: float = 150.0


@export var DISTANCIA_ATAQUE = 24.0  
@export var DISTANCIA_DETECCION = 200.0

# Gravedad del juego
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

# Estados del enemigo
enum Estados { PATRULLA, ATACANDO, HERIDO, MUERTO }
var estado_actual = Estados.PATRULLA

# Referencias a tus nodos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_espada: Area2D = get_node_or_null("Area2D")
@onready var hitbox_espada: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")

func _ready():
	vida_actual = max_vida
	sprite.play("walk")
	if area_espada == null or hitbox_espada == null:
		push_warning("Enemig_n4 no tiene Area2D/CollisionShape2D para ataque cuerpo a cuerpo.")
	

func _physics_process(delta: float) -> void:
	# 1. GRAVEDAD
	if not is_on_floor():
		velocity.y += gravedad * delta

	# 2. CONTROL DE ESTADOS
	if estado_actual == Estados.MUERTO:
		velocity.x = move_toward(velocity.x, 0, velocidad)
		move_and_slide()
		return

	if estado_actual == Estados.HERIDO:
		velocity.x = move_toward(velocity.x, 0, velocidad * delta * 5)
	
	elif estado_actual == Estados.ATACANDO:
		velocity.x = 0
		
	else:
		
		var leo = get_tree().get_first_node_in_group("player")
		if leo:
			var diff_x = leo.global_position.x - global_position.x
			var direccion = sign(diff_x)
			var distancia_x = abs(diff_x)
			var distancia_total = global_position.distance_to(leo.global_position)

			# Girar el sprite y la espada hacia Leo de forma segura
			if direccion != 0:
				sprite.flip_h = (direccion > 0)
				if area_espada != null:
					area_espada.position.x = abs(area_espada.position.x) * direccion

			# Decisiones
			if distancia_total > DISTANCIA_DETECCION:
				# Si Leo está lejos, patrulla o se queda quieto
				velocity.x = 0
				sprite.play("walk") # O puedes poner "idle" si prefieres
			elif distancia_x <= DISTANCIA_ATAQUE:
				# ¡Si está lo suficientemente cerca, ATACA!
				_iniciar_ataque()
			else:
				# Si lo detecta pero está lejos, camina hacia Leo
				velocity.x = direccion * velocidad
				if sprite.animation != "walk":
					sprite.play("walk")
		else:
			velocity.x = 0
			sprite.play("walk")

	move_and_slide()


func _iniciar_ataque() -> void:
	estado_actual = Estados.ATACANDO
	velocity.x = 0
	sprite.play("attack")
	if hitbox_espada != null:
		hitbox_espada.set_deferred("disabled", false)


func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	if estado_actual == Estados.HERIDO or estado_actual == Estados.MUERTO:
		return
		
	vida_actual -= cantidad
	print(name, " recibió daño. Vida restante: ", vida_actual)
	
	if vida_actual <= 0:
		_morir()
		return
		
	estado_actual = Estados.HERIDO
	if hitbox_espada != null:
		hitbox_espada.set_deferred("disabled", true)
	
	var dir_retroceso = 1.0 if global_position.x > origen_danio_x else -1.0
	velocity = Vector2(dir_retroceso * knockback_fuerza, -100.0)
	sprite.play("danio") 


func _morir() -> void:
	estado_actual = Estados.MUERTO
	if hitbox_espada != null:
		hitbox_espada.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	sprite.play("death")


# --- SEÑALES CONECTADAS ---

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		if hitbox_espada != null:
			hitbox_espada.set_deferred("disabled", true)
		estado_actual = Estados.PATRULLA 
	elif sprite.animation == "danio":
		estado_actual = Estados.PATRULLA 
	elif sprite.animation == "death":
		queue_free() 


func _on_area_2d_body_entered(body: Node2D) -> void:
	if estado_actual == Estados.ATACANDO and body.has_method("recibir_danio") and body != self:
		print("¡El enemigo acuchilló a Leo!")
		body.recibir_danio(dano_espada, global_position.x)
