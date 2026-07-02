extends Node

var click_sound: AudioStreamPlayer

func _ready():
	click_sound = AudioStreamPlayer.new()
	click_sound.stream = load("res://ost/menu/boton.wav") # Pon tu ruta real aquí
	add_child(click_sound)

func reproducir_click():
	if click_sound:
		click_sound.play()
