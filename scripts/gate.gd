extends StaticBody3D

@export var prompt: String = "open"
@export var required_item: String = ""
@export var thought_locked: String = "Locked."
@export var thought_open: String = ""
@export var thought_no_power: String = "Not yet. I should throw the switch first."
@export var required_switches: int = 0
@onready var collision: CollisionShape3D = $CollisionShape3D
@export var door: Node3D  
@export var open_angle: float = 100.0  
@export var sound: AudioStreamPlayer3D

var is_open: bool = false


func interact(player: Node) -> void:
	if is_open:
		return

	if required_item != "" and not player.has_item(required_item):
		Story.say(thought_locked)
		return
	
	if GameState.switches_on < required_switches:
		Story.say(thought_no_power)
		return
		
	_open()


func _open() -> void:
	is_open = true
	remove_from_group("interactable")

	if door:
		var swing := create_tween()
		swing.tween_property(door, "rotation:y", door.rotation.y + deg_to_rad(open_angle), 1.2).set_trans(Tween.TRANS_SINE)

	if sound:
		sound.play()

	collision.set_deferred("disabled", true)

	if thought_open != "":
		Story.say(thought_open)
