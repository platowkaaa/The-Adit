extends CharacterBody3D
 
 
# --- Движение ---
@export var speed: float = 2.0
@export var mouse_sensitivity: float = 0.002
 
# --- Покачивание головы при ходьбе ---
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.04

# --- Дрожь камеры при побеге ---
@export var shake_amplitude: float = 0.035   
@export var shake_speed: float = 8.0
 
# --- Ноды ---
@onready var newspaper: Control = $CanvasLayer/Newspaper
@onready var head: Node3D = $head
@onready var ray: RayCast3D = $head/RayCast3D
@onready var camera: Camera3D = $head/Camera3D
@onready var prompt_label: Label = $CanvasLayer/Interact/PromptLabel
@onready var note_panel: Control = $CanvasLayer/NotePanel
@onready var blackout: ColorRect = $CanvasLayer/Blackout 
@onready var lamp: Node3D = $head/Lamp
@export var enemy_lamp: Node3D
@export var intro_lines: Array[String] = [
	"The way I came in is gone. The roof's come down.",
	"The only way up now is the cage.",
	"It won't run without power. I'll have to find the switches.",
]

@export var rock_steps: Array[AudioStream] = []
@export var water_steps: Array[AudioStream] = []
@export var step_length: float = 1.0
@onready var steps_player: AudioStreamPlayer = $Steps
@onready var chase_music: AudioStreamPlayer = $ChaseMusic
@onready var run_label: Label = $CanvasLayer/RunLabel
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var continue_button: Button = $CanvasLayer/PauseMenu/paper/VBoxContainer/ContinueButton
@onready var quit_button: Button = $CanvasLayer/PauseMenu/paper/VBoxContainer/QuitButton
var in_water: bool = false
var after_note_thought: String = ""
var step_distance: float = 0.0

# --- Состояние ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var inventory: Array[String] = []
 
var reading: bool = false
var paused: bool = false
var ended: bool = false 
var in_cutscene: bool = false

# --- Лампа не лезет в стены ---
const LAMP_TUCKED := Vector3(0.2, -0.75, -0.25)  
const LAMP_REACH: float = 1.4  
const LAMP_RADIUS: float = 0.2  
var lamp_base_pos: Vector3
var lamp_probe := SphereShape3D.new()
 
var current_target: Node = null
 
# Служебное для покачивания.
var head_base_y: float = 0.0
var bob_time: float = 0.0
 
var shake_time: float = 0.0
var shake_noise:= FastNoiseLite.new()
 
