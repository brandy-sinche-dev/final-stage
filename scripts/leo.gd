extends CharacterBody2D

# Configuración de movimiento
const SPEED_WALK = 110.0  
const SPEED_RUN = 170.0   
const JUMP_VELOCITY = -350.0

# Inventario de llaves
var llaves_recolectadas: Array[String] = []

# Estadísticas de Vida y Combate
@export var max_vida: int = 100
var vida_actual: int = max_vida:
	set(valor):
		# 🌟 Usamos el operador directo para guardar el valor sin activar el 'set' otra vez
		vida_actual = valor 
		
		# Evitamos procesar el HUD si la red aún no se inicializa
		if not is_inside_tree(): 
			return
			
		# Cada vez que la red actualice esta variable, le avisamos al HUD local
		if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
			var interfaz = get_tree().get_first_node_in_group("hud")
			if interfaz and interfaz.has_method("actualizar_vida"):
				interfaz.actualizar_vida(vida_actual)

@export var knockback_fuerza: float = 200.0
@export var dano_espada = 15

# Referencias a los nodos hijos
@onready var sprite = $AnimatedSprite2D  
@onready var sword_hitbox = $Visuals/SwordArea/CollisionShape2D 
# El Label flotante sobre la cabeza del personaje
@onready var label_flotante = $LabelFlotante

# Estados del personaje
var esta_en_el_suelo: bool = true
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
			
			# 🌟 EL CAMBIO CLAVE: Si este nodo es el clon de la otra PC,
			# le decimos al Sincronizador que la autoridad de estos datos es el dueño original.
			if has_node("MultiplayerSynchronizer"):
				$MultiplayerSynchronizer.set_multiplayer_authority(id_del_dueno)


func _ready() -> void:
	floor_constant_speed = true
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(46.0)

	await get_tree().process_frame

	if multiplayer.multiplayer_peer != null:
		if is_multiplayer_authority():
			if has_node("Camera2D"):
				$Camera2D.enabled = true
				$Camera2D.make_current()
			_configurar_texto_jugador_dinamico()
		else:
			if has_node("Camera2D"):
				$Camera2D.enabled = false
	else:
		if has_node("Camera2D"):
			$Camera2D.enabled = true
			$Camera2D.make_current()
		if label_flotante:
			label_flotante.text = "Player 1"

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			# 🌟 CLAVE: El clon no procesa movimientos, pero SÍ necesita 
			# actualizar sus animaciones según lo que recibe de la red
			_maquina_visual()
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
	esta_en_el_suelo = is_on_floor() #Guardamos el suelo antes de movernos
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

	if not esta_en_el_suelo:
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


# Calcula el ID de red asignado a la instancia
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
	# 1. FRENO DE SEGURIDAD PARA RED
	var carpeta_jugadores = get_tree().current_scene.get_node_or_null("Jugadores")
	if carpeta_jugadores != null and multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			var id_del_jugador = name.to_int()
			if id_del_jugador != 1 and id_del_jugador != 0:
				sincronizar_danio_jugador.rpc_id(id_del_jugador, cantidad, origen_danio_x)
				return

	# 2. LÓGICA LOCAL DE DAÑO
	# Si ya estamos heridos o muertos, NO hacemos nada (esto evita el bucle)
	if esta_herido or esta_muerto:
		return
		
	# Al restar aquí, el setter de 'vida_actual' se disparará automáticamente.
	# ¡NO llames al HUD manualmente aquí! Deja que el setter lo haga por ti.
	vida_actual -= cantidad  
	
	if sonido_dano:
		sonido_dano.play()
	
	# 3. COMPROBACIÓN DE MUERTE
	if vida_actual <= 0:
		vida_actual = 0 # Aseguramos el valor
		morir()
		return
		
	# 4. ACTIVAR ESTADO DE HERIDO
	esta_herido = true
	esta_atacando = false
	
	var dir_retroceso = 1.0 if global_position.x > origen_danio_x else -1.0
	velocity = Vector2(dir_retroceso * knockback_fuerza, -150.0) 
	if sprite:
		sprite.play("hurt")


