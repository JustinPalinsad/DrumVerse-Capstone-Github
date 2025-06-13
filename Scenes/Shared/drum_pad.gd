extends Area2D

@export var is_left_pad: bool = true
@onready var hit_sound = $HitSound
@onready var shape = $CollisionShape2D
var original_scale: Vector2

func _ready():
	original_scale = scale
	
	if is_left_pad:
		shape.position.x = 80
	else:
		shape.position.x = -80

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		scale = original_scale * 0.9
		hit_sound.play()
		get_tree().create_timer(0.1).timeout.connect(func(): scale = original_scale)
