extends Node2D

var note_type : String
var hit_detected : bool = false

# Function to handle note hit
func hit():
	if !hit_detected:
		hit_detected = true
		# Play sound or feedback for hitting the note
		queue_free()  # Remove the note from the scene
