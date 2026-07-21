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

# Referencias a tus nodos (Con soporte para los nuevos nodos de audio)
@onready var sprite = $AnimatedSprite2D
@onready var area_espada = $Area2D
@onready var hitbox_espada = $Area2D/CollisionShape2D
@onready var sonido_ataque = $Ataque
@onready var sonido_danio = $Daño

# Define qué llave suelta este enemigo en el Inspector
@export var llave_a_soltar: String = "key_1"

func _ready():
	vida_actual = max_vida
	sprite.play("walk")
	hitbox_espada.disabled = true 

func _physics_process(delta: float) -> void:
	# 🌟 REGLA DE RED: IA y movimiento físico estricto SOLO en el Servidor
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return

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
		# 🌟 IA COOPERATIVA: Buscamos dinámicamente al más cercano
		var leo = _obtener_jugador_mas_cercano()
		if leo:
			var diff_x = leo.global_position.x - global_position.x
			var direccion = sign(diff_x)
			var distancia_x = abs(diff_x)
			var distancia_total = global_position.distance_to(leo.global_position)

			# Girar el sprite y la espada hacia Leo de forma segura
			if direccion != 0:
				sprite.flip_h = (direccion < 0)
				area_espada.position.x = abs(area_espada.position.x) * direccion

			# Decisiones
			if distancia_total > DISTANCIA_DETECCION:
				velocity.x = 0
				sprite.play("walk") 
			elif distancia_x <= DISTANCIA_ATAQUE:
				_iniciar_ataque()
			else:
				velocity.x = direccion * velocidad
				if sprite.animation != "walk":
					sprite.play("walk")
		else:
			velocity.x = 0
			sprite.play("walk")

	move_and_slide()


# 🌟 FUNCIÓN AUXILIAR: Detecta cuál de todos los jugadores está más cerca
func _obtener_jugador_mas_cercano() -> CharacterBody2D:
	var jugadores = get_tree().get_nodes_in_group("player")
	var jugador_cercano: CharacterBody2D = null
	var menor_distancia: float = 999999.0

	for j in jugadores:
		if j and not j.esta_muerto:
			var dist = global_position.distance_to(j.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				jugador_cercano = j
				
	return jugador_cercano


func _iniciar_ataque() -> void:
	estado_actual = Estados.ATACANDO
	velocity.x = 0
	sprite.play("attack")
	hitbox_espada.set_deferred("disabled", false)
	
	# Control de audio inteligente según el modo de juego
	if multiplayer.multiplayer_peer != null:
		rpc("reproducir_sonido_red", "ataque") # Modo 2 Jugadores (Red RPC)
	else:
		if sonido_ataque: sonido_ataque.play() # Modo Solo Jugador (Local)


func recibir_danio(cantidad: int, origen_danio_x: float) -> void:
	# 🌟 RED HÍBRIDA: Si el Cliente detecta el impacto de su espada, le avisa por RPC al Servidor
	if multiplayer.multiplayer_peer != null:
		if not multiplayer.is_server():
			sincronizar_danio_enemigo_2.rpc_id(1, cantidad, origen_danio_x)
			return

	if estado_actual == Estados.HERIDO or estado_actual == Estados.MUERTO:
		return
		
	vida_actual -= cantidad
	print(name, " recibió daño. Vida restante: ", vida_actual)
	
	# Control de audio inteligente según el modo de juego
	if multiplayer.multiplayer_peer != null:
		rpc("reproducir_sonido_red", "danio") # Modo 2 Jugadores (Red RPC)
	else:
		if sonido_danio: sonido_danio.play() # Modo Solo Jugador (Local)
	
	if vida_actual <= 0:
		_morir()
		return
		
	estado_actual = Estados.HERIDO
	hitbox_espada.set_deferred("disabled", true)
	
	var dir_retroceso = 1.0 if global_position.x > origen_danio_x else -1.0
	velocity = Vector2(dir_retroceso * knockback_fuerza, -100.0)
	sprite.play("danio") 


# 🌟 RPC EXCLUSIVO: Recibe los golpes del cliente y los aplica en el Servidor
@rpc("any_peer", "call_local", "reliable")
func sincronizar_danio_enemigo_2(cantidad: int, origen_x: float) -> void:
	if multiplayer.is_server():
		recibir_danio(cantidad, origen_x)


func _morir() -> void:
	print("El enemigo ha muerto. Iniciando secuencia de muerte...")
	estado_actual = Estados.MUERTO
	hitbox_espada.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	sprite.play("death")
	
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
# --- SEÑALES CONECTADAS ---

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		hitbox_espada.set_deferred("disabled", true)
		estado_actual = Estados.PATRULLA 
	elif sprite.animation == "danio":
		estado_actual = Estados.PATRULLA 
	elif sprite.animation == "death":
		_borrar_enemigo_red()


# 🌟 ELIMINACIÓN CENTRALIZADA: Evita el bug del contador de oleadas desfasado
func _borrar_enemigo_red() -> void:
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			queue_free()
	else:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if estado_actual == Estados.ATACANDO and body.has_method("recibir_danio") and body != self:
		# 🌟 CONTROL DE DAÑO SEGURO: El Servidor dictamina cuándo dañar a un jugador
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			print("¡El enemigo acuchilló a un jugador!")
			body.recibir_danio(dano_espada, global_position.x)


# 🌟 RPC DE AUDIO: Se ejecuta en cada pantalla remota de forma sincronizada
@rpc("any_peer", "call_local", "reliable")
func reproducir_sonido_red(tipo_sonido: String) -> void:
	if tipo_sonido == "ataque":
		if sonido_ataque:
			sonido_ataque.play()
	elif tipo_sonido == "danio":
		if sonido_danio:
			sonido_danio.play()
