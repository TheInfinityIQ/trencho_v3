extends RefCounted

const Fixture = preload("res://resume_fixture.gd")
const ValueCodec = preload("res://checkpoint.gd")
const ALLOWED := ["scenario.gd", "squad.gd", "soldier.gd", "information.gd", "supply.gd", "rear.gd", "recovery.gd", "combat.gd", "vehicle_routes.gd", "vehicle.gd", "artillery.gd", "engineering.gd", "medical.gd", "battle.gd"]
var fixture
var reason := ""
var codec = ValueCodec.new()
var objects: Dictionary = {}
var records: Dictionary = {}

func object_key(value) -> String:
	var filename: String = value.get_script().resource_path.get_file()
	var identity = value.get("id") if filename in ["soldier.gd", "squad.gd", "vehicle.gd", "artillery.gd"] else null
	return filename + (":" + str(identity) if identity != null else "")

func fields(value) -> Array[String]:
	var result: Array[String] = []
	var filename: String = value.get_script().resource_path.get_file()
	for property in value.get_property_list():
		var derived: bool = (filename == "scenario.gd" and property.name == "battle_state") or (filename == "combat.gd" and property.name in ["suppression", "decay_at"])
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not derived:
			result.append(property.name)
	result.sort()
	return result

func encode(value):
	if value is WeakRef:
		var target = value.get_ref()
		if target == null:
			return null
		encode(target)
		return {"$weak": object_key(target)}
	if value is RandomNumberGenerator:
		return {"$rng": {"seed": value.seed, "state": value.state}}
	if value is Object:
		var key := object_key(value)
		if not records.has(key):
			objects[key] = value
			records[key] = {"script": value.get_script().resource_path, "fields": {}}
			for field in fields(value):
				records[key].fields[field] = encode(value.get(field))
		return {"$ref": key}
	if value is Array:
		return value.map(encode)
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = encode(value[key])
		return result
	return value

func graph(world) -> Dictionary:
	objects.clear()
	records.clear()
	encode(world)
	return records.duplicate(true)

func release_mapping() -> void:
	objects.clear()
	records.clear()

func exact_pack(value):
	if value is float:
		var bytes := PackedByteArray()
		bytes.resize(8)
		bytes.encode_double(0, value)
		return {"$value": "float64", "hex": bytes.hex_encode()}
	if value is Array:
		return value.map(exact_pack)
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = exact_pack(value[key])
		return result
	return codec.pack(value)

func semantic_snapshot(sample) -> String:
	var state := graph(sample.world)
	var result := JSON.stringify(exact_pack({"world": state, "authored": sample.authored, "progression": sample.progression, "initial_ammo": sample.initial_ammo}), "", true, true)
	release_mapping()
	return result

func serialize() -> String:
	reason = ""
	if fixture == null or not fixture.world.battle_active():
		reason = "FOCUSED_ACTIVE_FIXTURE_REQUIRED"
		return ""
	var state := graph(fixture.world)
	var text := JSON.stringify({"schema_version": 2, "fixture_id": Fixture.FIXTURE_ID, "checkpoint": "FOCUSED_ACTIVE",
		"world_time": exact_pack(fixture.world.elapsed), "objects": exact_pack(state), "authored": exact_pack(fixture.authored),
		"initial_ammo": exact_pack(fixture.initial_ammo), "progression": exact_pack(fixture.progression)}, "\t", true, true)
	release_mapping()
	return text

func references_valid(value, valid_keys: Dictionary) -> bool:
	if value is Array:
		return value.all(func(item): return references_valid(item, valid_keys))
	if value is Dictionary:
		if value.has("$ref") or value.has("$weak"):
			return value.size() == 1 and valid_keys.has(value.get("$ref", value.get("$weak")))
		if value.has("$rng"):
			return value.size() == 1 and value["$rng"] is Dictionary and value["$rng"].get("seed") is int and value["$rng"].get("state") is int
		return value.values().all(func(item): return references_valid(item, valid_keys))
	return not value is Object

