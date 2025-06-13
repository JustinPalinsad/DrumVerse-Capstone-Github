extends Control

var total_hits = 0
var total_notes = 0
var total_misses = 0
var hit_percentage = 0.0
var grade = "N/A"
var mode = "practice"  # This is passed from the game scene

func _ready():
	$VBoxContainer/HitsLabel.text = "Hits: %d / %d" % [total_hits, total_notes]
	$VBoxContainer/MissesLabel.text = "Misses: %d" % total_misses
	$VBoxContainer/AccuracyLabel.text = "Accuracy: " + str(round(hit_percentage * 10) / 10.0) + "%"
	$VBoxContainer/GradeLabel.text = "Grade: %s" % grade

	$VBoxContainer/HBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

func _on_menu_pressed():
	$ClickSoundPlayer.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Menu Scenes/main_menu.tscn")
	queue_free()  #  Remove this results scene
