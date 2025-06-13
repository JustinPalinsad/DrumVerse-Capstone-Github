extends Node2D

signal beat_tick

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var tick_sound: AudioStreamPlayer2D = $TickSound

var bpm: float = 60.0
var timer: Timer
var game_start_time_msec: int = 0
var loop_counter: int = 0
var max_loops: int = 4
var mode: String = "practice"

func _ready() -> void:
	print("Metronome ready")
	timer = Timer.new()
	timer.one_shot = false
	timer.autostart = false
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func start(bpm_value: float, mode_value: String = "practice") -> void:
	bpm = bpm_value
	mode = mode_value
	loop_counter = 0

	timer.wait_time = 60.0 / bpm
	timer.start()

	game_start_time_msec = Time.get_ticks_msec()

	play_tick()
	print("Metronome started with BPM:", bpm)

func _on_timer_timeout() -> void:
	play_tick()

	loop_counter += 1

	if mode == "practice":
		if loop_counter >= max_loops:
			print("Restarting bar in Practice Mode")
			loop_counter = 0  # Reset for the next loop


func play_tick() -> void:
	if tick_sound and tick_sound.stream:
		tick_sound.play()
	else:
		print("No tick sound assigned!")

	if sprite:
		sprite.play("metronome")

	emit_signal("beat_tick")

	# Log time
	var current_time_msec = Time.get_ticks_msec()
	var elapsed_seconds = (current_time_msec - game_start_time_msec) / 1000.0

	var moving_circle = get_parent().get_node_or_null("MovingCircle")
	if moving_circle:
		print("Tick at", str(elapsed_seconds) + "s | MovingCircle X:", moving_circle.position.x)
	else:
		print("Tick at", str(elapsed_seconds) + "s | MovingCircle missing")

	if mode == "practice" and loop_counter >= max_loops:
		print("Restarting bar in Practice Mode")
		loop_counter = 0
		
func stop() -> void:
	if timer:
		timer.stop()
		print("Metronome timer stopped")

	if tick_sound and tick_sound.playing:
		tick_sound.stop()
		print("Tick sound stopped")

	if sprite and sprite.is_playing():
		sprite.stop()
		print("Metronome animation stopped")