func decode(value):
	if value is Array:
		return value.map(decode)
	if value is Dictionary:
		if value.has("$ref"):
			return objects[value["$ref"]]
		if value.has("$weak"):
			return weakref(objects[value["$weak"]])
		if value.has("$rng"):
			var rng := RandomNumberGenerator.new()
			rng.seed = value["$rng"].seed
			rng.state = value["$rng"].state
			return rng
		var result := {}
		for key in value:
			result[key] = decode(value[key])
		return result
	return value

func type_valid(template, saved) -> bool:
	if template == null:
		return true
	if template is WeakRef:
		return saved == null or (saved is Dictionary and saved.has("$weak"))
	if template is RandomNumberGenerator:
		return saved is Dictionary and saved.has("$rng")
	if template is Object:
		return saved is Dictionary and saved.has("$ref")
	if typeof(template) != typeof(saved):
		return false
	if template is Array and template.is_typed():
		return saved.all(func(item): return typeof(item) == template.get_typed_builtin())
	return true

func load_serialized(text: String) -> bool:
	reason = ""
	if text.to_utf8_buffer().size() > 4000000:
		reason = "ACTIVE_SAVE_TOO_LARGE"
		return false
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		reason = "MALFORMED_ACTIVE_SAVE"
		return false
	var raw: Dictionary = parser.data
	if not raw.has_all(["schema_version", "fixture_id", "checkpoint", "world_time", "objects", "authored", "initial_ammo", "progression"]):
		reason = "MISSING_ACTIVE_SAVE_FIELDS"
		return false
	if raw.schema_version != 2 or raw.fixture_id != Fixture.FIXTURE_ID or raw.checkpoint != "FOCUSED_ACTIVE":
		reason = "UNSUPPORTED_ACTIVE_SAVE"
		return false
	codec.reason = ""
	var state = codec.unpack(raw.objects)
	var authored = codec.unpack(raw.authored)
	var progression = codec.unpack(raw.progression)
	var initial_ammo = codec.unpack(raw.initial_ammo)
	var saved_time = codec.unpack(raw.world_time)
	if not codec.reason.is_empty() or not state is Dictionary or not authored is Dictionary or not authored.has_all(["mission", "work"]) or not progression is Dictionary or not progression.has_all(["meta", "campaign"]) or not initial_ammo is int or not saved_time is float or saved_time < 0:
		reason = "INVALID_ACTIVE_SAVE_STRUCTURE"
		return false
	# Rebuild immutable authored topology and all possible actors without running
	# any ticks. Key matching uses scripts and logical IDs, never object addresses.
	if not codec.valid_payload({"meta": progression.meta, "campaign": progression.campaign, "campaign_pool": progression.meta.get("unlocked_card_ids", []), "proof_tier2": true, "checkpoint": "BETWEEN_BATTLES", "save_identity": "active-proof", "revision": 1.0}):
		reason = "INVALID_ACTIVE_PROGRESSION"
		return false
	var candidate = Fixture.new(progression)
	var expected := graph(candidate.world)
	if state.size() != expected.size() or not state.has_all(expected.keys()):
		release_mapping()
		reason = "ACTIVE_OBJECT_SET_MISMATCH"
		return false
	for key in expected:
		if not state[key] is Dictionary or state[key].get("script") != expected[key].script or not state[key].get("fields") is Dictionary or state[key].fields.size() != expected[key].fields.size() or not state[key].fields.has_all(expected[key].fields.keys()) or state[key].script.get_file() not in ALLOWED:
			release_mapping()
			reason = "INVALID_ACTIVE_OBJECT_FIELDS"
			return false
		for field in state[key].fields:
			if not type_valid(objects[key].get(field), state[key].fields[field]):
				release_mapping()
				reason = "INVALID_ACTIVE_FIELD_TYPE"
				return false
	if not references_valid(state, expected) or state["scenario.gd"].fields.elapsed != saved_time or state["battle.gd"].fields.state != "ACTIVE":
		release_mapping()
		reason = "INVALID_ACTIVE_REFERENCES_OR_TIME"
		return false
	for key in state:
		var target = objects[key]
		for field in state[key].fields:
			var value = decode(state[key].fields[field])
			if target.get(field) is Array and value is Array:
				target.get(field).assign(value)
			else:
				target.set(field, value)
	candidate.authored = authored
	candidate.progression = progression
	candidate.initial_ammo = initial_ammo
	fixture = candidate
	release_mapping()
	return true
