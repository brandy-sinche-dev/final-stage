extends Node2D 


@onready var musica_fondo = $AudioStreamPlayer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausar_musica"):
		if musica_fondo:
			musica_fondo.stream_paused = not musica_fondo.stream_paused
