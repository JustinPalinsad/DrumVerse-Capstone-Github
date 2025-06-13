extends Resource
class_name DrumModuleData

@export var continue_bars: Array[HitlineData] = []
@export var show_note_labels: bool = false # Optional
@export var end_bar: HitlineData
@export var bpm: int = 60
@export var moving_circle_duration: float = 4.0
