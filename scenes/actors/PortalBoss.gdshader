shader_type canvas_item;

// Spiral controls
uniform int arms : hint_range(1,12) = 6;
uniform float tightness : hint_range(0.0, 12.0) = 6.0;
uniform float speed : hint_range(-5.0, 5.0) = 1.8;   // <— sign controls direction
uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;

// Colors
uniform vec4 color_a : source_color = vec4(0.15, 0.75, 1.0, 1.0); // inner stripe
uniform vec4 color_b : source_color = vec4(0.95, 1.0, 1.0, 1.0);  // outer stripe

// Border (ring) around the portal
uniform float border_thickness : hint_range(0.0, 0.5) = 0.06;  // 0 = none
uniform float border_softness  : hint_range(0.0, 0.2) = 0.02;  // feather
uniform vec4  border_color : source_color = vec4(0.05, 0.15, 0.25, 1.0);

// Optional overall fade (0..1)
uniform float alpha_mul : hint_range(0.0, 1.0) = 1.0;

void fragment(){
    // Centered UV
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Spiral phase
    float t = TIME * speed;
    float phase = float(arms) * a + tightness * log(max(r, 1e-3)) - t;

    // Procedural stripes
    float s = 0.5 + 0.5 * sin(phase);
    float stripes = smoothstep(0.5 - edge_softness, 0.5 + edge_softness, s);
    vec3 spiral_rgb = mix(color_a.rgb, color_b.rgb, stripes);

    // Use your GradientTexture2D alpha as soft circular mask
    float mask = texture(TEXTURE, uv * 0.5 + 0.5).a;

    // Border ring near r≈1
    float inner_edge = 1.0 - border_thickness;
    float border = smoothstep(inner_edge - border_softness, inner_edge, r)
                 * (1.0 - smoothstep(1.0 - border_softness, 1.0, r));

    // Composite: draw border over the spiral
    vec3 rgb = mix(spiral_rgb, border_color.rgb, clamp(border, 0.0, 1.0));
    float alpha = max(mask, border) * alpha_mul;

    COLOR = vec4(rgb, alpha);
}



