extends Node2D

@onready var sprite: Sprite2D = get_node("Sprite2D")

func _ready():
	var beams = get_node("BeamContainer").get_children()
	for beam in beams:
		if beam.has_method("is_beam") and beam.is_beam():
			beam.parent_note = self
	print("Ready! Total beams in this note:", beams.size())
