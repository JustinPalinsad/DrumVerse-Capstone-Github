extends Node2D

@onready var circle_sprite: Sprite2D = $CircleSprite

var was_hit: bool = false

func hit():
	if not was_hit:
		was_hit = true
		circle_sprite.modulate = Color(1, 1, 1)  # Turn Circle white
