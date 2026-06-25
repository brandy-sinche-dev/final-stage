extends CharacterBody2D

# Configuración de movimiento
const SPEED_WALK = 110.0  
const SPEED_RUN = 170.0   
const JUMP_VELOCITY = -350.0

# Inventario de llaves
var llaves_recolectadas: Array[String] = []

# Estadísticas de Vida y Combate
@export var max_vida: int = 100
var vida_actual: int = max_vida
@export var knockback_fuerza: float = 200.0
@export var dano_espada = 15

# Referencias a los nodos hijos
@onready var sprite = $AnimatedSprite2D  
@onready var sword_hitbox = $Visuals/SwordArea/CollisionShape2D 
# El Label flotante sobre la cabeza del personaje
@onready var label_flotante = $LabelFlotante

# Estados del personaje
var esta_atacando = false
var esta_herido = false
var esta_muerto = false

# Efectos de sonidos
@onready var sonido_saltar: AudioStreamPlayer2D = $EffectsSounds/sound_jump
@onready var sonido_ataque1: AudioStreamPlayer2D = $EffectsSounds/sound_ataque1
@onready var sonido_dano: AudioStreamPlayer2D = $EffectsSounds/sound_hurt
@onready var sonido_muerte: AudioStreamPlayer2D = $EffectsSounds/sound_death


func _enter_tree() -> void:
	if multiplayer.multiplayer_peer != null:
		var id_del_dueno = name.to_int()
		if id_del_dueno > 0:
			set_multiplayer_authority(id_del_dueno)


func _ready() -> void:
	# 🌟 CONFIGURACIÓN DE FÍSICAS EXTRUCTURALES
	floor_constant_speed = true
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(46.0)

	if multiplayer.multiplayer_peer != null:
		if is_multiplayer_authority():
			$Camera2D.enabled = true
		else:
			if has_node("Camera2D"):
				$Camera2D.enabled = false
				
		# 🌟 SOLUCIÓN RED: Asignamos el nombre de jugador según quién sea el dueño de este nodo
		_configurar_texto_jugador_dinamico()
	else:
		if has_node("Camera2D"):
			$Camera2D.enabled = true
		# Modo Historia (Un solo jugador)
		if label_flotante:
			label_flotante.text = "Player 1"


func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return

	# 1. CONTROL DE MUERTE
	if esta_muerto:
		velocity.x = move_toward(velocity.x, 0, SPEED_WALK)
		move_and_slide()
		_maquina_visual()
		return
		
	# 2. GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. PROCESAR MOVIMIENTO Y ENTRADAS
	if esta_herido:
		velocity.x = move_toward(velocity.x, 0, SPEED_WALK * delta * 5)
	else:
		var direction := Input.get_axis("ui_left", "ui_right")
		var quiere_saltar := Input.is_action_just_pressed("ui_accept") and is_on_floor()
		var quiere_atacar := Input.is_action_just_pressed("atacar")

		if esta_atacando and quiere_saltar:
			esta_atacando = false

		if quiere_saltar:
			velocity.y = JUMP_VELOCITY
			sonido_saltar.play() 
		elif quiere_atacar and not esta_atacando:
			esta_atacando = true
			CombateManager.iniciar_nuevo_ataque_leo()
			if is_on_floor():
				velocity.x = 0

		var corriendo = Input.is_action_pressed("ui_shift") 
		var velocidad_objetivo = SPEED_RUN if corriendo else SPEED_WALK
		
		if esta_atacando and is_on_floor():
			velocity.x = 0
		else:
			if direction:
				velocity.x = direction * velocidad_objetivo
				sprite.flip_h = (direction < 0)
				if has_node("Visuals"): 
					$Visuals.scale.x = direction
			else:
				velocity.x = 0 


	# 4. EJECUTAR FÍSICA Y ACTUALIZAR MÁQUINAS
	move_and_slide()
	_controlar_hitbox_espada() 
	_maquina_visual()


# MÁQUINA VISUAL: Control estricto de prioridades de animación
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
			if Input.is_action_pressed("ui_shift"):
				if sprite.animation != "run": sprite.play("run")
			else:
				if sprite.animation != "walk": sprite.play("walk")
		else:
			if sprite.animation != "idle": sprite.play("idle")


# 🌟 NUEVA FUNCIÓN INTERNA: Calcula el ID de red asignado a la instancia
func _configurar_texto_jugador_dinamico() -> void:
	if label_flotante == null:
		return
		
	# Obtenemos la autoridad de red que le diste a este personaje en el _enter_tree()
	var id_autoridad = get_multiplayer_authority()
	
	# El creador del servidor (Host) siempre tiene por regla nativa el ID = 1
	if id_autoridad == 1:
		label_flotante.text = "Player 1"
		label_flotante.modulate = Color.CYAN # Identificador visual celeste
	else:
		# Cualquier cliente conectado secundariamente tendrá un ID mayor a 1
		label_flotante.text = "Player 2"
		label_flotante.modulate = Color.ORANGE # Identificador visual naranja
		

func _controlar_hitbox_espada() -> void:
	sword_hitbox.disabled = not esta_atacando


func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	if esta_herido or esta_muerto:
		return
		
	vida_actual -= cantidad
	sonido_dano.play()
	
	var interfaz = get_tree().get_first_node_in_group("hud")
	if interfaz and interfaz.has_method("actualizar_vida"):
		interfaz.actualizar_vida(vida_actual)
	
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
	sonido_muerte.play()


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		esta_atacando = false 
	elif sprite.animation == "hurt":
		esta_herido = false
	elif sprite.animation == "death":
		set_physics_process(false) 
		if sonido_muerte.playing:
			await sonido_muerte.finished
		if multiplayer.multiplayer_peer != null:
			solicitar_reinicio_global.rpc()
		else:
			get_tree().reload_current_scene()


func _on_sword_area_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_danio") and body != self:
		if CombateManager.leo_puede_hacer_danio():
			body.recibir_danio(dano_espada, global_position.x)


func agregar_llave(id_llave: String) -> void:
	if not llaves_recolectadas.has(id_llave):
		llaves_recolectadas.append(id_llave)

func tiene_llave(id_llave: String) -> bool:
	return llaves_recolectadas.has(id_llave)

func gastar_llave(id_llave: String) -> void:
	llaves_recolectadas.erase(id_llave)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not esta_muerto:
		morir()

func _on_area_2d_2_body_entered(body: Node2D) -> void:
	pass


@rpc("any_peer", "call_local", "reliable")
func solicitar_reinicio_global() -> void:
	if multiplayer.is_server():
		get_tree().reload_current_scene()
