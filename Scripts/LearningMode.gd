extends Node2D

@onready var background: ColorRect = $Background
@onready var label1: Label = $CanvasLayer/Label1
@onready var label2: Label = $CanvasLayer/Label2
@onready var repeat_button: Button = $CanvasLayer/RepeatButton
@onready var continue_button: Button = $CanvasLayer/ContinueButton
@onready var line_4_4: TextureRect = $"44"
@onready var notes_container: Node2D = $NotesContainer
@onready var demo_animator: AnimationPlayer = $DemoAnimator
@onready var moving_circle: Node2D = $MovingCircle
@onready var metronome_player: AudioStreamPlayer2D = $MetronomePlayer
@onready var hit_sound_player: AudioStreamPlayer2D = $HitSoundPlayer
@onready var metronome_timer: Timer = $MetronomeTimer

var instructions: Array[String] = [
	"Welcome to Drumverse Learning Mode!",
	"Here you'll learn the basics of playing.",
	"First, let's understand the notes...",
	"4/4 time (which is the most common time signature), one quarter note equals one beat.",
	"Now, watch the demo to see how it works."
]
var current_instruction_index: int = 0
var notes: Array[Node2D] = []
var hit_radius: float = 4
var is_demo_active: bool = false
var demo_played: bool = false
var notes_hit_in_demo: Dictionary = {}
var active_hit_effects: Array[Node2D] = []
var beats_per_measure: int = 4
var tempo_bpm: float = 60  # Check and adjust if needed for testing
var beat_interval: float
var original_circle_pos: Vector2  # 💡 Store starting position
var travel_distance: float = 1600.0  # Distance the circle should move over a full measure

func _ready():
	label2.visible = false
	notes_container.visible = false
	repeat_button.visible = false
	continue_button.visible = true
	demo_animator.stop()
	moving_circle.visible = false

	if is_instance_valid(line_4_4):
		line_4_4.visible = false

	for child in notes_container.get_children():
		if child is Node2D and child.has_node("Sprite2D"):
			notes.append(child)

	update_instruction_text()
	continue_button.pressed.connect(_on_continue_button_pressed)
	repeat_button.pressed.connect(_on_repeat_button_pressed)
	demo_animator.animation_finished.connect(_on_demo_finished)
	metronome_timer.timeout.connect(_on_metronome_timeout)

	_calculate_beat_interval()
	original_circle_pos = moving_circle.position  # 🟢 Save initial position

func _calculate_beat_interval():
	beat_interval = 60.0 / tempo_bpm

func update_instruction_text():
	if current_instruction_index < instructions.size():
		label1.text = instructions[current_instruction_index]

		match current_instruction_index:
			2:
				label2.text = "These are the notes you'll be playing."
				label2.visible = true
				notes_container.visible = true
				if is_instance_valid(line_4_4):
					line_4_4.visible = true
			3:
				label2.text = "A quarter note is a basic unit of rhythm in music.\nIn 4/4 time, one quarter note = 1 beat.\n\nIn 4/4 time, there are 4 quarter notes per measure."
				label2.visible = true
				notes_container.visible = true
				if is_instance_valid(line_4_4):
					line_4_4.visible = true
			_:
				label2.visible = false
				notes_container.visible = false
				if is_instance_valid(line_4_4):
					line_4_4.visible = false

		if current_instruction_index == instructions.size() - 1:
			continue_button.text = "Watch Demo"
		else:
			continue_button.text = "Next"
	else:
		label1.visible = false
		label2.visible = false
		continue_button.visible = true
		repeat_button.visible = true
		moving_circle.visible = true
		notes_container.visible = true
		if is_instance_valid(line_4_4):
			line_4_4.visible = true
		start_demo()
		set_process(true)

func _on_continue_button_pressed():
	if current_instruction_index < instructions.size() - 1:
		current_instruction_index += 1
		update_instruction_text()
	elif !demo_played:
		demo_played = true
		current_instruction_index += 1
		update_instruction_text()
		start_demo()

func start_demo():
	notes_hit_in_demo.clear()
	is_demo_active = true
	moving_circle.visible = true
	moving_circle.position = original_circle_pos  # 🔁 Reset to original position on demo start
	_clear_hit_effects()

	metronome_timer.start(beat_interval)
	metronome_player.play()

	var demo_animation = demo_animator.get_animation("demo")
	if demo_animation:
		demo_animation.loop_mode = Animation.LOOP_NONE
		demo_animator.stop()
		demo_animator.play("demo")
		demo_animator.speed_scale = 1.0

func _on_repeat_button_pressed():
	start_demo()

func _on_demo_finished(anim_name: String):
	if anim_name == "demo":
		is_demo_active = false
		moving_circle.visible = false
		metronome_timer.stop()

func _process(delta):
	if is_demo_active:
		# 🚀 Move the circle horizontally based on tempo
		var speed = 200  # Simple fixed speed for testing
		moving_circle.position.x += speed * delta

		# Debugging: Print the speed value
		print("Speed: ", speed)

		# 🔁 Optional wrap-around if it goes off-screen
		if moving_circle.position.x > original_circle_pos.x + travel_distance:
			print("Circle wrapped around!")
			moving_circle.position.x = original_circle_pos.x

		# 💥 Check note hits
		for note in notes:
			if note.has_method("get_global_position") and moving_circle.has_method("get_global_position") and note.has_node("Sprite2D"):
				var distance = note.get_global_position().distance_to(moving_circle.get_global_position())
				if distance < hit_radius and !notes_hit_in_demo.has(note):
					var hit_effect_instance = spawn_hit_effect(moving_circle.get_global_position())
					notes_hit_in_demo[note] = true
					active_hit_effects.append(hit_effect_instance)
					hit_sound_player.play()
					print("Hit sound played!")
					break

func spawn_hit_effect(hit_position: Vector2):
	var hit_effect_scene = load("res://Scenes/Shared/HitEffect.tscn")
	if hit_effect_scene:
		var hit_effect_instance = hit_effect_scene.instantiate()
		hit_effect_instance.global_position = hit_position
		hit_effect_instance.z_index = 10
		add_child(hit_effect_instance)
		return hit_effect_instance

func _clear_hit_effects():
	for effect in active_hit_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	active_hit_effects.clear()

func _on_metronome_timeout():
	metronome_player.play()
