extends Node2D

@export var amplitud_flotacion: float = 5.0
@export var velocidad_flotacion: float = 2.0
@export var intensidad_pulso: float = 0.08
@export var velocidad_pulso: float = 3.0
@export var rotacion_aura: float = 0.15

@onready var portal_base: Sprite2D = get_node_or_null("PortalBase")
@onready var portal_aura: Sprite2D = get_node_or_null("PortalAura")
@onready var particulas: CPUParticles2D = get_node_or_null("ParticulasPortal")

var posicion_base_original: Vector2
var posicion_aura_original: Vector2
var escala_base_original: Vector2
var escala_aura_original: Vector2

func _ready() -> void:
	if portal_base:
		posicion_base_original = portal_base.position
		escala_base_original = portal_base.scale
	
	if portal_aura:
		posicion_aura_original = portal_aura.position
		escala_aura_original = portal_aura.scale
		portal_aura.modulate.a = 0.35
	
	if particulas:
		particulas.emitting = true

func _process(delta: float) -> void:
	var tiempo: float = Time.get_ticks_msec() / 1000.0
	
	var flotacion: float = sin(tiempo * velocidad_flotacion) * amplitud_flotacion
	var pulso: float = 1.0 + sin(tiempo * velocidad_pulso) * intensidad_pulso
	
	if portal_base:
		portal_base.position.y = posicion_base_original.y + flotacion
		portal_base.scale = escala_base_original * (1.0 + (pulso - 1.0) * 0.35)
	
	if portal_aura:
		portal_aura.position.y = posicion_aura_original.y + flotacion
		portal_aura.scale = escala_aura_original * pulso
		portal_aura.rotation += delta * rotacion_aura
		portal_aura.modulate.a = 0.30 + abs(sin(tiempo * velocidad_pulso)) * 0.25
