shader_type canvas_item;

uniform float time : hint_range(0.0, 1.0); // Time-based parameter to control the effect

void fragment() {
    // Get the current pixel's color
    vec4 color = texture(TEXTURE, UV);

    // If the color of the note is black, transition to white over time
    if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0) {
        // Gradually mix the note color with white over time
        color.rgb = mix(color.rgb, vec3(1.0, 1.0, 1.0), time);
    }

    // Set the final color
    COLOR = color;
}
