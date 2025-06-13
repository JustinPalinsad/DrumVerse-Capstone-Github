extends Node2D

var beam1_hit := false
var beam2_hit := false

@onready var sprite: Sprite2D = $Sprite2D

# Colors
const BASE_COLOR = Color.WHITE
const PARTIAL_COLOR = Color("#7A6358") # A midpoint between white and final
const FINAL_COLOR = Color("#30160D")   # Final brown after both beams hit

func _ready():
	if not sprite:
		push_error("❌ Sprite2D not found!")
		return
	sprite.modulate = BASE_COLOR

func _on_beam1_hit(_body):
	if not beam1_hit:
		beam1_hit = true
		_update_color()

func _on_beam2_hit(_body):
	if not beam2_hit:
		beam2_hit = true
		_update_color()

func _update_color():
	if beam1_hit and beam2_hit:
		sprite.modulate = FINAL_COLOR
	elif beam1_hit or beam2_hit:
		sprite.modulate = PARTIAL_COLOR

# Called by GameScene
func on_hit():
	if not beam1_hit:
		beam1_hit = true
	elif not beam2_hit:
		beam2_hit = true
	_update_color()
