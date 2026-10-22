# Grass-only correction patch Rev6 validation

Parent Rev5 whole-ZIP SHA-256: bf6e01da1a4c58d8879305b313a0e5637a92377a68bb1cebce08b21e3e2b4adc

## Runtime grass PNG hashes
- terrain/terrain_grass_01.png: b8868dfb4ee76c5c95cf65f06ddd383aed1be27c6d5a23c77db3216d9eea61fb (149905 bytes)
- terrain/terrain_grass_02.png: 24a7436015cabb92a2380628ee7508da5d3559fe8035428233d92800107c78a1 (150179 bytes)

## Exact edge checks
- A_right_equals_A_left: True
- A_right_equals_B_left: True
- B_right_equals_A_left: True
- B_right_equals_B_left: True
- A_bottom_equals_A_top: True
- A_bottom_equals_B_top: True
- B_bottom_equals_A_top: True
- B_bottom_equals_B_top: True
- A_rot90_right_equals_A_left: True
- B_rot90_right_equals_A_left: True

## Edge-vs-near-interior luminance deltas
- A_outer1_minus_next15_top: 1.8679
- A_outer1_minus_next15_left: 0.5817
- B_outer1_minus_next15_top: 4.8718
- B_outer1_minus_next15_left: 2.3718

## Proof images
- reference/grass_rotated_4x4_full.png
- reference/grass_rotated_4x4_downsample_320.png