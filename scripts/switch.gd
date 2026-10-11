extends StaticBody3D

@export var prompt: String = "pull the switch"
@export var required_item: String = ""
@export var thought_locked: String = "The handle's gone. Someone took it off."
@export var thought_locked_2: String = "It must be somewhere close. I should look around."
@export var thought_on: String = "A hum. Power's running somewhere."

@export var blade: Node3D  
@export var blade_angle: float = -180.0  

var is_on: bool = false
var _talking: bool = false    # идёт пара фраз — повторные нажатия не считаются
var _told_once: bool = false  # первая фраза уже была

func _ready() -> void:
	# Рубильник без ручки: ручку сначала надо найти.
	if required_item != "" and blade:
		blade.visible = false

func interact(player: Node) -> void:
	if is_on:
		return

	if required_item != "" and not player.has_item(required_item):
		_say_locked()
		return

	if required_item != "":
		player.remove_item(required_item)
		if blade:
			blade.visible = true

	is_on = true
	if blade:
		var pull := create_tween()
		pull.tween_property(blade, "rotation:z", blade.rotation.z + deg_to_rad(blade_angle), 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	remove_from_group("interactable")
	GameState.throw_switch()

	if thought_on != "":
		Story.say(thought_on)


# Рубильник без ручки. Первый раз — две фразы подряд, дальше только вторая.
func _say_locked() -> void:
	if _talking:
		return
	if _told_once:
		if thought_locked_2 != "":
			Story.say(thought_locked_2)
		return

	_talking = true
	_told_once = true
	Story.say(thought_locked)
	# Ждём, пока первая фраза погаснет: 3 с на экране + 0.6 с затухания (thought_label.gd).
	await get_tree().create_timer(3.6).timeout
	if thought_locked_2 != "":
		Story.say(thought_locked_2)
	_talking = false
