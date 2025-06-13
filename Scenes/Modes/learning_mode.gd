extends Node2D

# Removed export — we now use GameState.selected_module
@export var learning_module: Resource = null
@export var hit_effect_scene: PackedScene
@export var miss_effect_scene: PackedScene

const NOTE_Y_POSITION := 460
const HIT_RADIUS := 25.0

var slide_control
var notes_container
var hitline_sprite
var moving_circle
var animation_player
var replay_button
var effects_container
var metronome
var countdown_label
var countdown_audio_player
var hit_sound_player
var note_pattern_label


var notes: Array[Node2D] = []
var mode: String = "learning"
var drum_module: DrumModuleData = null
var slide_index := 0
var bottom_index := 0
var showing_bottom := true
var try_slide_started := false
var input_enabled := true
var input_event_handled := false
var input_cooldown_timer: Timer

func _ready() -> void:
	if learning_module == null:
		learning_module = GameState.selected_learning_module  # ✅ Fallback if not set by loading screen

	if learning_module:
		print("✅ Loaded in Learning Mode:", learning_module)
	else:
		push_error("❌ No learning module provided!")
	
	slide_control = $SlideControl
	notes_container = $NotesContainer
	hitline_sprite = $HitLine/Sprite2D
	moving_circle = $MovingCircle
	animation_player = moving_circle.get_node("AnimationPlayer2")
	replay_button = $ReplayButton
	effects_container = $EffectsContainer
	metronome = $Metronome
	hit_sound_player = $HitSoundPlayer
	note_pattern_label = $NotePatternLabel


	replay_button.visible = false
	replay_button.modulate = Color("#30160d")
	replay_button.pressed.connect(_on_replay_button_pressed)

	moving_circle.visible = false

	input_cooldown_timer = Timer.new()
	input_cooldown_timer.wait_time = 0.05
	input_cooldown_timer.one_shot = true
	input_cooldown_timer.timeout.connect(func(): input_event_handled = false)
	add_child(input_cooldown_timer)

	_show_slide_0()

func _input(event):
	if not input_enabled or input_event_handled:
		return

	if event.is_pressed() and (event is InputEventMouseButton or event is InputEventScreenTouch):
		var pos = get_global_mouse_position()

		if replay_button.visible and replay_button.get_global_rect().has_point(pos):
			_restart_demo()
			return

		if slide_index == 0 and showing_bottom:
			input_event_handled = true
			input_cooldown_timer.start()
			_show_next_bottom()
			return

		if slide_index == 1 and not try_slide_started:
			try_slide_started = true
			_start_slide_3()

func _process(_delta):
	if slide_index == 1 and animation_player.is_playing():
		_check_auto_hits()

func _check_auto_hits():
	for note in notes:
		for beam in note.get_node("BeamContainer").get_children():
			if not beam.has_meta("hit") and abs(beam.global_position.x - moving_circle.global_position.x) < HIT_RADIUS:
				beam.set_meta("hit", true)
				_spawn_hit_effect(beam.global_position)

func _spawn_hit_effect(hit_pos: Vector2):
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		effects_container.add_child(effect)
		effect.global_position = hit_pos
		effect.scale = Vector2(0.5, 0.5)
		effect.z_index = 10
		
		if hit_sound_player:
			hit_sound_player.play()
		
		await get_tree().create_timer(0.2).timeout
		effect.queue_free()


func _spawn_miss_effect(pos: Vector2):
	if miss_effect_scene:
		var effect = miss_effect_scene.instantiate()
		effects_container.add_child(effect)
		effect.position = effects_container.to_local(pos)
		effect.scale = Vector2(0.5, 0.5)
		effect.z_index = 10
		await get_tree().create_timer(0.5).timeout
		effect.queue_free()
		
func update_note_pattern_label(bar_data):
	var pattern := ""
	for i in bar_data.notes.size():
		var pad = bar_data.notes[i].required_pad
		var note_char = ""
		match pad:
			"left":
				note_char = "L"
			"right":
				note_char = "R"
			_:
				note_char = "B"
		pattern += note_char
		if i < bar_data.notes.size() - 1:
			pattern += "-"
	if note_pattern_label:
		note_pattern_label.text = pattern



func _show_slide_0():
	slide_index = 0
	slide_control.get_node("Slide3Label").visible = false
	slide_control.get_node("TitleLabel").text = learning_module.title_text
	slide_control.get_node("TopLabel").text = learning_module.top_texts[0]
	bottom_index = 0
	showing_bottom = true
	_show_next_bottom()

	if learning_module.demo_bars.size() > 0:
		var first_bar = learning_module.demo_bars[0]
		if first_bar is HitlineData:
			_set_hitline_texture(first_bar)
			_spawn_bar(first_bar)

func _show_next_bottom():
	var bottom_label = slide_control.get_node("BottomLabel")
	if bottom_index < learning_module.bottom_texts.size():
		bottom_label.text = learning_module.bottom_texts[bottom_index]
		bottom_index += 1
	else:
		bottom_label.text = ""
		showing_bottom = false
		if learning_module.top_texts.size() > 1:
			slide_control.get_node("TopLabel").text = learning_module.top_texts[1]
		await get_tree().create_timer(0.3).timeout
		_start_demo_slide()

func _start_demo_slide():
	slide_index = 1
	input_enabled = false
	try_slide_started = false
	replay_button.visible = false

	moving_circle.position = Vector2(96, NOTE_Y_POSITION)
	animation_player.stop()
	animation_player.seek(0.0, true)
	await get_tree().process_frame

	_clear_notes()
	moving_circle.visible = true

	if animation_player.has_animation("moving_circle"):
		await _play_demo_sequence()

	animation_player.stop()
	moving_circle.visible = false

	# 🔇 Stop the metronome after the last bar
	if metronome:
		var tick_player = metronome.get_node("LearningTickPlayer")
		var sprite = metronome.get_node("AnimatedSprite2D")
		if tick_player:
			tick_player.stop()
		if sprite:
			sprite.stop()
			sprite.frame = 0

	await get_tree().create_timer(0.2).timeout
	replay_button.visible = true
	input_enabled = true