func _ready() -> void:
 
	process_mode = Node.PROCESS_MODE_ALWAYS

	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			window.godotWantsLock = false;
			window.godotLockLost = false;
			const canvas = document.getElementById('canvas') || document.querySelector('canvas');
			const lock = () => {
				if (window.godotWantsLock && document.pointerLockElement !== canvas) {
					canvas.requestPointerLock();
				}
			};
			canvas.addEventListener('mousedown', lock);
			window.addEventListener('keydown', (e) => { if (e.key !== 'Escape') lock(); });
			document.addEventListener('pointerlockchange', () => {
				if (document.pointerLockElement !== canvas && window.godotWantsLock) {
					window.godotLockLost = true;
				}
			});
		""", true)
 
	head_base_y = head.position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	prompt_label.visible = false
	blackout.visible = false
	GameState.time_is_up.connect(_on_time_is_up) 
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	quit_button.visible = not OS.has_feature("web")
	GameState.power_restored.connect(_play_finale_cutscene)
	GameState.escaped.connect(_play_ending)

	shake_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	shake_noise.frequency = 1.0
	shake_noise.seed = randi()

	lamp_base_pos = lamp.position
	lamp_probe.radius = LAMP_RADIUS

	_play_intro()


func _play_intro() -> void:
	in_cutscene = true
	_apply_state()
	await get_tree().create_timer(1.0, false).timeout
	for line in intro_lines:
		Story.say(line)
		await get_tree().create_timer(3.6, false).timeout
	in_cutscene = false
	_apply_state()

func _play_ending() -> void:
	chase_music.stop()
	in_cutscene = true
	_apply_state()

	camera.rotation = Vector3.ZERO

	blackout.modulate.a = 0.0
	blackout.visible = true

	var fade := create_tween()
	fade.tween_property(blackout, "modulate:a", 1.0, 3.0)
	await fade.finished
	in_cutscene = false
	ended = true
	_apply_state()
	newspaper.show_ending(true)

func _play_finale_cutscene() -> void:
	in_cutscene = true
	_apply_state()
	enemy_lamp.visible = true

	var env := get_world_3d().environment.duplicate() as Environment
	get_world_3d().environment = env
	var dark := create_tween().set_parallel(true)
	dark.tween_property(env, "fog_light_color", Color.BLACK, 2.0)
	dark.tween_property(env, "fog_density", 0.0, 2.0)

	var dir := enemy_lamp.global_position - global_position
	var desired_y := atan2(-dir.x, -dir.z)
	var target_y := rotation.y + wrapf(desired_y - rotation.y, -PI, PI)
	var turn := create_tween()
	turn.set_parallel(true)
	turn.tween_property(self, "rotation:y", target_y, 2.0).set_trans(Tween.TRANS_SINE)
	turn.tween_property(head, "rotation:x", 0.0, 2.0).set_trans(Tween.TRANS_SINE)
	await turn.finished

	await get_tree().create_timer(2.0).timeout

	enemy_lamp.visible = false

	var jolt := create_tween()
	jolt.tween_property(camera, "rotation:x", deg_to_rad(8.0), 0.05)
	jolt.tween_property(camera, "rotation:x", 0.0, 0.25)
	await jolt.finished

	await get_tree().create_timer(0.3).timeout

	GameState.blackout.emit()

	in_cutscene = false
	_apply_state()
	GameState.start_escape()
	chase_music.play()

	run_label.modulate.a = 1.0
	run_label.visible = true
	var run_fade := create_tween()
	run_fade.tween_interval(5.0)
	run_fade.tween_property(run_label, "modulate:a", 0.0, 1.0)


func _update_camera_shake(delta: float) -> void:
	if not GameState.escape_running:
		var back := 1.0 - exp(-delta * 8.0)
		camera.rotation.x = lerp(camera.rotation.x, 0.0, back)
		camera.rotation.y = lerp(camera.rotation.y, 0.0, back)
		return

	shake_time += delta * shake_speed


	var left_ratio := GameState.time_left / GameState.ESCAPE_TIME


	var strength := (1.0 - left_ratio) * shake_amplitude


	camera.rotation.x = shake_noise.get_noise_1d(shake_time) * strength
	camera.rotation.y = shake_noise.get_noise_1d(shake_time + 500.0) * strength


func _on_time_is_up() -> void:
	chase_music.stop()
	ended = true
	blackout.visible = true
	newspaper.show_ending(false)
	camera.rotation = Vector3.ZERO
	_apply_state() 

func is_busy() -> bool:
	return reading or paused or ended or in_cutscene
 

func read_note(pages: PackedStringArray, thought: String = "") -> void:
	after_note_thought = thought
	note_panel.show_note(pages)
	set_reading(true)

 
func set_reading(value: bool) -> void:
	reading = value

	if not value:
		note_panel.hide_note()
		if after_note_thought != "":
			Story.say(after_note_thought)
			after_note_thought = ""

	_apply_state()
 

func set_paused(value: bool) -> void:
	paused = value
	pause_menu.visible = value
	_apply_state()


func _on_continue_pressed() -> void:
	set_paused(false)


func _on_quit_pressed() -> void:
	get_tree().quit()
 
 
func _apply_state() -> void:
	var world_stopped: bool = reading or paused or ended
	get_tree().paused = world_stopped
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.godotWantsLock = %s;" % ("false" if world_stopped else "true"), true)
	if world_stopped:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if is_busy():
		prompt_label.visible = false
 
 
func add_item(item: String) -> void:
	if not has_item(item):
		inventory.append(item)
 
 
func has_item(item: String) -> bool:
	return item in inventory
 
 
func remove_item(item: String) -> void:
	inventory.erase(item)
 
 
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ended:
			return

		if reading:
			set_reading(false)
		else:
			set_paused(not paused)
		return


	if reading and event.is_action_pressed("interact"):
		if not note_panel.next_page():
			set_reading(false)
		return

	if is_busy():
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90.0), deg_to_rad(90.0))
		return

	if event.is_action_pressed("interact") and is_instance_valid(current_target):
		current_target.interact(self)
		return
 
 
func _process(delta: float) -> void:
	if OS.has_feature("web"):
		_check_web_mouse()

	if is_busy():
		return

	_update_target()
	_update_head_bob(delta)
	_update_camera_shake(delta)
 
 
func _update_target() -> void:
	current_target = _find_target()
 
	if current_target != null:
		prompt_label.text = "[E] %s" % _get_prompt(current_target)
		prompt_label.visible = true
	else:
		prompt_label.visible = false
 
 
func _find_target() -> Node:
	if not ray.is_colliding():
		return null
 
	var obj = ray.get_collider()
	if obj is Node and obj.is_in_group("interactable") and obj.has_method("interact"):
		return obj
 
	return null
 
 
func _get_prompt(obj: Node) -> String:
	if "prompt" in obj:
		return str(obj.prompt)
	return "examine"
 
 
func _update_head_bob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
 
	if is_on_floor() and horizontal_speed > 0.1:
		bob_time += delta * horizontal_speed * bob_frequency
		head.position.y = head_base_y + sin(bob_time) * bob_amplitude
	else:
		head.position.y = lerp(head.position.y, head_base_y, 1.0 - exp(-delta * 8.0))
		bob_time = 0.0
 
 
func _physics_process(delta: float) -> void:
	if is_busy():
		return
 
	if not is_on_floor():
		velocity.y -= gravity * delta
 
	var current_speed := speed
	if Input.is_action_pressed("accelerate"):
		current_speed *= 1.5
 
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
 
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
 
	move_and_slide()
	_update_steps(delta)
	_update_lamp_pushback(delta)



func _update_lamp_pushback(delta: float) -> void:
	var from := head.global_position
	var center := lamp_base_pos + Vector3(0.0, 0.08, 0.0)  # середина лампы, а не пламя
	var to := head.to_global(center * LAMP_REACH)

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = lamp_probe
	query.transform = Transform3D(Basis(), from)
	query.motion = to - from
	query.exclude = [get_rid()]
	var free_part: float = get_world_3d().direct_space_state.cast_motion(query)[0]

	var target := lamp_base_pos.lerp(LAMP_TUCKED, 1.0 - free_part)
	lamp.position = lamp.position.lerp(target, 1.0 - exp(-delta * 12.0))


func _update_steps(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horizontal_speed < 0.1:
		step_distance = step_length
		return

	step_distance += horizontal_speed * delta
	if step_distance < step_length:
		return
	step_distance = 0.0

	var sounds := water_steps if in_water else rock_steps
	if sounds.is_empty():
		return
	steps_player.stream = sounds.pick_random()
	steps_player.pitch_scale = randf_range(0.9, 1.1)
	steps_player.play()


func _check_web_mouse() -> void:
	if JavaScriptBridge.eval("window.godotLockLost === true", true):
		JavaScriptBridge.eval("window.godotLockLost = false;", true)
		if not paused and not reading and not ended:
			set_paused(true)
