extends CharacterBody2D # Cambia 'Node' por 'CharacterBody2D'

func _ready():
	$AnimatedSprite2D.play("ataque")
