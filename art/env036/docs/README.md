# T3-ENV-036 rural add-on source correction

This is a bounded corrected candidate for three rural building silhouettes, four independent access overlays, two meadow tiles and two cultivated field tiles. It does not replace existing Rev5/Rev6/Soldier runtime art and does not add tree, junction, depot, combat or damage assets. Source scale is 32 px/m.

Nine runtime PNGs are byte-identical to the immutable v1 archive: all three buildings, all four access overlays and both meadow tiles. Only `terrain/field_01.png` and `terrain/field_02.png` are newly generated candidates because the v1 mixed patch showed an 8 m grid. The new field pair is 256×256 RGB, 8×8 m, with north-south furrows and permitted rotations 0/180. `reference/field_mixed_4x4_320.png` and `reference/field_boundary_local_crop_320.png` are the key visual checks.

The buildings retain their original 6×10, 10×10 and 10×14 m nominal rectangles, but those rectangles do not bound all visible roof/eave/porch pixels and contain transparent areas. `placement_envelope_px` is the conservative full-art clearance for presentation scenes: alpha bounds plus 4 px. Precise wall collision/navigation needs an authored game shape. Exterior entrance ports are at the south porch thresholds, just beyond the nominal rectangles. The source PNGs were not stretched or repainted. The access PNGs are unchanged; `reference/connected_road_to_house_b_full.png` demonstrates a real overlapping road-to-threshold chain, with exact positions in metadata.

Read `docs/PARCEL_STRATEGY.md` before integrating fields. Field material tiles in world space and is clipped by a parcel polygon with a 0.375 m outer land-use transition against accepted Rev6 grass. This boundary mask is for the parcel, not an internal tile seam concealment.

`docs/file_hashes.json` lists hashes of all other package members and intentionally omits itself; the outer ZIP SHA256 pins that manifest. `docs/VALIDATION.md` states completed and pending checks. Original v1 archive remains intact for rollback.
