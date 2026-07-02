extends Area2D

func _ready():
	# Conectamos la señal para detectar cuándo entra Leo a la zona
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# Comprobamos si lo que cayó es el jugador Leo
	if body.name == "Player" or body.is_in_group("player"):	
		body.morir()
		print("Leo ha caído al vacío.")
