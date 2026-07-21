# player_data.gd
extends Node

signal datos_cambiados

var vida_actual: int = 100:
	set(valor):
		vida_actual = valor
		datos_cambiados.emit() # Avisamos a todos los interesados

var corazones_restantes: int = 3:
	set(valor):
		corazones_restantes = valor
		datos_cambiados.emit() # Avisamos a todos los interesados

var es_partida_local: bool = true # Por defecto es local
func resetear_datos():
	vida_actual = 100
	corazones_restantes = 3
