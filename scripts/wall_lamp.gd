extends StaticBody3D

@export var prompt: String = "light"
@export var thought_text: String = ""
@onready var light: OmniLight3D = $OmniLight3D
@onready var lantern: Node3D = $lantern
@export var sound: AudioStreamPlayer3D

var is_lit: bool = false


func _ready() -> void:
	if OS.has_feature("web"):
		light.shadow_enabled = false
	light.visible = false
	lantern.set_lit(false)
	GameState.blackout.connect(_on_blackout)


func interact(_player: Node) -> void:
	if is_lit:
		return

	is_lit = true
	light.visible = true
	lantern.set_lit(true)
	if sound:
		sound.play()

	remove_from_group("interactable")

	if thought_text != "":
		Story.say(thought_text)


func _on_blackout() -> void:
	light.visible = false
	lantern.set_lit(false)
