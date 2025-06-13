extends Node

@export var HitEffectScene: PackedScene  # You can remove this if not needed anymore
@export var MissEffectScene: PackedScene
@export var white_note_texture: Texture  # Assign your white note PNG here

@onready var TapSound = $TapSound
@onready var MetronomeSound = $MetronomeSound
@onready var moving_circle = get_node("MovingCircle")
@onready var notes_container = get_node("NotesContainer")

@export var hit_threshold = 40
@export var bpm = 120.0  # Beats per minute

func _ready():
	if not is_instance_valid(moving_circle):
		printerr("Error: MovingCircle node not found.")
		return
	if not is_instance_valid(notes_container):
		printerr("Error: NotesContainer node not found.")
		return
	if not is_instance_valid(TapSound):
		printerr("Error: TapSound node not found.")
		return
	if not is_instance_valid(MetronomeSound):
		printerr("Error: MetronomeSound node not found.")
		return

	print("Ready: MovingCircle =", moving_circle.name, ", NotesContainer =", notes_container.name)
	start_metronome()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		check_hit_or_miss()
		if TapSound:
			print("Playing TapSound...")
			TapSound.play()

func check_hit_or_miss():
	if is_instance_valid(moving_circle) and is_instance_valid(notes_container):
		var closest_note = null
		var closest_distance = hit_threshold + 1

		if abs(moving_circle.global_position.x - moving_circle.start_x) > 5:
			for note in notes_container.get_children():
				if is_instance_valid(note):
					var distance = abs(note.global_position.x - moving_circle.global_position.x)
					if distance < closest_distance:
						closest_distance = distance
						closest_note = note

			if is_instance_valid(closest_note) and closest_distance <= hit_threshold:
				change_note_to_white(closest_note)
				print("HIT on:", closest_note.name, "at distance:", closest_distance)
			else:
				show_miss_effect(moving_circle.global_position)
				print("MISS at MovingCircle X:", moving_circle.global_position.x)
		else:
			show_miss_effect(moving_circle.global_position)
			print("MISS at start - MovingCircle hasn't moved enough.")
	else:
		printerr("Error: Nodes not valid in check_hit_or_miss().")

func change_note_to_white(note: Node):
	if note.has_node("Sprite2D"):
		var sprite = note.get_node("Sprite2D")
		if sprite is Sprite2D and white_note_texture:
			sprite.texture = white_note_texture
			sprite.z_index = 10  # Makes sure it appears on top of 4/4 line
			print("✅ Note changed to white:", note.name)
		else:
			printerr("❌ Sprite2D missing or white texture not assigned")
	else:
		printerr("❌ No Sprite2D found in note:", note.name)

func show_miss_effect(pos: Vector2):
	if MissEffectScene:
		var miss = MissEffectScene.instantiate()
		miss.position = pos
		add_child(miss)
		print("Miss effect shown at:", pos)
	else:
		printerr("MissEffectScene not assigned!")

func start_metronome():
	var beat_interval = 60.0 / bpm
	print("Metronome interval:", beat_interval)
	metronome_tick(beat_interval)

func metronome_tick(interval):
	await get_tree().create_timer(interval).timeout
	if MetronomeSound:
		print("Playing MetronomeSound...")
		MetronomeSound.play()
	metronome_tick(interval)
