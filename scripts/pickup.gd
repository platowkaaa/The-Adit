extends StaticBody3D

@export var prompt: String = "pick up"
@export var item_id: String = ""
@export var thought_text: String = ""
@export var pickup_sound: AudioStream

func interact(player: Node) -> void:
	player.add_item(item_id)
	if thought_text != "":
		Story.say(thought_text)
	if pickup_sound:
		var sfx := AudioStreamPlayer.new()
		sfx.stream = pickup_sound
		get_tree().current_scene.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
	queue_free()
