extends StaticBody3D

@export var prompt: String = "ride up"
@export var thought_locked: String = "The cage won't move. The last switch is still off."
@export var required_switches: int = 3


var is_open: bool = false


func interact(player: Node) -> void:
	if is_open: 
		return
	
	if GameState.switches_on < required_switches:
		Story.say(thought_locked)
		return
	_open()
	
func _open() -> void:
	is_open = true
	remove_from_group("interactable")
	GameState.enter_cage() 
