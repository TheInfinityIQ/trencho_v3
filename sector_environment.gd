extends RefCounted
## ENV-036 composition on the accepted sector; no gameplay ownership.
const LandUse = preload("res://sector_land_use.gd")
const Properties = preload("res://sector_properties.gd")
const Layout = preload("res://sector_layout.gd")
const VERSION := "env036-v1"
var land_use = LandUse.new()
var properties: Array = []
var access: Array = []
var catalog: Dictionary = {}
var source_identity := ""

func configure(source: Dictionary, source_hash: String) -> void:
	source_identity = source_hash
	catalog = {"house":{"id":"house", "file":"res://art/a1_rev5/buildings/house_rural.png", "canvas_px":[320, 448], "pivot_px":[160, 218], "clearance_px":[12, 10, 308, 428], "entrance_px":[160, 404]}}
	for file in source.buildings:
		var item: Dictionary = source.buildings[file]
		var id: String = file.get_file().get_basename()
		catalog[id] = {"id":id, "file":"res://art/env036/" + file, "canvas_px":item.canvas_px, "pivot_px":item.pivot_px, "clearance_px":item.placement_envelope_px, "nominal_size_m":item.physical_footprint_m, "entrance_px":item.entrance_px}
	for file in source.access_overlays:
		var item: Dictionary = source.access_overlays[file]
		var id: String = file.get_file().get_basename()
		catalog[id] = {"id":id, "file":"res://art/env036/" + file, "canvas_px":item.canvas_px, "pivot_px":item.pivot_px}

func compose(layout) -> void:
	var baseline: String = layout.fingerprint
	land_use.generate(layout)
	var buildings := []
	for key in ["house", "house_b", "house_c", "farmhouse_d"]: buildings.append(catalog[key])
	properties = Properties.compose(layout, buildings)
	access = Properties.access_modules(properties)

	for chunk in layout.chunks:
		chunk["properties"] = []
		chunk["access"] = []
		chunk["parcels"] = []
		chunk.trees.clear()
	for i in range(properties.size()):
		var owner: Vector2i = properties[i].owner
		layout.chunks[owner.y * 6 + owner.x].properties.append(i)
	for i in range(access.size()):
		var owner: Vector2i = access[i].owner
		layout.chunks[owner.y * 6 + owner.x].access.append(i)
	for i in range(land_use.parcels.size()):
		var owner: Vector2i = land_use.parcels[i].owner
		layout.chunks[owner.y * 6 + owner.x].parcels.append(i)
	var retained := []
	for tree in layout.trees:
		if land_use.cultivated(tree.position, 3) or not Properties.tree_clear(tree.position, properties): continue
		retained.append(tree)
	layout.trees = retained
	for i in range(layout.trees.size()): layout.index_object(layout.trees[i], "trees", i)
	layout.fingerprint = JSON.stringify(Layout.canonical({"version":VERSION, "baseline":baseline, "source":source_identity, "parcels":land_use.parcels, "properties":properties, "access":access, "trees":retained}), "", true, true).sha256_text()
