# Field parcels on Rev6 grass

Use one world-space field sampling lattice: 1 source pixel = 1/32 m, one tile = 256 px = 8 m. Choose field_01/field_02 and rotation 0/180 by a deterministic tile hash. The two revised RGB field PNGs share a common boundary phase. Sample them at integer source-pixel coordinates derived from world meters, not from each parcel's local origin. Adjacent tiles meet without a per-tile cover strip.

Create a property polygon in world meters for each cultivated parcel. It can be mostly straight-sided with bounded irregular corner/edge points, but it must be one polygon for the property, not a separate mask per 8 m tile. Convert vertices to source pixels by multiplying by 32. Let `d` be signed distance in source pixels to the polygon boundary (positive inside). Composite the field over the existing Rev6 grass with `alpha = smoothstep(0, 12, d)`; 12 source px = 0.375 m. Do not blur or overlay internal tile joins. Keep the grass underlying the polygon so only its outer land-use transition is softened.

Render/tile with mipmaps and the existing game camera filters. At Local 0.3125, the 12 px outer feather occupies 3.75 screen pixels. At Tactical 0.1 it is 1.2 pixels; at Sector 0.0202 it is subpixel, while the property polygon remains the visible land-use cue. The proof source is a 64×64 m sample (2048×2048 px) with a single irregular parcel; the scaled proof PNGs use exactly those three zoom factors. The masked transition is an explicit source placement strategy, not developer repainting or a hidden fix for failed tile adjacency.

The original v1 field tiles and the accepted Rev6 grass files are unchanged. The new field textures are candidates pending independent engine and human visual assessment.
