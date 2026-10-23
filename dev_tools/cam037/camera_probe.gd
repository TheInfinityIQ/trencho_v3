extends "res://representative_sector.gd"
var camera_update_us := 0
var debug_draw_us := 0
var debug_draw_count := 0
var activation_calls := 0

func _process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	super._process(delta)
	camera_update_us = Time.get_ticks_usec() - started

func draw_debug(canvas: Node2D) -> void:
	var started := Time.get_ticks_usec()
	super.draw_debug(canvas)
	debug_draw_us = Time.get_ticks_usec() - started
	debug_draw_count += 1

func update_activation() -> void:
	activation_calls += 1
	super.update_activation()
