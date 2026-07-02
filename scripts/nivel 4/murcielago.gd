extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

var area_x_min := 100
var area_x_max := 1800
var area_y_min := 80
var area_y_max := 400

func _ready():
	randomize()
	animated_sprite.play("fly")
	volar()

func volar():
	var nueva_pos = Vector2(
		randf_range(area_x_min, area_x_max),
		randf_range(area_y_min, area_y_max)
	)

	animated_sprite.flip_h = nueva_pos.x < position.x

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var duracion = randf_range(1.5, 3.0)
	tween.tween_property(self, "position", nueva_pos, duracion)

	await tween.finished
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout

	volar()
