extends CanvasLayer

var slides: Array = []
var bottom_slides: Array = []

func _ready():
	# Assumes child nodes are slides
	for child in get_children():
		if "bottom" in child.name.lower():
			bottom_slides.append(child)
		else:
			slides.append(child)
	hide_all()

func hide_all():
	for slide in slides:
		slide.visible = false
	for bottom in bottom_slides:
		bottom.visible = false

func show_slide(index: int, show: bool = true):
	hide_all()
	if index >= 0 and index < slides.size():
		slides[index].visible = show

func show_slide_bottom(index: int, show: bool = true):
	if index >= 0 and index < bottom_slides.size():
		bottom_slides[index].visible = show

func get_slide_count(type_index: int) -> int:
	return bottom_slides.size() if type_index == 0 else slides.size()
