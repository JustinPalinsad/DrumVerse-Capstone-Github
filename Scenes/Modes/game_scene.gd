extends Node2D

@export var hit_radius: float = 45.0
@export var mode: String = "practice"

@onready var moving_circle = get_node("MovingCircle")
@onready var animation_player = moving_circle.get_node("AnimationPlayer2")
@onready var effects_container = get_node("EffectsContainer")
@onready var metronome = get_node("Metronome")
@onready var hitline_sprite = get_node("HitLine/Sprite2D")
@onready var miss_effect_scene = preload("res://Scenes/Shared/MissEffect.tscn")
@onready var hit_effect_scene = preload("res://Scenes/Shared/HitEffect.tscn")
@onready var left_pad = get_node("LeftPad")
@onready var right_pad = get_node("RightPad")
@onready var note_pattern_label = get_node("NotePatternLabel")
@onready var bpm_label = get_node("BPMLabel")
@onready var countdown_label = get_node("CountdownLabel")
@onready var countdown_audio_player = get_node("CountdownAudioPlayer")
@onready var pass_sound = get_node("PassSound")
@onready var fail_sound = get_node("FailSound")

@onready var con_texture = preload("res://Assets/Continue.png")
@onready var end_texture = preload("res://Assets/End.png")

var notes: Array[Node2D] = []
var tick_counter: int = 0
var drum_module: DrumModuleData
var current_bar_index: int = 0
var beats_to_cover: int = 4
var moving_circle_duration: float
var challenge_mode_has_ended := false

# 🎯 Challenge Mode Scoring
var total_notes := 0
var total_hits := 0
var total_misses := 0

func _ready() -> void:
	drum_module = GameState.selected_module
	if not drum_module:
		push_error("No module selected!")
		return

	moving_circle.visible = (mode == "practice")
	moving_circle_duration = (60.0 / drum_module.bpm) * beats_to_cover
	bpm_label.text = "BPM: %d" % drum_module.bpm
	hitline_sprite.modulate = Color("#30160D")

	countdown_label.visible = true
	note_pattern_label.visible = false

	await play_countdown()

	spawn_current_bar()
	metronome.start(drum_module.bpm, mode)

	if metronome.has_signal("beat_tick"):
		metronome.connect("beat_tick", Callable(self, "_on_tick"))

	left_pad.connect("input_event", Callable(self, "_on_left_pad_input"))
	right_pad.connect("input_event", Callable(self, "_on_right_pad_input"))

func play_countdown() -> void:
	countdown_label.visible = true
	var countdown_values = ["3", "2", "1", "GO"]
	for value in countdown_values:
		countdown_label.text = value
		countdown_audio_player.play()
		await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false

func spawn_current_bar():
	clear_notes()

	var total_continue_bars = drum_module.continue_bars.size()
	var bar_data

	if current_bar_index < total_continue_bars:
		bar_data = drum_module.continue_bars[current_bar_index]
		hitline_sprite.texture = con_texture
		hitline_sprite.position.x = 0
	elif current_bar_index == total_continue_bars:
		bar_data = drum_module.end_bar
		hitline_sprite.texture = end_texture
	else:
		print("All bars completed.")
		end_challenge_mode()
		return

	print("Loading bar index:", current_bar_index)

	spawn_notes_from_bar(bar_data)

	note_pattern_label.visible = drum_module.show_note_labels
	if drum_module.show_note_labels:
		update_note_pattern_label(bar_data)

	if animation_player and animation_player.has_animation("moving_circle"):
		var anim = animation_player.get_animation("moving_circle")
		var original_length = anim.length
		animation_player.speed_scale = moving_circle_duration / original_length
		animation_player.stop()
		animation_player.play("moving_circle")

func spawn_notes_from_bar(bar_data):
	for note_data in bar_data.notes:
		if note_data and note_data.note_scene:
			var note = note_data.note_scene.instantiate()
			note.position = Vector2(note_data.x_position, 415)
			note.set_meta("required_pad", note_data.required_pad)
			add_child(note)
			notes.append(note)
			total_notes += 1

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
	note_pattern_label.text = pattern

func clear_notes():
	for note in notes:
		note.queue_free()
	notes.clear()

func _on_tick() -> void:
	if challenge_mode_has_ended:
		return

	tick_counter += 1

	if tick_counter >= 4:
		tick_counter = 0
		current_bar_index += 1

		if animation_player and animation_player.has_animation("moving_circle"):
			animation_player.stop()
			animation_player.play("moving_circle")

		if mode == "practice":
			var total = drum_module.continue_bars.size()
			if current_bar_index > total:
				current_bar_index = 0
			spawn_current_bar()
		else:
			spawn_current_bar()

