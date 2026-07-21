extends VideoStreamPlayer

# Esto creará una casilla en el Inspector para que arrastres tu escena del menú
@export var escena_menu: PackedScene

func _on_finished():
	if escena_menu:
		get_tree().change_scene_to_packed(escena_menu)

func _input(event):
	# Permite saltar la intro presionando Espacio o Enter
	if event.is_action_pressed("ui_accept") and escena_menu:
		get_tree().change_scene_to_packed(escena_menu)
