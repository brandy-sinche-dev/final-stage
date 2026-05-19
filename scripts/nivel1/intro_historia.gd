extends CanvasLayer

# REFERENCIAS A LOS NODOS
@onready var camara: Camera2D = $SubViewportContainer/SubViewport/CamaraCinematica
@onready var texto_narrador: RichTextLabel = $CajaTexto/TextoNarrador
@onready var fondo_negro: ColorRect = $FondoNegro # Nuestra pantalla de transición

# Imágenes
@onready var v1_torre: Sprite2D = $SubViewportContainer/SubViewport/TorreSuelo
@onready var v2_caballeros: Sprite2D = $SubViewportContainer/SubViewport/CaballerosCaidos
@onready var v3_leo: Sprite2D = $SubViewportContainer/SubViewport/LeoPresentacion

# CONFIGURACIÓN DE LA HISTORIA
var textos: Array = [
	"Hace miles de años, la tierra tembló y del suelo brotó una torre gigante. No la construyó ninguna persona; apareció por arte de magia.",
	"Durante siglos, caballeros con armaduras pesadas intentaron subir, pero todos fallaron porque la torre está llena de trampas mortales.",
	"Leo, un joven que lleva la ligera 'Espada de Ráfaga', decide entrar para demostrar que puede llegar al piso final y entender sus secretos."
]

@onready var viñetas: Array = [v1_torre, v2_caballeros, v3_leo]

# VARIABLES DE CONTROL
var indice_actual: int = 0
var velocidad_letra: float = 0.04 
var terremoto_fuerza: float = 4.0 
var esta_temblando: bool = false
var texto_terminado: bool = false
var transicionando: bool = false # Nueva variable para bloquear el Enter durante el fundido
var tween_texto: Tween

func _ready() -> void:
	print("--- INTRO: Sistema con Fundido a Negro ---")
	v1_torre.visible = true
	v2_caballeros.visible = false
	v3_leo.visible = false
	fondo_negro.modulate.a = 0.0 # Aseguramos que inicie invisible
	
	ejecutar_escena_actual(true)

func _process(_delta: float) -> void:
	if esta_temblando:
		camara.offset = Vector2(
			randf_range(-terremoto_fuerza, terremoto_fuerza),
			randf_range(-terremoto_fuerza, terremoto_fuerza)
		)
	else:
		camara.offset = Vector2.ZERO

func ejecutar_escena_actual(con_terremoto: bool) -> void:
	texto_terminado = false
	texto_narrador.text = textos[indice_actual]
	texto_narrador.visible_ratio = 0.0
	
	if con_terremoto:
		esta_temblando = true
		await get_tree().create_timer(1.5).timeout
		esta_temblando = false
		await get_tree().create_timer(0.3).timeout
	
	tween_texto = create_tween()
	var tiempo_escritura = textos[indice_actual].length() * velocidad_letra
	tween_texto.tween_property(texto_narrador, "visible_ratio", 1.0, tiempo_escritura)
	tween_texto.tween_callback(func(): texto_terminado = true)

func _input(event: InputEvent) -> void:
	# Si estamos en medio de un desvanecimiento, ignoramos los botones del jugador
	if transicionando:
		return
		
	if event.is_action_pressed("ui_accept"):
		if not texto_terminado:
			if tween_texto and tween_texto.is_running():
				tween_texto.kill()
			texto_narrador.visible_ratio = 1.0
			texto_terminado = true
		else:
			avanzar_viñeta()

func avanzar_viñeta() -> void:
	transicionando = true # Bloqueamos interacciones
	
	# FASE A: Desvanecer a negro (La pantalla se oscurece en 0.5 segundos)
	var tween_fade_in = create_tween()
	texto_narrador.text = "" # Limpiamos el texto viejo antes del fundido
	tween_fade_in.tween_property(fondo_negro, "modulate:a", 1.0, 0.5)
	await tween_fade_in.finished
	
	# FASE B: El cambio secreto (Ocurre mientras todo está en negro)
	viñetas[indice_actual].visible = false
	indice_actual += 1
	
	if indice_actual >= textos.size():
		terminar_introduccion()
		return
		
	viñetas[indice_actual].visible = true
	await get_tree().create_timer(0.2).timeout # Pequeña pausa dramática a oscuras
	
	# FASE C: Desvanecer el negro (Se revela la nueva viñeta en 0.5 segundos)
	var tween_fade_out = create_tween()
	tween_fade_out.tween_property(fondo_negro, "modulate:a", 0.0, 0.5)
	await tween_fade_out.finished
	
	transicionando = false # Desbloqueamos el control
	ejecutar_escena_actual(false)

func terminar_introduccion() -> void:
	# Un último fundido lento antes de iniciar el mapa
	var tween_final = create_tween()
	tween_final.tween_property(fondo_negro, "modulate:a", 1.0, 1.0)
	await tween_final.finished
	get_tree().change_scene_to_file("res://scenes/nivel1/nivel_1.tscn")
