extends CanvasLayer # 🚨 CORREGIDO: Ahora coincide con tu nodo raíz CanvasLayer

# 🚨 CORRECCIÓN DE RUTA: 
# Desde el CanvasLayer entramos a HUD -> ContenedorVida -> barravida
# (Asegúrate de escribir las mayúsculas/minúsculas exactamente como las tienes en el editor)
@onready var barra_vida = $"HUD/ContenedorVida/BarraVida"

func _ready() -> void:
	print("--- ¡ALERTA! El HUD en CanvasLayer ha iniciado correctamente ---")
	
	if barra_vida == null:
		print("HUD ERROR: No se encontró el nodo 'barravida'. Revisa las mayúsculas en la ruta.")
		return
		
	# Esperamos un cuadro para asegurar que Leo ya está en el mapa
	await get_tree().process_frame
	
	var leo = get_tree().get_first_node_in_group("player")
	if leo:
		barra_vida.max_value = leo.max_vida
		barra_vida.value = leo.vida_actual
		print("HUD: Conectado a Leo con éxito. Vida actual: ", barra_vida.value)
	else:
		print("HUD ADVERTENCIA: No se encontró a Leo en el grupo 'player'.")

func actualizar_vida(vida_nueva: int) -> void:
	if barra_vida:
		print("HUD: Actualizando barra visual a: ", vida_nueva)
		barra_vida.value = vida_nueva
