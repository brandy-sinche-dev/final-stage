extends CanvasLayer

@onready var fondo = $ColorRect 

func _ready() -> void:
	add_to_group("game_over")
	fondo.modulate.a = 0 # Aseguramos que empiece invisible
	self.visible = false

func activar_game_over() -> void:
	self.visible = true
	# Animación simple de fundido a negro
	var tween = create_tween()
	tween.tween_property(fondo, "modulate:a", 1.0, 2.0) # Oscurece en 2 segundos
	
	await tween.finished
	await get_tree().create_timer(1.0).timeout # Espera un segundo con el mensaje
	
	fondo.modulate.a = 0
	self.visible = false
	
	# Regresa al menú principal
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
