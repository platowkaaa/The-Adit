extends StaticBody3D

@export var prompt: String = "pick up"
@export var item_id: String = ""
@export var thought_text: String = ""

func interact(player: Node) -> void:
	player.add_item(item_id)
	if thought_text != "":
		Story.say(thought_text)
	queue_free()