func morir() -> void:
	esta_muerto = true
	velocity = Vector2.ZERO
	sprite.play("death") # Asegúrate de que no tenga loop
	
	activar_camara_espectador()
	print("Jugador ", name, " ha muerto.")
	
	# Solicitamos la reaparición pasando nuestro ID único de red
	var mi_id = name.to_int()
	_solicitar_respawn_red(mi_id)


func _solicitar_respawn_red(id: int) -> void:
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			# Si el Host murió, el servidor procesa su propio respawn
			_ejecutar_respawn_en_servidor(id)
		else:
			# Si el Cliente murió, le envía un RPC al Servidor para que lo reviva
			sincronizar_respawn_jugador.rpc_id(1, id)
	else:
		# Modo solitario offline
		_ejecutar_respawn_en_servidor(id)

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
# 🌟 NUEVO RPC: El Servidor obliga a la PC dueña del personaje a recibir el golpe
@rpc("any_peer", "call_local", "reliable")
func sincronizar_danio_jugador(cantidad: int, origen_x: float) -> void:
	# Forzamos la ejecución de la lógica local en la PC correspondiente
	recibir_danio(cantidad, origen_x)

@rpc("any_peer", "call_local", "reliable")
func solicitar_reinicio_global() -> void:
	if multiplayer.is_server():
		get_tree().reload_current_scene()

# 🌟 RPC EXCLUSIVO: El Cliente le pide al Servidor volver a nacer
@rpc("any_peer", "call_local", "reliable")
func sincronizar_respawn_jugador(id_jugador: int) -> void:
	if multiplayer.is_server():
		_ejecutar_respawn_en_servidor(id_jugador)


# 🌟 NUEVA FUNCIÓN: Si muero, mi cámara busca al compañero vivo
func activar_camara_espectador() -> void:
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return # Solo la PC del jugador muerto ejecuta esto localmente
	
	print("Buscando compañero para espectar...")
	var jugadores = get_tree().get_nodes_in_group("player")
	for compañero in jugadores:
		# Buscamos un personaje que NO sea este (el muerto) y que esté vivo
		if compañero != self and not compañero.esta_muerto:
			if compañero.has_node("Camera2D"):
				# Encendemos la cámara del compañero en NUESTRA pantalla
				compañero.get_node("Camera2D").enabled = true
				compañero.get_node("Camera2D").make_current()
				print("Espectando a: ", compañero.name)
				break

# 🌟 LÓGICA MAESTRA EN EL SERVIDOR
func _ejecutar_respawn_en_servidor(id_jugador: int) -> void:
	# 1. Buscamos el mapa o el nodo raíz que tiene el script del mapa (donde está _crear_jugador_en_servidor)
	var mapa = get_tree().current_scene
	
	# 2. Primero eliminamos el cuerpo viejo/muerto del Servidor de forma segura.
	# Como es un nodo controlado por MultiplayerSpawner, al borrarlo aquí, desaparecerá de todas las PCs.
	var contenedor = mapa.get_node_or_null("Jugadores")
	if contenedor and contenedor.has_node(str(id_jugador)):
		var nodo_viejo = contenedor.get_node(str(id_jugador))
		nodo_viejo.queue_free()
	
	# 3. Esperamos un frame para que el motor limpie el nodo viejo por completo antes de spawnear el nuevo
	await get_tree().process_frame
	
	# 4. Llamamos a la función original de tu mapa para volverlo a crear con su ID correcto
	if mapa.has_method("_crear_jugador_en_servidor"):
		mapa._crear_jugador_en_servidor(id_jugador)
		print("SERVIDOR: Respawn exitoso para el jugador ID: ", id_jugador)
