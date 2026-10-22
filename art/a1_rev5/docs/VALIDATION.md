# Trencho v3 A1 Consolidated Rev5 validation

Status: SOURCE READY / ENGINE CHECK PENDING

## Runtime completeness
- Runtime PNG count: 18 (expected 18)
- All referenced runtime/proof files exist: True

## House
- content_bbox_px: [16, 14, 304, 424]
- authoritative_footprint_rect_px: [32, 26, 288, 410] = 256x384 px = 8x12 m
- footprint covered by rendered envelope: True
- entrance_point_px: [160, 404]
- bottom_row_alpha>=128 count: 0

## Road corner
- centerline type: quarter-circle arc
- center: [511,511]
- radius: 311 px = 9.71875 m
- south port: [200,511], outward tangent [0,1]
- east port: [511,200], outward tangent [1,0]
- paved width: 192 px = 6 m
- inner pavement radius: 215 px = 6.71875 m (positive; no inner-offset self-overlap)