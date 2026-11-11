extends SceneTree

func _initialize() -> void:
    var encoded := FileAccess.get_file_as_string("res://assets/reset_night_title.webp.b64").strip_edges()
    if encoded.is_empty():
        push_error("RESET NIGHT title artwork is missing.")
        quit(1)
        return
    var source := Image.new()
    var err := source.load_webp_from_buffer(Marshalls.base64_to_raw(encoded))
    if err != OK:
        push_error("Could not decode RESET NIGHT title artwork: %s" % err)
        quit(1)
        return

    # Legacy launcher icon: square dark tile with the full original title artwork.
    var main_icon := Image.create(512, 512, false, Image.FORMAT_RGBA8)
    main_icon.fill(Color("#05070a"))
    var main_art := source.duplicate()
    main_art.resize(480, 268, Image.INTERPOLATE_LANCZOS)
    main_icon.blit_rect(main_art, Rect2i(0, 0, 480, 268), Vector2i(16, 122))
    if not _save(main_icon, "res://assets/reset_night_icon.png"):
        quit(1)
        return

    # Adaptive icon foreground: keep all important artwork within Android's central safe area.
    var foreground := Image.create(432, 432, false, Image.FORMAT_RGBA8)
    foreground.fill(Color(0, 0, 0, 0))
    var safe_art := source.duplicate()
    safe_art.resize(250, 140, Image.INTERPOLATE_LANCZOS)
    foreground.blit_rect(safe_art, Rect2i(0, 0, 250, 140), Vector2i(91, 146))
    if not _save(foreground, "res://assets/reset_night_adaptive_foreground.png"):
        quit(1)
        return

    var background := Image.create(432, 432, false, Image.FORMAT_RGBA8)
    background.fill(Color("#05070a"))
    if not _save(background, "res://assets/reset_night_adaptive_background.png"):
        quit(1)
        return

    var mono := Image.create(432, 432, false, Image.FORMAT_RGBA8)
    mono.fill(Color(0, 0, 0, 0))
    var mono_art := source.duplicate()
    mono_art.convert(Image.FORMAT_RGBA8)
    mono_art.resize(250, 140, Image.INTERPOLATE_LANCZOS)
    for y in range(mono_art.get_height()):
        for x in range(mono_art.get_width()):
            var px: Color = mono_art.get_pixel(x, y)
            var luminance: float = (px.r + px.g + px.b) / 3.0
            mono_art.set_pixel(x, y, Color(1, 1, 1, px.a * luminance))
    mono.blit_rect(mono_art, Rect2i(0, 0, 250, 140), Vector2i(91, 146))
    if not _save(mono, "res://assets/reset_night_adaptive_monochrome.png"):
        quit(1)
        return

    print("RESET NIGHT legacy, adaptive and monochrome launcher icons generated.")
    quit(0)

func _save(image: Image, resource_path: String) -> bool:
    var absolute_path := ProjectSettings.globalize_path(resource_path)
    var error := image.save_png(absolute_path)
    if error != OK:
        push_error("Could not create %s (error %s)" % [resource_path, error])
        return false
    return true
