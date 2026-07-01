extends Node2D

@onready var animated_sprite = $Fantasma

func _ready():
	randomize()
	animated_sprite.play("idle")
	mover()

func mover():
	var nueva_pos = Vector2(
		randf_range(position.x - 100, position.x + 100),
		randf_range(position.y - 60, position.y + 60)
	)

	var tween = create_tween()
	tween.tween_property(self, "position", nueva_pos, 2.5)
	tween.finished.connect(mover)
