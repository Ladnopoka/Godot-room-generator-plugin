@tool
extends Node3D

@onready var wall_up = $wall_up
@onready var wall_left = $wall_left
@onready var wall_down = $wall_down
@onready var wall_right = $wall_right

func remove_wall_up():
	wall_up.free()
func remove_wall_down():
	wall_down.free()
func remove_wall_left():
	wall_left.free()
func remove_wall_right():
	wall_right.free()
