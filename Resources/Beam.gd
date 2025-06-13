extends Area2D

@export var parent_note: Node2D
@onready var hit_effect_scene: PackedScene = preload("res://Scenes/Shared/HitEffect.tscn")

func is_beam() -> bool:
	return true

func register_hit():
	if parent_note and parent_note.has_method("register_beam_hit"):
		parent_note.register_beam_hit()

	var game_scene = get_tree().get_current_scene()
	if game_scene:
		var effects_container = game_scene.get_node_or_null("EffectsContainer")
		if effects_container:
			var hit_effect = hit_effect_scene.instantiate()
			effects_container.add_child(hit_effect)
			hit_effect.position = effects_container.to_local(global_position)
			hit_effect.scale = Vector2(0.5, 0.5)
			hit_effect.z_index = 10
			await get_tree().create_timer(0.2).timeout
			hit_effect.queue_free()
