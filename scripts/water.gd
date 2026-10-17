extends MeshInstance3D

@export var player: CharacterBody3D

var _mat: ShaderMaterial
var _moving: float = 0.0


func _ready() -> void:
	_mat = material_override as ShaderMaterial


func _process(delta: float) -> void:
	if player == null or _mat == null:
		return
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var target := clampf(speed / 1.5, 0.0, 1.0)
	_moving = lerpf(_moving, target, minf(delta * 3.0, 1.0))
	_mat.set_shader_parameter("player_pos", player.global_position)
	_mat.set_shader_parameter("player_moving", _moving)

	var local := to_local(player.global_position)
	var half := (mesh as PlaneMesh).size / 2.0
	var inside := absf(local.x) < half.x and absf(local.z) < half.y
	var below := player.global_position.y < global_position.y + 0.1
	player.set("in_water", inside and below)
