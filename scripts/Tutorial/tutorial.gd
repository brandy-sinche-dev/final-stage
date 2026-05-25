extends Node2D # O el tipo de nodo raíz que sea tu tutorial

# Guardamos la ruta de la escena de niveles. 
# TIP: Puedes arrastrar tu archivo .tscn de niveles desde el FileSystem directamente aquí.
const SCENE_MENU = "res://scenes/menu.tscn" 

func _unhandled_input(event: InputEvent) -> void:
	# Detectamos si se presionó la acción que configuramos en el Input Map
	if event.is_action_pressed("salir_tutorial"):
		_ir_a_niveles()

func _ir_a_niveles() -> void:
	print("Saliendo del tutorial... Cargando mapa de niveles.")
	
	var error = get_tree().change_scene_to_file(SCENE_MENU)
	
	# Validación de seguridad por si escribiste mal la ruta del archivo
	if error != OK:
		print("Error: No se pudo cargar la escena de niveles. Revisa la ruta.")
