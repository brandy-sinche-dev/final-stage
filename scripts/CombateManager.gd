extends Node

# --- Control de Enemigos hacia Leo ---
var ultimo_golpe_tiempo: float = 0.0
@export var tregua_ataque: float = 0.4

func solicitar_permiso_danio() -> bool:
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	if tiempo_actual - ultimo_golpe_tiempo >= tregua_ataque:
		ultimo_golpe_tiempo = tiempo_actual
		return true
	return false

# --- 🚨 NUEVO: Control de Leo hacia Enemigos 🚨 ---
# Esta variable nos dirá si el ataque actual de Leo ya golpeó a un monstruo
var leo_ya_golpeo_en_este_ataque: bool = false

func iniciar_nuevo_ataque_leo():
	# Cada vez que Leo presione el botón de atacar, reseteamos el réferi
	leo_ya_golpeo_en_este_ataque = false

func leo_puede_hacer_danio() -> bool:
	# Si Leo NO ha golpeado a nadie en este espadazo, le damos permiso
	if not leo_ya_golpeo_en_este_ataque:
		leo_ya_golpeo_en_este_ataque = true # Bloqueamos inmediatamente para los siguientes enemigos
		return true # Permiso concedido para el primer enemigo
	
	return false # Permiso denegado para el resto que estén amontonados
