extends StaticBody3D

@export var prompt: String = "read"
@export_multiline var pages: PackedStringArray = []
@export var thought_text: String = ""

var was_read: bool = false

func interact(player: Node) -> void:
	player.read_note(pages)

	if not was_read:
		was_read = true
		if thought_text != "":
			Story.say(thought_text)
