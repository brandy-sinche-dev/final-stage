extends Control

@onready var boton_reanudar = $CanvasLayer/VBoxContainer/reanudar
@onready var boton_reiniciar = $CanvasLayer/VBoxContainer/reiniciar
@onready var boton_salir = $CanvasLayer/VBoxContainer/salir
@onready var canvas = $CanvasLayer

func _ready() -> void:
	hide()
	canvas.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Asegura que procese siempre

	boton_reanudar.pressed.connect(_on_reanudar_pressed)
	boton_reiniciar.pressed.connect(_on_reiniciar_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)

func _input(event: InputEvent) -> void:
	# Detección directa de la tecla Escape física
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			alternar_pausa()
			

func alternar_pausa() -> void:
	var esta_pausado = get_tree().paused
	
	if esta_pausado:
		hide()
		canvas.visible = false
		get_tree().paused = false
	else:
		show()
		canvas.visible = true
		get_tree().paused = true

func _on_reanudar_pressed() -> void:
	alternar_pausa()

func _on_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_salir_pressed() -> void:
	get_tree().paused = false
	PlayerData.resetear_datos()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
