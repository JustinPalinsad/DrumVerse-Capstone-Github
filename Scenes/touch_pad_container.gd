extends Node2D

@onready var lefttouchpad = $LeftTouchPad
@onready var righttouchpad = $RightTouchPad

var original_scale := Vector2(0.441, 0.441)
var pressed_scale := Vector2(0.398, 0.398)

func _ready() -> void:
	# Save original scale (assumes both have the same scale at start)
	original_scale = lefttouchpad.scale

func _on_left_touch_pad_pressed() -> void:
	$Snare.play()
	lefttouchpad.scale = pressed_scale

func _on_left_touch_pad_released() -> void:
	lefttouchpad.scale = original_scale

func _on_right_touch_pad_pressed() -> void:
	$Snare.play()
	righttouchpad.scale = pressed_scale

func _on_right_touch_pad_released() -> void:
	righttouchpad.scale = original_scale