func end_challenge_mode():
	challenge_mode_has_ended = true
	await get_tree().process_frame
	metronome.stop()

	if metronome.has_node("TickSound"):
		var tick_sound = metronome.get_node("TickSound")
		if tick_sound is AudioStreamPlayer:
			tick_sound.stop()

	animation_player.stop()
	moving_circle.visible = false
	clear_notes()

	await get_tree().create_timer(2.0).timeout

	var hit_percentage: float = 0.0
	var total_attempts := total_hits + total_misses
	if total_attempts > 0:
		hit_percentage = float(total_hits) / float(total_attempts) * 100.0

	var grade: String
	if hit_percentage >= 95:
		grade = "S"
	elif hit_percentage >= 85:
		grade = "A"
	elif hit_percentage >= 70:
		grade = "B"
	elif hit_percentage >= 50:
		grade = "C"
	else:
		grade = "Fail"

	var player_passed = grade != "Fail"

	print("Challenge Results:")
	print("Hits: %d / %d" % [total_hits, total_notes])
	print("Misses: %d" % total_misses)
	print("Hit %%: %.1f%%" % hit_percentage)
	print("Grade: %s" % grade)

	if has_node("PassSound") and has_node("FailSound"):
		if player_passed:
			get_node("PassSound").play()
		else:
			get_node("FailSound").play()

	_show_results(hit_percentage, grade)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var pos = event.position

		var left_collider = left_pad.get_node("CollisionShape2D")
		var right_collider = right_pad.get_node("CollisionShape2D")

		if left_collider and point_inside_shape(left_collider, pos):
			animate_pad(left_pad)
			check_hit("left")
		elif right_collider and point_inside_shape(right_collider, pos):
			animate_pad(right_pad)
			check_hit("right")

	elif event.is_action_pressed("left_pad"):
		animate_pad(left_pad)
		check_hit("left")
	elif event.is_action_pressed("right_pad"):
		animate_pad(right_pad)
		check_hit("right")

func _on_left_pad_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		animate_pad(left_pad)
		check_hit("left")

func _on_right_pad_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		animate_pad(right_pad)
		check_hit("right")

func animate_pad(pad: Node2D) -> void:
	var original_scale = pad.scale
	pad.scale = original_scale * 0.9
	if pad.has_node("HitSound"):
		var hit_sound = pad.get_node("HitSound")
		if hit_sound is AudioStreamPlayer2D:
			hit_sound.play()
	await get_tree().create_timer(0.1).timeout
	pad.scale = original_scale

func check_hit(pad_side: String) -> void:
	for note in notes:
		var required_pad = note.get_meta("required_pad")
		if required_pad != "both" and required_pad != pad_side:
			continue
		var beams = note.get_node("BeamContainer").get_children()
		for beam in beams:
			if beam is Area2D and not beam.has_meta("hit"):
				var beam_x = beam.global_position.x
				var circle_x = moving_circle.global_position.x
				if abs(beam_x - circle_x) < hit_radius:
					beam.set_meta("hit", true)
					if beam.has_method("register_hit"):
						beam.register_hit()
					play_hit_effect(beam.global_position)
					total_hits += 1
					return
	play_miss_effect()

func play_miss_effect() -> void:
	total_misses += 1
	var miss = miss_effect_scene.instantiate()
	effects_container.add_child(miss)
	miss.position = effects_container.to_local(moving_circle.global_position)
	miss.scale = Vector2(0.5, 0.5)
	miss.z_index = 10
	await get_tree().create_timer(0.5).timeout
	miss.queue_free()

func play_hit_effect(effect_position: Vector2) -> void:
	var hit = hit_effect_scene.instantiate()
	effects_container.add_child(hit)
	hit.position = effects_container.to_local(effect_position)
	hit.scale = Vector2(0.5, 0.5)
	hit.z_index = 10
	await get_tree().create_timer(0.2).timeout
	hit.queue_free()

func point_inside_shape(collider: CollisionShape2D, global_point: Vector2) -> bool:
	var shape = collider.shape
	if shape == null:
		return false

	var local_point = collider.to_local(global_point)

	if shape is RectangleShape2D:
		var half_extents = shape.extents
		return abs(local_point.x) <= half_extents.x and abs(local_point.y) <= half_extents.y
	elif shape is CircleShape2D:
		return local_point.length() <= shape.radius
	else:
		return false

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Sample/sample_scene.tscn")

func _show_results(passed_hit_percentage: float, passed_grade: String):
	var results_scene = preload("res://Sample/result_scene.tscn").instantiate()
	results_scene.total_hits = total_hits
	results_scene.total_notes = total_notes
	results_scene.total_misses = total_misses
	results_scene.hit_percentage = passed_hit_percentage
	results_scene.grade = passed_grade
	results_scene.mode = mode  # Pass the mode to the results scene

	get_tree().get_root().add_child(results_scene)
	hide()
