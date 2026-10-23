extends RefCounted
## Shared immutable source data/texture cache. No Soldier state lives here.
const ROOT := "res://art/modular_soldier_v3/"
const NAMES := ["standing_idle", "standing_walk", "standing_sprint", "crouch_idle", "crouch_walk", "prone_ready", "prone_move", "stand_to_crouch", "crouch_to_stand", "crouch_to_prone", "prone_to_crouch", "death_backward", "death_prone", "death_forward"]
const PARTS := ["left_leg", "right_leg", "front_equipment", "back_equipment", "shoulders", "left_arm", "right_arm", "left_arm_splayed", "right_arm_splayed", "rifle_topdown", "rifle_side_dropped", "head"]
static var _cache: Dictionary = {}

static func clip(name: String) -> Dictionary:
	if not _cache.has(name):
		assert(name in NAMES, "Unknown source Soldier clip")
		var folder := ROOT + "clips/" + name + "/"
		var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "assembly_manifest.json"))
		var frames: Array = []
		for frame in metadata.frames:
			var textures := {}
			for part in frame.parts: textures[part] = load(folder + frame.parts[part].file)
			frames.append(textures)
		_cache[name] = {"metadata":metadata, "textures":frames}
	return _cache[name]
