extends Node2D

var label
var label1
var label2
var label3
var label4
var label5
var label6
var arrow
var arrow2
var arrow3
var continue_bar
var end_bar
var metronome
var next_button

var current_slide = 1

func _ready():
	# Initializing nodes
	label = $Label
	label1 = $Label1
	label2 = $Label2
	label3 = $Label3
	label4 = $Label4
	label5 = $Label5
	label6 = $Label6
	arrow = $Arrow
	arrow2 = $Arrow2
	arrow3 = $Arrow3
	continue_bar = $ContinueBar
	end_bar = $EndBar
	metronome = $Metronome
	next_button = $Button  # You said your node is named 'Button'
	
	# Hide everything except Label for Slide 1
	label1.hide()
	label2.hide()
	label3.hide()
	label4.hide()
	label5.hide()
	label6.hide()
	arrow.hide()
	arrow2.hide()
	arrow3.hide()
	continue_bar.hide()
	end_bar.hide()
	metronome.hide()
	label.show()

	# Connect using Callable (Godot 4+)
	next_button.pressed.connect(_on_next_button_pressed)

# This method handles the button press
func _on_next_button_pressed():
	match current_slide:
		1:
			label.hide()
			label1.show()
			continue_bar.show()  # Continue bar should remain visible
			current_slide = 2
		2:
			arrow.show()
			label2.show()
			current_slide = 3
		3:
			label1.hide()
			label2.hide()
			arrow.hide()
			continue_bar.hide()
			label3.show()
			label4.show()
			metronome.show()
			current_slide = 4
		4:
			label3.hide()
			label4.hide()
			metronome.hide()
			label5.show()
			arrow2.show()
			end_bar.show()
			current_slide = 5
		5:
			label6.show()
			arrow3.show()
			current_slide = 6
