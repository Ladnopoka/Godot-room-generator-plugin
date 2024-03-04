@tool
extends Node3D

@export var start : bool = false : set = set_start
@export var grid_map_path : NodePath
@onready var grid_map : GridMap = get_node(grid_map_path)

var directions = {
	"up": Vector3i.FORWARD,
	"down": Vector3i.BACK,
	"left": Vector3i.LEFT,
	"right": Vector3i.RIGHT
}

var dungeon_cell_scene = preload("res://addons/room-generator/dungeon_tiles/dungeon_tiles_directional.tscn")

func set_start(val):
	if Engine.is_editor_hint():
		create_dungeon()#

func create_dungeon():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	#this is to offset the instances position to allign with the cells in 
	#the grid map, since they are centered, but our objects are not.
	for c in grid_map.get_used_cells(): 
		var cell_index = grid_map.get_cell_item(c)
		if cell_index <= 2 && cell_index >= 0:
			var dungeon_cell = dungeon_cell_scene.instantiate()
			dungeon_cell.position = Vector3(c) + Vector3(0.5, 0, 0.5)
			add_child(dungeon_cell)
