extends Control

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel1/intro_historia.tscn")


func _on_niveles_pressed() -> void:
	get_tree().change_scene_to_file("")


func _on_exit_pressed() -> void:
	get_tree().quit()
