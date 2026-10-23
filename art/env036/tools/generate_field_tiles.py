"""New code-native field textures after two image edits failed exact tiling.

This does not alter the supplied v1 RGB tiles. It authors two new periodic,
rotation-compatible 256px field textures from seeded noise and vertical furrows.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

JOB = Path(__file__).resolve().parent.parent
OUT = JOB / "terrain"
OUT.mkdir(parents=True, exist_ok=True)
N = 256
Y, X = np.mgrid[0:N, 0:N].astype(np.float64)


def smooth_noise(cells: int, seed: int, symmetric: bool) -> np.ndarray:
    rng = np.random.default_rng(seed)
    coarse = rng.normal(0, 1, (cells + 1, cells + 1)).astype(np.float32)
    coarse[-1, :] = coarse[0, :]
    coarse[:, -1] = coarse[:, 0]
    image = Image.fromarray(coarse, mode="F").resize((N, N), Image.Resampling.BICUBIC)
    field = np.asarray(image, dtype=np.float64)
    if symmetric:
        field = (field + field[::-1, :] + field[:, ::-1] + field[::-1, ::-1]) / 4
    std = max(float(field.std()), 1e-6)
    return (field - field.mean()) / std


def edge_symmetric(field: np.ndarray, width: float) -> np.ndarray:
    """Enforce 0/180-compatible edge phase without mirroring the interior."""
    mirror = (field + field[::-1, :] + field[:, ::-1] + field[::-1, ::-1]) / 4
    mirror = (mirror - mirror.mean()) * (field.std() / max(mirror.std(), 1e-6))
    distance = np.minimum.reduce((X, N - 1 - X, Y, N - 1 - Y))
    t = np.clip(1 - distance / width, 0, 1)
    t = t * t * (3 - 2 * t)
    return field * (1 - t) + mirror * t


base = sum(weight * smooth_noise(cells, 1000 + cells, False)
           for cells, weight in ((4, 7), (8, 6), (16, 5), (32, 4), (64, 2.2)))
base /= 13.0
base = edge_symmetric(base, 10)
grain = edge_symmetric(smooth_noise(128, 1171, False), 3)
furrow = np.cos(2 * np.pi * (X + .5) / 16.0)
furrow_detail = np.cos(2 * np.pi * (X + .5) / 8.0)
residue = edge_symmetric(smooth_noise(64, 1417, False), 4)
green = edge_symmetric(smooth_noise(32, 1583, False), 4)

def source_detail(path: Path) -> np.ndarray:
    """Use generated photo microdetail; periodic geometry remains code-native."""
    photo = Image.open(path).convert("RGB").resize((N, N), Image.Resampling.LANCZOS)
    blurred = photo.filter(ImageFilter.GaussianBlur(3.0))
    luminance = np.asarray(photo, dtype=np.float64).mean(axis=2)
    low = np.asarray(blurred, dtype=np.float64).mean(axis=2)
    return (luminance - low)


common_detail = edge_symmetric(source_detail(JOB / "source/field_imagegen_attempt_01.png"), 3)
alternate_detail = source_detail(JOB / "source/field_imagegen_attempt_02.png")

edge_distance = np.minimum.reduce((X, N - 1 - X, Y, N - 1 - Y))
window = np.clip(edge_distance / 12, 0, 1)
window = window * window * (3 - 2 * window)
results = {}
for variant, seed in ((1, 2011), (2, 2012)):
    local = (smooth_noise(8, seed, False) * 6 +
             smooth_noise(32, seed + 100, False) * 5 +
             smooth_noise(96, seed + 200, False) * 2) * window
    scalar = (16 * base + 8 * grain + 13 * furrow + 4 * furrow_detail + local
              + .9 * common_detail + (.45 * alternate_detail * window if variant == 2 else 0))
    straw = np.maximum(residue - .68, 0) * (12 if variant == 1 else 15)
    weeds = np.maximum(green - 1.5, 0) * 6
    shade = scalar + straw
    rgb = np.stack((99 + shade + 1.2 * base - weeds * .6,
                    80 + shade * .84 + weeds * 1.4,
                    52 + shade * .61 - weeds * .5), axis=-1)
    # Periodic D2 edge values are shared between variants and 180° rotation.
    # The interior-only variant noise fades into an already textured common edge.
    rgb = np.clip(np.rint(rgb), 0, 255).astype(np.uint8)
    name = f"field_{variant:02d}.png"
    Image.fromarray(rgb, "RGB").save(OUT / name)
    results[name] = {"mean_rgb": np.mean(rgb, axis=(0, 1)).round(2).tolist(),
                     "std_rgb": np.std(rgb, axis=(0, 1)).round(2).tolist()}
(JOB / "docs/field_generation.json").write_text(json.dumps({
    "method": "new seeded periodic procedural field; original v1 RGB tiles preserved unchanged",
    "canvas_px": [256, 256], "source_scale_px_per_m": 32,
    "furrow_pitch_px": 16, "furrow_orientation": "north_south",
    "allowed_rotations_deg": [0, 180], "variants": results,
    "reason": "v1 arbitrary mixed adjacency showed visible 8 m grid; imagegen attempts supplied realistic microtexture but not usable exact tile phase or straight furrows; new periodic vertical geometry and boundary-only 180 symmetry retain those details without the checkerboard of procedural attempt 01"
}, indent=2) + "\n")
print(results)
