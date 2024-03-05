@tool
extends Node3D

@onready var floor = $floor
@onready var wall_up = $wall_up
@onready var door_up = $door_up
@onready var wall_left = $wall_left
@onready var door_left = $door_left
@onready var wall_down = $wall_down
@onready var door_down = $door_down
@onready var wall_right = $wall_right
@onready var door_right = $door_right
@onready var ceiling = $ceiling

func remove_wall_up():
	wall_up.free()
func remove_wall_down():
	wall_down.free()
func remove_wall_left():
	wall_left.free()
func remove_wall_right():
	wall_right.free()
func remove_door_up():
	door_up.free()
func remove_door_down():
	door_down.free()
func remove_door_left():
	door_left.free()
func remove_door_right():
	door_right.free()
	
