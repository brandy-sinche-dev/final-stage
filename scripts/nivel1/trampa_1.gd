extends Node2D
@export var bullet_scene: PackedScene
@export var shoot_direction: Vector2 = Vector2.LEFT
@onready var shoot_point: Marker2D = $ShootPoint
@onready var shoot_timer: Timer = $ShootTimer
func _ready() -> void:
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
func _on_shoot_timer_timeout() -> void:
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = shoot_point.global_position
	bullet.direction = shoot_direction.normalized()
	get_tree().current_scene.add_child(bullet)
