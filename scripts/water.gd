extends MeshInstance3D

# Сообщает шейдеру воды, где игрок и идёт ли он, — для кругов на воде.

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
	_moving = lerpf(_moving, target, minf(delta * 3.0, 1.0))  # круги затухают плавно, а не пропадают разом
	_mat.set_shader_parameter("player_pos", player.global_position)
	_mat.set_shader_parameter("player_moving", _moving)
