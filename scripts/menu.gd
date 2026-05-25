extends Control

# Obtenemos las referencias de los dos contenedores
@onready var contenedor_principal: VBoxContainer = $ContenedorPrincipal
@onready var contenedor_niveles: VBoxContainer = $ContenedorNiveles


func _ready() -> void:
	# Nos aseguramos de que al arrancar el juego, los niveles estén ocultos
	contenedor_principal.visible = true
	contenedor_niveles.visible = false


func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel1/intro_historia.tscn")


func _on_niveles_pressed() -> void:
	# Ocultamos el menú principal y mostramos los niveles
	contenedor_principal.visible = false
	contenedor_niveles.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_nivel_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel1/nivel_1.tscn")


func _on_nivel_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/nivel2/nivel_2.tscn")


func _on_nivel_3_pressed() -> void:
	pass # Replace with function body.


func _on_nivel_4_pressed() -> void:
	pass # Replace with function body.


func _on_regresar_pressed() -> void:
	# Ocultamos los niveles y mostramos el menu principal
	contenedor_principal.visible = true
	contenedor_niveles.visible = false


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
