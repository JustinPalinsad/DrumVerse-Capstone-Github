@tool
extends Node2D

@onready var loading_label: Label = $LoadingLabel
@onready var timer: Timer = Timer.new()

var base_text := "Loading"
var dot_count := 0
var max_dots := 3

var mode: String = ""
var drum_module: Resource = null  # ✅ Fixed type

func _ready():
	loading_label.text = base_text
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)

	await get_tree().create_timer(1.5).timeout
	load_game_scene()

func _on_timer_timeout():
	dot_count = (dot_count + 1) % (max_dots + 1)
	loading_label.text = base_text + ".".repeat(dot_count)

func load_game_scene():
	var next_scene_path := ""

	if mode == "learning":
		next_scene_path = "res://Scenes/Modes/learning_mode.tscn"
	else:
		next_scene_path = "res://Scenes/game_scene.tscn"

	var next_scene = load(next_scene_path) as PackedScene
	var instance = next_scene.instantiate()
	instance.mode = mode

	if mode == "learning":
		instance.learning_module = drum_module  # ✅ For Learning Mode
	else:
		instance.drum_module = drum_module  # ✅ For Practice/Challenge

	get_tree().root.add_child(instance)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = instance
