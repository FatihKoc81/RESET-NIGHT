extends SceneTree

func _initialize() -> void:
    var b64_path := "res://assets/reset_night_title.webp.b64"
    var encoded := FileAccess.get_file_as_string(b64_path).strip_edges()
    if encoded.is_empty():
        push_error("RESET NIGHT title artwork is missing.")
        quit(1)
        return
    var source := Image.new()
    var load_error := source.load_webp_from_buffer(Marshalls.base64_to_raw(encoded))
    if load_error != OK:
        push_error("Could not decode RESET NIGHT title artwork: %s" % load_error)
        quit(1)
        return
    source.resize(512, 286, Image.INTERPOLATE_LANCZOS)
    var icon := Image.create(512, 512, false, Image.FORMAT_RGBA8)
    icon.fill(Color("#05070a"))
    icon.blit_rect(source, Rect2i(0, 0, source.get_width(), source.get_height()), Vector2i(0, 113))
    var output_path := ProjectSettings.globalize_path("res://assets/reset_night_icon.png")
    var save_error := icon.save_png(output_path)
    if save_error != OK:
        push_error("Could not create RESET NIGHT launcher icon: %s" % save_error)
        quit(1)
        return
    print("RESET NIGHT launcher icon generated: ", output_path)
    quit(0)
