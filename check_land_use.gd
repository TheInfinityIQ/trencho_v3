extends SceneTree
const Layout = preload("res://sector_layout.gd")
const LandUse = preload("res://sector_land_use.gd")
const Properties = preload("res://sector_properties.gd")
const Rural = preload("res://sector_environment.gd")
const OUT := "res://artifacts/env036/"
var checks := 0
var failures: Array[String] = []
var evidence: Array = []
var native_complete := false

func _initialize() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/docs/metadata.json"))
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/env036/provenance.json"))
	var source_ok := true
	for path in provenance.source_file_sha256: source_ok = source_ok and FileAccess.get_sha256("res://art/env036/" + path) == provenance.source_file_sha256[path]
	expect(source_ok and provenance.source_file_sha256.size() == 37, "All37source members retain verified artist bytes")
	var imports_ok := true
	for path in source.runtime_pngs:
		var config := ConfigFile.new()
		imports_ok = imports_ok and config.load("res://art/env036/" + path + ".import") == OK and config.get_value("params", "mipmaps/generate", false) and config.get_value("params", "compress/mode", -1) == 0
	expect(imports_ok, "All11runtime images import losslessly with mipmaps")
	var fingerprints := []
	for seed_value in [35035, 35036]:
		var layout = Layout.new(); layout.generate(seed_value)
		var use = LandUse.new(); use.generate(layout)
		var second = LandUse.new(); second.generate(layout)
		var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/a1_rev5/docs/metadata.json"))
		var catalog := [{"id":"house", "pivot_px":[160, 218], "clearance_px":metadata.house.authoritative_footprint_rect_px, "entrance_px":metadata.house.entrance_point_px}]
		var properties: Array = Properties.compose(layout, catalog)
		var property_valid: bool = properties.size() == layout.houses.size()
		for i in range(properties.size()):
			var property: Dictionary = properties[i]
			property_valid = property_valid and property.presentation_clearance_bounds == layout.houses[i].footprint and absf(property.road_access.y - layout.village.y) == 3 and property.access_direction.dot(property.road_access - property.presentation_access_anchor) > 0
			property_valid = property_valid and not Properties.tree_clear(property.presentation_access_anchor, properties) and not Properties.tree_clear(property.yard, properties)
		expect(property_valid, "Existing source footprint/entrance produces road-facing property access and tree exclusions")
		expect(JSON.stringify(Layout.canonical(use.parcels), "", true, true) == JSON.stringify(Layout.canonical(second.parcels), "", true, true), "Seeded parcel placement repeats")
		var fields := 0
		var meadows := 0
		var valid := true
		for i in range(use.parcels.size()):
			var parcel: Dictionary = use.parcels[i]
			if parcel.family == "field": fields += 1
			else: meadows += 1
			valid = valid and Rect2(Vector2.ZERO, Layout.SIZE).encloses(parcel.bounds) and parcel.owner == Layout.owner(parcel.position)
			for j in range(i): valid = valid and not parcel.bounds.grow(16).intersects(use.parcels[j].bounds)
			for house in layout.houses: valid = valid and not house.footprint.grow(24).intersects(parcel.bounds)
			for road in layout.roads:
				for fraction in [0.0, 0.5, 1.0]: valid = valid and not parcel.bounds.grow(12).has_point(layout.sample_segment(road, road.length * fraction).position)
			expect(use.family_at(parcel.position) == parcel.family and use.cultivated(parcel.position) == (parcel.family == "field"), "Parcel lookup classifies its land use")
		expect(fields == 6 and meadows == 3 and valid, "Six coherent fields/three meadows preserve boundaries/road/property reserve")
		var nominal_before := JSON.stringify(Layout.canonical(layout.houses), "", true, true)
		var rural = Rural.new(); rural.configure(source, provenance.archive_sha256); rural.compose(layout)
		var duplicate = Layout.new(); duplicate.generate(seed_value)
		var second_rural = Rural.new(); second_rural.configure(source, provenance.archive_sha256); second_rural.compose(duplicate)
		expect(layout.fingerprint == duplicate.fingerprint, "Source/version/seed reproduces complete environment composition")
		expect(nominal_before == JSON.stringify(Layout.canonical(layout.houses), "", true, true), "Presentation does not relabel original nominal fixture house records")
		fingerprints.append(layout.fingerprint)
		var variants := {}
		var clearance_ok := true
		var access_ok := true
		for i in range(rural.properties.size()):
			var property: Dictionary = rural.properties[i]
			variants[property.asset] = true
			clearance_ok = clearance_ok and property.presentation_clearance_bounds.has_point(property.presentation_access_anchor) and not property.has("physical_footprint")
			for j in range(i): clearance_ok = clearance_ok and not property.presentation_clearance_bounds.intersects(rural.properties[j].presentation_clearance_bounds)
			if i > 0: clearance_ok = clearance_ok and property.asset != rural.properties[i - 1].asset
			for step in range(31):
				var point: Vector2 = property.road_access.lerp(property.presentation_access_anchor, step / 30.0)
				var covered := false
				for module in rural.access:
					if module.property != property.id: continue
					var size := Vector2(3, module.span) if module.has("span") else (Vector2(6, 6) if module.asset == "yard_gravel" else Vector2(3, 3))
					covered = covered or Rect2(module.position - size * 0.5, size).grow(0.001).has_point(point)
				access_ok = access_ok and covered
		expect(clearance_ok and variants.size() == 4, "Four silhouettes, adjacent variation and disjoint authoritative PRESENTATION clearances; anchors contained")
		expect(access_ok, "Authored access spans overlap continuously from road edge to exterior presentation anchor")
		var vegetation_ok: bool = layout.trees.size() >= 100 and layout.trees.size() <= 300
		for tree in layout.trees: vegetation_ok = vegetation_ok and not rural.land_use.cultivated(tree.position, 3) and Properties.tree_clear(tree.position, rural.properties)
		expect(vegetation_ok, "Vegetation excludes cultivated parcels, conservative building clearances, yards and accesses")
		var ownership_ok := true
		for kind in ["properties", "access", "parcels"]:
			var items: Array = rural.land_use.parcels if kind == "parcels" else rural.get(kind)
			var indexed := 0
			for chunk in layout.chunks:
				for index in chunk[kind]:
					ownership_ok = ownership_ok and items[index].owner == chunk.key and Layout.owner(items[index].position) == chunk.key
					indexed += 1
			ownership_ok = ownership_ok and indexed == items.size()
		expect(ownership_ok, "Every parcel/property/access object indexed once by logical owner")
		evidence.append({"seed":seed_value, "fingerprint":layout.fingerprint, "properties":rural.properties.size(), "access_modules":rural.access.size(), "fields":6, "meadows":3, "trees":layout.trees.size()})
	expect(fingerprints[0] != fingerprints[1], "Alternate seed changes environment composition")
	if "--visual" in OS.get_cmdline_user_args():
		await visual_run()
		expect(native_complete, "Native environment verification reaches completion")
	var file := FileAccess.open(OUT + "checks.json", FileAccess.WRITE); file.store_string(JSON.stringify({"checks":checks, "failures":failures, "evidence":evidence}, "\t")); file.close()
	print("ENV036 CHECKS: ", checks, " failures: ", failures)
	quit(0 if failures.is_empty() else 1)

