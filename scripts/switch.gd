extends StaticBody3D

@export var prompt: String = "повернуть рубильник"
@export var required_item: String = ""
@export var thought_locked: String = "Пусто. Предохранитель выгорел."
@export var thought_on: String = "Гудит. Где-то пошло электричество."

@export var blade: Node3D  
@export var blade_angle: float = -180.0  

var is_on: bool = false

func interact(player: Node) -> void:
	if is_on:
		return

	if required_item != "" and not player.has_item(required_item):
		if thought_locked != "":
			Story.say(thought_locked)
		return

	if required_item != "":
		player.remove_item(required_item)

	is_on = true
	if blade:
		var pull := create_tween()
		pull.tween_property(blade, "rotation:z", blade.rotation.z + deg_to_rad(blade_angle), 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	remove_from_group("interactable")
	GameState.throw_switch()

	if thought_on != "":
		Story.say(thought_on)
