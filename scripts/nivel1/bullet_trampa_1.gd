extends Area2D
@export var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
func _process(delta: float) -> void:
	position += direction * speed * delta
func _on_body_entered(body: Node) -> void:
	if body.has_method("recibir_danio"):
		body.recibir_danio(1,global_position.x)
	queue_free()
func _on_screen_exited() -> void:
	queue_free()
