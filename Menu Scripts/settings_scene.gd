extends Control  

@onready var sprite := $"DarkMode Button"
@onready var button := $"DarkMode Button"

const COLOR_YELLOW := Color("ffc025")
const COLOR_BROWN := Color("30170c")
const LIGHT_TEXTURE := preload("res://Menu Assets/LightMode.png")
const DARK_TEXTURE := preload("res://Menu Assets/DarkMode.png")

func _ready() -> void:
	# Apply dark mode state when the scene loads
	var mat := sprite.material as ShaderMaterial
	if mat:
		if GameState.dark_mode_enabled:
			mat.set_shader_parameter("layer_color", COLOR_BROWN)
			mat.set_shader_parameter("sub_color", COLOR_YELLOW)
			button.texture_normal = LIGHT_TEXTURE  # Show light icon when in dark mode
		else:
			mat.set_shader_parameter("layer_color", COLOR_YELLOW)
			mat.set_shader_parameter("sub_color", COLOR_BROWN)
			button.texture_normal = DARK_TEXTURE  # Show dark icon when in light mode

	# Optional: disable texture_pressed to prevent flicker
	button.texture_pressed = null

func _on_dark_mode_button_pressed() -> void:
	$Sound.play()
	await get_tree().create_timer(0.2).timeout

	GameState.dark_mode_enabled = !GameState.dark_mode_enabled

	var mat := sprite.material as ShaderMaterial
	if mat:
		if GameState.dark_mode_enabled:
			mat.set_shader_parameter("layer_color", COLOR_BROWN)
			mat.set_shader_parameter("sub_color", COLOR_YELLOW)
			button.texture_normal = LIGHT_TEXTURE
		else:
			mat.set_shader_parameter("layer_color", COLOR_YELLOW)
			mat.set_shader_parameter("sub_color", COLOR_BROWN)
			button.texture_normal = DARK_TEXTURE

	# Optional: reset pressed texture to avoid it showing
	button.texture_pressed = null

func _on_back_pressed() -> void:
	$Sound.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Menu Scenes/main_menu.tscn")


func _on_sound_toggle_pressed() -> void:
	$Sound.play()
	pass # Replace with function body.
