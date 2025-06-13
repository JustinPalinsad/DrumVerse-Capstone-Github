extends Control

#variables ng animation player sa code
@onready var text_animPlayer = $"Tap Anywhere/Text Animation" #for text
@onready var drum_animPlayer = $"Drum/Drum Animation" #for drum

func _ready() -> void:
	text_animPlayer.play("text_blink_animation")
	
func _on_start_button_pressed() -> void:
	text_animPlayer.play("text_blink_faster_animation")
	drum_animPlayer.play("drum_bounce_animation")
	$ClickSoundPlayer.play()
	await get_tree().create_timer(0.2).timeout
	print("Going to Main Menu...!")
	await text_animPlayer.animation_finished
	get_tree().change_scene_to_file("res://Menu Scenes/main_menu.tscn")
