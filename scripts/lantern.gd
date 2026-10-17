extends Node3D

@export var lit: bool = true

@onready var flame: MeshInstance3D = $tank/glass/Flame/FlameSprite
@onready var glass: MeshInstance3D = $tank/glass

var glow: float


func _ready() -> void:
	glow = glass.get_surface_override_material(0).emission_energy_multiplier
	set_lit(lit)


func set_lit(on: bool) -> void:
	lit = on
	flame.visible = on
	glass.get_surface_override_material(0).emission_energy_multiplier = glow if on else 0.0
