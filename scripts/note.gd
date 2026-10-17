extends StaticBody3D

@export var prompt: String = "read"
@export_multiline var pages: PackedStringArray = []
@export var thought_text: String = ""

var was_read: bool = false

func interact(player: Node) -> void:
	var after := ""
	if not was_read:
		was_read = true
		after = thought_text
	player.read_note(pages, after)
