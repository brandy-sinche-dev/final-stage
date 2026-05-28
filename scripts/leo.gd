extends CharacterBody2D

# Configuración de movimiento
const SPEED_WALK = 90.0  
const SPEED_RUN = 170.0   
const JUMP_VELOCITY = -350.0

# Array para almacenar los IDs de las llaves que tenemos
var llaves_recolectadas: Array[String] = []


# Estadísticas de Vida y Combate
@export var max_vida: int = 100
var vida_actual: int = max_vida
@export var knockback_fuerza: float = 200.0
@export var dano_espada = 15

# Referencias a los nodos hijos
@onready var sprite = $AnimatedSprite2D  
@onready var sword_hitbox = $Visuals/SwordArea/CollisionShape2D 

# Estados del personaje
var esta_atacando = false
var esta_herido = false
var esta_muerto = false

# Efectos de sonidos
@onready var sonido_saltar: AudioStreamPlayer2D = $EffectsSounds/sound_jump
@onready var sonido_ataque1: AudioStreamPlayer2D = $EffectsSounds/sound_ataque1
@onready var sonido_dano: AudioStreamPlayer2D = $EffectsSounds/sound_hurt


func _physics_process(delta: float) -> void:
	# 1. CONTROL DE MUERTE
	if esta_muerto:
		velocity.x = move_toward(velocity.x, 0, SPEED_WALK)
		move_and_slide()
		_maquina_visual()
		return
		
	# 2. GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. PROCESAR MOVIMIENTO (Solo si NO está herido)
	if esta_herido:
		# Durante el impacto, disminuye la inercia del golpe gradualmente
		velocity.x = move_toward(velocity.x, 0, SPEED_WALK * delta * 5)
	else:
		# CAPTURA DE INPUTS NORMALES
		var direction := Input.get_axis("ui_left", "ui_right")
		var quiere_saltar := Input.is_action_just_pressed("ui_accept") and is_on_floor()
		var quiere_atacar := Input.is_action_just_pressed("atacar")

		# LÓGICA DE CANCELACIÓN REAL
		if esta_atacando and quiere_saltar:
			esta_atacando = false

		# PROCESAR ACCIONES
		if quiere_saltar:
			velocity.y = JUMP_VELOCITY
			sonido_saltar.play() 
		elif quiere_atacar and not esta_atacando:
			esta_atacando = true
			CombateManager.iniciar_nuevo_ataque_leo()
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, SPEED_WALK)

		# PROCESAR MOVIMIENTO HORIZONTAL
		var corriendo = Input.is_action_pressed("ui_shift") 
		var velocidad_actual = SPEED_RUN if corriendo else SPEED_WALK

		if esta_atacando and is_on_floor():
			velocity.x = 0
		else:
			if direction:
				velocity.x = direction * velocidad_actual
				sprite.flip_h = (direction < 0)
				if has_node("Visuals"): 
					$Visuals.scale.x = direction
			else:
				velocity.x = move_toward(velocity.x, 0, velocidad_actual)

	# 4. EJECUTAR FÍSICA Y ACTUALIZAR MÁQUINAS (Siempre corren para no romper animaciones)
	move_and_slide()
	_controlar_hitbox_espada() 
	_maquina_visual()


# MÁQUINA VISUAL: Controla las animaciones por orden estricto de prioridad
func _maquina_visual() -> void:
	if esta_muerto:
		if sprite.animation != "death": sprite.play("death")
		return

	if esta_herido:
		if sprite.animation != "hurt": 
			sprite.play("hurt")
		return

	if esta_atacando:
		if sprite.animation != "attack":
			sonido_ataque1.play()
			sprite.play("attack")
			sprite.frame = 0 
		return 

	if not is_on_floor():
		if sprite.animation != "jump":
			sprite.play("jump")
	else:
		if velocity.x != 0:
			if abs(velocity.x) > SPEED_WALK:
				if sprite.animation != "run": sprite.play("run")
			else:
				if sprite.animation != "walk": sprite.play("walk")
		else:
			if sprite.animation != "idle": sprite.play("idle")


func _controlar_hitbox_espada() -> void:
# Si está atacando, la hitbox se ENCIENDE (disabled = false)
	if esta_atacando:
		sword_hitbox.disabled = false
	else:
		sword_hitbox.disabled = true


func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	if esta_herido or esta_muerto:
		return
		
	vida_actual -= cantidad
	sonido_dano.play()
	print("Vida de Leo: ", vida_actual)
	
	# === ENLACE CON EL HUD ===
	var interfaz = get_tree().get_first_node_in_group("hud")
	if interfaz and interfaz.has_method("actualizar_vida"):
		interfaz.actualizar_vida(vida_actual)
	# =========================
	
	if vida_actual <= 0:
		morir()
		return
		
	esta_herido = true
	esta_atacando = false
	
	var dir_retroceso = 1.0 if global_position.x > origen_danio_x else -1.0
	velocity = Vector2(dir_retroceso * knockback_fuerza, -150.0) 
	sprite.play("hurt")


func morir() -> void:
	esta_muerto = true
	velocity = Vector2.ZERO
	sprite.play("death")


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		esta_atacando = false 
	elif sprite.animation == "hurt":
		esta_herido = false # Al limpiar esto fluidamente, recupera el control
	elif sprite.animation == "death":
		get_tree().reload_current_scene()


func _on_sword_area_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_danio") and body != self:
		if CombateManager.leo_puede_hacer_danio():
			print("¡Leo golpeó a: ", body.name, " (Primer objetivo del espadazo)!")
			body.recibir_danio(dano_espada, global_position.x)
		else:
			print("Golpe ignorado para ", body.name, " porque la espada ya impactó a un enemigo antes.")

func agregar_llave(id_llave: String) -> void:
	if not llaves_recolectadas.has(id_llave):
		llaves_recolectadas.append(id_llave)

func tiene_llave(id_llave: String) -> bool:
	# Devuelve true si Leo tiene la llave en su inventario
	return llaves_recolectadas.has(id_llave)

func gastar_llave(id_llave: String) -> void:
	# Si la llave es de un solo uso, la borramos tras abrir la puerta
	llaves_recolectadas.erase(id_llave)

# ==========================================
# SEÑAL DE REINICIO EN NIVEL 2 (ZONA DE MUERTE / VACÍO)
# ==========================================

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Como este script corre en Leo, si el Area2D detecta un cuerpo,
	# ejecutamos la función morir() para que haga su animación y luego reinicie.
	if not esta_muerto:
		morir()


func _on_area_2d_2_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