func _on_replay_button_pressed():
	_restart_demo()

func _restart_demo():
	animation_player.stop()
	moving_circle.visible = false
	replay_button.visible = false
	try_slide_started = false
	input_enabled = false
	slide_index = 0  # 👈 Important! Reset the slide index
	_clear_notes()
	await get_tree().create_timer(0.2).timeout
	_start_demo_slide()


func _play_demo_sequence():
	var anim_name = "moving_circle"
	var anim_length = 4.0

	if metronome:
		_start_metronome_loop()

	for i in learning_module.demo_bars.size():
		var bar = learning_module.demo_bars[i]
		_set_hitline_texture(bar)
		_spawn_bar(bar)

		# ✅ Show pattern label if enabled
		if learning_module.show_note_labels:
			update_note_pattern_label(bar)
			if note_pattern_label:
				note_pattern_label.visible = true
		else:
			if note_pattern_label:
				note_pattern_label.visible = false

		animation_player.stop()
		animation_player.seek(0.0, true)
		animation_player.play(anim_name)

		await get_tree().process_frame
		await get_tree().create_timer(anim_length).timeout

		var is_end_bar = bar.resource_path.to_lower().find("endbar") >= 0
		var is_last = i == learning_module.demo_bars.size() - 1

		if not (is_last and is_end_bar):
			_clear_notes()

	# Stop metronome AFTER endbar
	_stop_metronome_loop()

	# ✅ Hide pattern label when done
	if note_pattern_label:
		note_pattern_label.visible = false

	animation_player.stop()
	replay_button.visible = true
	input_enabled = true



func _start_slide_3():
	slide_index = 2
	input_enabled = false
	replay_button.visible = false
	moving_circle.visible = false
	_clear_notes()

	slide_control.get_node("TopLabel").text = ""
	slide_control.get_node("BottomLabel").text = ""
	slide_control.get_node("TitleLabel").visible = false  #  Hide TitleLabel 

	var slide3_label = slide_control.get_node("Slide3Label")
	if slide3_label:
		slide3_label.visible = true
		slide3_label.text = learning_module.slide3_message

	# Hide metronome visuals
	if metronome:
		var tick_player = metronome.get_node("LearningTickPlayer")
		var sprite = metronome.get_node("AnimatedSprite2D")
		if tick_player:
			tick_player.stop()
		if sprite:
			sprite.stop()
			sprite.visible = false

	# Hide the BPM label and hitline
	var bpm_label = $BPMLabel
	if bpm_label:
		bpm_label.visible = false

	if hitline_sprite:
		hitline_sprite.visible = false



func _spawn_bar(bar_data):
	for note_data in bar_data.notes:
		if note_data != null and note_data.note_scene != null:
			var note = note_data.note_scene.instantiate()
			note.position = Vector2(note_data.x_position, NOTE_Y_POSITION)
			note.set_meta("required_pad", note_data.required_pad)
			notes_container.add_child(note)
			notes.append(note)

func _clear_notes():
	for note in notes:
		note.queue_free()
	notes.clear()
	


func _set_hitline_texture(bar_data):
	var is_end = bar_data.resource_path.to_lower().find("endbar") >= 0
	if is_end:
		hitline_sprite.texture = preload("res://Assets/End.png")
	else:
		hitline_sprite.texture = preload("res://Assets/Continue.png")

func _play_metronome_tick():
	if metronome:
		var tick_player = metronome.get_node("LearningTickPlayer")
		var sprite = metronome.get_node("AnimatedSprite2D")
		var delay_timer = metronome.get_node("Timer")

		if tick_player:
			tick_player.play()
			if sprite:
				sprite.stop()
				sprite.frame = 0
			if delay_timer:
				delay_timer.wait_time = 0.25
				delay_timer.one_shot = true
				delay_timer.start()
				delay_timer.timeout.connect(func():
					if sprite:
						sprite.play()
				)
			tick_player.finished.connect(func():
				if sprite:
					sprite.stop()
					sprite.frame = 0
			)
			
func _start_metronome_loop():
	if metronome:
		var tick_player = metronome.get_node("LearningTickPlayer")
		var sprite = metronome.get_node("AnimatedSprite2D")
		var timer = metronome.get_node("Timer")

		if tick_player and sprite and timer:
			timer.wait_time = 4.0  # length of your demo bar
			timer.one_shot = false
			timer.timeout.connect(_on_metronome_tick_timeout)
			timer.start()

			_on_metronome_tick_timeout()  # Play immediately

func _stop_metronome_loop():
	if metronome:
		var tick_player = metronome.get_node("LearningTickPlayer")
		var sprite = metronome.get_node("AnimatedSprite2D")
		var timer = metronome.get_node("Timer")

		if tick_player:
			tick_player.stop()
		if sprite:
			sprite.stop()
			sprite.frame = 0
		if timer:
			timer.stop()
			timer.timeout.disconnect(_on_metronome_tick_timeout)

func _on_metronome_tick_timeout():
	var tick_player = metronome.get_node("LearningTickPlayer")
	var sprite = metronome.get_node("AnimatedSprite2D")
	if tick_player:
		tick_player.stop()
		tick_player.play()
	if sprite:
		sprite.stop()
		sprite.frame = 0
		sprite.play()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Sample/sample_scene.tscn")
