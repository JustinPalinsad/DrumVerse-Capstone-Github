extends Control

@onready var anim_player = $"Selection Container/Selection Animation"

var current_index := 1
const STEP := 0.3  # time step between button states

var target_time := 0.0
var is_animating := false
var animation_direction := 1  # 1 for forward, -1 for backward

func _ready():
	# Play the animation, then pause it at 0.0 to prevent auto-loop
	anim_player.play("menu_animation")	
	anim_player.seek(0.3, true)
	anim_player.pause()

func _unhandled_input(event):
	if is_animating:
		return  # Prevent spamming during animation

	# Enforce directional limits based on the current position (index)
	match current_index:
		0:
			if event.is_action_pressed("ui_right"):
				$ClickSoundPlayer.play()
				await get_tree().create_timer(0.1).timeout
				current_index = 1
				_play_to_index(current_index)
		1:
			if event.is_action_pressed("ui_right"):
				$ClickSoundPlayer.play()
				await get_tree().create_timer(0.1).timeout
				current_index = 2
				_play_to_index(current_index)
			elif event.is_action_pressed("ui_left"):
				$ClickSoundPlayer.play()
				await get_tree().create_timer(0.1).timeout
				current_index = 0
				_play_to_index(current_index)
		2:
			if event.is_action_pressed("ui_left"):
				$ClickSoundPlayer.play()
				await get_tree().create_timer(0.1).timeout
				current_index = 1
				_play_to_index(current_index)

func _play_to_index(index: int):
	# Calculate target time with a small offset to prevent exact boundary issues
	target_time = clamp(index * STEP, 0.0, anim_player.current_animation_length - 0.001)
	var current_time = anim_player.current_animation_position

	if is_equal_approx(current_time, target_time):
		return  # Already at correct time

	animation_direction = sign(target_time - current_time)

	# Play the animation in the correct direction
	anim_player.play("menu_animation")
	anim_player.speed_scale = animation_direction



	is_animating = true

func _process(_delta):
	if is_animating:
		var current_time = anim_player.current_animation_position
		# Check if we've reached or passed the target time
		if (animation_direction > 0 and current_time >= target_time) or \
		   (animation_direction < 0 and current_time <= target_time):
			anim_player.seek(target_time, true)

			anim_player.pause()
			is_animating = false


func _on_select_button_pressed() -> void:
	$BackSoundPlayer.play()
	await get_tree().create_timer(0.5).timeout
	match current_index:
		0:
			print("Notes")
			get_tree().change_scene_to_file("res://Menu Scenes/notes_scene.tscn")
			#go to notes scene
		1:
			print("Play")
			get_tree().change_scene_to_file("res://Sample/sample_selection.tscn")
			#go to play scene / sample selection scene
		2: 
			print("Settings")	
			print("Settings")
			get_tree().change_scene_to_file("res://Menu Scenes/settings_scene.tscn")
			#go to settings

func _on_back_pressed() -> void:
	$BackSoundPlayer.play()
	await get_tree().create_timer(0.2).timeout
	#return to title screen
	get_tree().change_scene_to_file("res://Menu Scenes/title_screen.tscn")
