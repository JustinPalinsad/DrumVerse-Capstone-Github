extends Resource
class_name DrumNote

@export_enum("left", "right", "both") var required_pad: String = "both"
@export var x_position: float
@export var note_scene: PackedScene