func capture(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func visual_run() -> void:
	var view = load("res://representative_sector.tscn").instantiate(); root.add_child(view)
	await process_frame; await process_frame; view.paused = true
	expect(not view.debug_enabled and view.world.friendly_people().size() == 18 and view.visuals.size() == 27 and view.people.size() == 27, "Clean scene binds18friendly and9physical enemies")
	await capture("local_street_default")
	var before: Vector2 = view.people[0].position
	var truck_before: float = view.truck_distance
	view.advance_models(4)
	expect(is_equal_approx(view.people[0].position.distance_to(before), 5.6) and is_equal_approx(view.truck_distance - truck_before, 48), "Accepted1.4/12m/s model/truck motion preserved")
	await capture("local_street_walking")
	view.set_mode("tactical"); await capture("tactical_settlement")
	view.toggle_debug(); await capture("tactical_property_debug"); view.toggle_debug()
	var generations: int = view.generation_count
	var fingerprint: String = view.layout.fingerprint
	var nodes := count_nodes(view)
	view.camera.position = Layout.SIZE * 0.5 * 32
	view.set_mode("sector"); await capture("sector_overview")
	view.toggle_debug(); await capture("sector_parcel_debug"); view.toggle_debug()
	expect(view.active_chunks == 24 and view.generation_count == generations and view.layout.fingerprint == fingerprint and count_nodes(view) == nodes, "Whole-sector camera/culling does not regenerate environment")
	for family in ["field", "meadow"]:
		for parcel in view.environment.land_use.parcels:
			if parcel.family != family: continue
			view.set_mode("local"); view.camera.position = (parcel.bounds.position + Vector2(32, 24)) * 32; view.clamp_camera(); view.update_activation()
			await capture(family + "_local_boundary")
			view.set_mode("tactical"); view.camera.position = parcel.position * 32; view.clamp_camera(); view.update_activation()
			await capture(family + "_tactical")
			break
	for parcel in view.environment.land_use.parcels:
		if parcel.family != "field": continue
		var line_x := ceilf(parcel.bounds.position.x / 256) * 256
		if line_x < parcel.bounds.position.x + 16 or line_x > parcel.bounds.end.x - 16: continue
		view.set_mode("local"); view.camera.position = Vector2(line_x, parcel.position.y) * 32; view.clamp_camera(); view.update_activation()
		await capture("field_chunk_boundary_local")
		break
	for mode in ["local", "tactical"]:
		view.set_mode(mode); view.paused = false
		for warmup in range(30): await process_frame
		var intervals := []; var updates := []; var previous := Time.get_ticks_usec()
		for sample in range(120):
			await process_frame
			var now := Time.get_ticks_usec(); intervals.append((now - previous) / 1000.0); previous = now; updates.append(view.update_us / 1000.0)
		intervals.sort(); updates.sort()
		evidence.append({"mode":mode, "active_chunks":view.active_chunks, "frame_interval_p50_ms":intervals[60], "frame_interval_p95_ms":intervals[114], "model_adapter_update_p50_ms":updates[60], "model_adapter_update_p95_ms":updates[114]})
	view.paused = true
	evidence.append({"nodes":nodes, "process_nodes":count_processing(view), "batches_and_parcel_fragments":view.batch_count, "generation_ms":view.generation_ms})
	view.set_seed(35036); view.paused = true
	view.set_mode("tactical"); await capture("alternate_tactical")
	view.set_mode("sector"); await capture("alternate_sector")
	expect(view.layout.seed_value == 35036 and view.layout.fingerprint != fingerprint and view.generation_count == generations + 1, "Explicit alternate seed changes environment")
	view.free(); await process_frame
	native_complete = true

func count_nodes(node: Node) -> int:
	var result := 1
	for child in node.get_children(): result += count_nodes(child)
	return result

func count_processing(node: Node) -> int:
	var result := 1 if node.is_processing() or node.is_physics_processing() else 0
	for child in node.get_children(): result += count_processing(child)
	return result
