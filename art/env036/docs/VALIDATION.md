# T3-ENV-036 corrected candidate checks

Source ZIP v1 SHA256: `1a3b6d5cb913ff57e0b1f4aaeeae65a62a5bb76a5d881ba0ecb20f912fee336b` (preserved, not modified).

- Eleven runtime PNGs retained: three RGBA buildings, four RGBA access overlays, two original RGB meadow tiles and two revised RGB field tiles. RGB is intentional for fully opaque terrain.
- Nine runtime files are byte-identical to v1; only the two field PNGs differ. Their exact hashes are in `docs/file_hashes.json`.
- Building dimensions/pivots unchanged; coverage audit in `docs/building_coverage.json` and annotated footprints shows their declared rectangles are nominal size references, not full artwork bounds or collision shapes. `placement_envelope_px` covers actual visible pixels plus 4 px clearance. South interaction ports are at visible exterior porch thresholds beyond the nominal rectangles.
- Revised field mixed 4×4 patch inspected at 1024×1024 and 320×320 with variants and 0/180 rotations. Unchanged meadow mixed 4×4 inspected at full/320 with all cardinal rotations. Metrics in `reference/seam_metrics.json` are diagnostic only.
- Parcel against actual Rev6 grass inspected at Local 0.3125, Tactical 0.1 and Sector 0.0202 from one 2048×2048 source composition. The 12 px transition is only at the outer parcel polygon.
- Connected road→long-driveway→gravel apron→worn threshold→House B proof is composited from actual unchanged runtime access/building PNGs and accepted Rev5 road. Coordinates in metadata; no gap remains between driveway axis and road/threshold.
- Godot 4.7.2 import and resource/dimension checks passed for all 11 runtime PNGs in an isolated proof project; detailed machine result is `docs/godot_validation.json`. This is an import check, not an in-game MAP-035 scene review or human approval.

Limitations: porch facade is stylized and is not a visibly open door. The new placement envelopes provide art clearance only; strict physical footprints, wall collision and navigation shapes remain a source-art/gameplay contract gap. No independent in-game MAP-035 integration by the artist and no human art approval are claimed.
