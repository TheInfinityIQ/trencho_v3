extends SceneTree

const EXPECTED := {
    "buildings/house_b.png": Vector2i(320, 448),
    "buildings/house_c.png": Vector2i(384, 384),
    "buildings/farmhouse_d.png": Vector2i(416, 544),
    "access/driveway_short.png": Vector2i(160, 192),
    "access/driveway_long.png": Vector2i(160, 320),
    "access/yard_gravel.png": Vector2i(256, 256),
    "access/worn_ground.png": Vector2i(128, 128),
    "terrain/meadow_01.png": Vector2i(256, 256),
    "terrain/meadow_02.png": Vector2i(256, 256),
    "terrain/field_01.png": Vector2i(256, 256),
    "terrain/field_02.png": Vector2i(256, 256),
}

func _initialize() -> void:
    var results: Array[Dictionary] = []
    var failed := false
    for rel in EXPECTED:
        var path: String = "res://runtime/" + rel
        var image := Image.load_from_file(path)
        var texture = load(path)
        var ok: bool = not image.is_empty() and image.get_size() == EXPECTED[rel] and texture is Texture2D
        results.append({"file": rel, "ok": ok, "size": [image.get_width(), image.get_height()], "texture_imported": texture is Texture2D})
        if not ok:
            failed = true
    var report := {"godot_check": "runtime Image load, imported Texture2D resource and dimensions", "failed": failed, "assets": results}
    var f := FileAccess.open("res://native_validation.json", FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(report, "  "))
        f.close()
    else:
        failed = true
    quit(1 if failed else 0)
