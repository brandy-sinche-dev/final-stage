extends Node2D

@onready var rayo = $AnimatedSprite2D

func _ready():
	randomize()
	rayo.visible = false
	rayo.stop()
	tormenta()

func tormenta():
	while true:
		await get_tree().create_timer(randf_range(1.0, 4.0)).timeout

		rayo.visible = true
		rayo.frame = 0
		rayo.play("default")

		await get_tree().create_timer(0.35).timeout

		rayo.stop()
		rayo.visible = false
