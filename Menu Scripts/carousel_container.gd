@tool
extends Node2D

@export var spacing: float = 20.0
@export var wraparound_enabled: bool = false
@export var wraparound_radius: float = 300.0
@export var wraparound_height: float = 50.0

@export_range(0.0, 1.0) var opacity_strength: float = 0.35
@export_range(0.0, 1.0) var scale_strength: float = 0.25
@export_range(0.01, 0.99, 0.01) var scale_min: float = 0.1

@export var smoothing_speed: float = 6.5
@export var follow_button_focus: bool = true
@export var position_offset_node: Control
@export var up_button: Button # New export for your up button
@export var down_button: Button # New export for your down button

var dragging := false
var last_mouse_pos := Vector2.ZERO
var velocity := 0.0
var released := false

var _selected_index := 0
var queued_print_index := -1

@export var selected_index: int:
	get: return _selected_index
	set(value): set_selected_index(value)

func set_selected_index(value: int):
	if position_offset_node:
		_selected_index = clamp(value, 0, position_offset_node.get_child_count() - 1)
	else:
		_selected_index = value

func _ready():
	if position_offset_node:
		for child in position_offset_node.get_children():
			if child.has_signal("pressed") and not child.is_connected("pressed", Callable(self, "_on_button_pressed")):
				child.connect("pressed", Callable(self, "_on_button_pressed").bind(child))
	
	# Connect the up and down buttons to their functions
	if up_button:
		up_button.connect("pressed", Callable(self, "_up"))
	if down_button:
		down_button.connect("pressed", Callable(self, "_down"))

func _on_button_pressed(button: Control):
	# Only execute the action if the button pressed is the highlighted one
	if button.get_index() == selected_index:
		# 🔄 Update selection if the correct button is pressed
		selected_index = button.get_index()
		queued_print_index = button.get_index()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				released = false
				last_mouse_pos = event.position
				velocity = 0.0

				if position_offset_node:
					for child in position_offset_node.get_children():
						if child.has_focus():
							child.release_focus()
			else:
				dragging = false
				released = true

	elif event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_pos
		position_offset_node.position.y += delta.y
		velocity = delta.y
		last_mouse_pos = event.position

func _process(delta: float) -> void:
	if !position_offset_node or position_offset_node.get_child_count() == 0:
		return

	selected_index = clamp(selected_index, 0, position_offset_node.get_child_count() - 1)

	# Layout children vertically
	var y := 0.0
	for i in position_offset_node.get_children():
		i.pivot_offset = i.size / 2.0
		i.position = Vector2(-i.size.x / 2.0, y)
		y += i.size.y + spacing

	# ✅ Follow focused button (keyboard/tab)
	if follow_button_focus:
		for i in position_offset_node.get_children():
			if i.has_focus():
				selected_index = i.get_index()
				break

	# 📍 Smooth scroll to selected
	if !dragging:
		var target_item = position_offset_node.get_child(selected_index)
		var target_y = -(target_item.position.y + target_item.size.y / 2.0 - get_viewport_rect().size.y / 2.0)
		position_offset_node.position.y = lerp(position_offset_node.position.y, target_y, smoothing_speed * delta)

	# 🔄 Snap to closest after swipe
	if released:
		released = false
		var center_y = get_viewport_rect().size.y / 2.0
		var closest_index := 0
		var smallest_dist := INF

		for i in position_offset_node.get_children():
			var item_center_y = position_offset_node.position.y + i.position.y + i.size.y / 2.0
			var dist = abs(center_y - item_center_y)

			if dist < smallest_dist:
				smallest_dist = dist
				closest_index = i.get_index()

		selected_index = closest_index

	# 🧠 Live scaling, opacity, and interactivity control
	var center_y := get_viewport_rect().size.y / 2.0
	for i in position_offset_node.get_children():
		var item_center_y = position_offset_node.position.y + i.position.y + i.size.y / 2.0
		var pixel_dist = abs(center_y - item_center_y)

		var normalized = clamp(pixel_dist / (get_viewport_rect().size.y / 2.0), 0.0, 1.0)

		i.scale = Vector2.ONE * clamp(1.0 - scale_strength * normalized, scale_min, 1.0)
		i.modulate.a = clamp(1.0 - opacity_strength * normalized, 0.0, 1.0)

		# 🎯 Centered child is interactable; others are ignored
		if i.get_index() == selected_index:
			i.z_index = 1
			i.mouse_filter = Control.MOUSE_FILTER_STOP
			i.focus_mode = Control.FOCUS_ALL
		else:
			i.z_index = -abs(i.get_index() - selected_index)
			i.mouse_filter = Control.MOUSE_FILTER_IGNORE
			i.focus_mode = Control.FOCUS_NONE
			
func _up():
	selected_index -= 1
	if selected_index < 0:
		selected_index += 1
func _down():
	selected_index += 1
	if selected_index > position_offset_node.get_child_count()-1:
		selected_index -= 1
