extends Node2D

@onready var sprite = $AnimatedSprite2D

var tiempo := 0.0
var escala_inicial := Vector2.ONE

func _ready():
	sprite.play("idle")
	escala_inicial = scale

func _process(delta):
	tiempo += delta

	# Pequeña variación de tamaño
	scale = escala_inicial + Vector2.ONE * sin(tiempo * 2.0) * 0.03

	# Ligera variación del brillo
	modulate = Color(
		1.0,
		1.0,
		1.0,
		0.85 + sin(tiempo * 3.0) * 0.15
	)
