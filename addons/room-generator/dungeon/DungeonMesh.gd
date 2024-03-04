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

func handle_none(cell, dir):
	cell.call("remove_door_"+dir)
func handle_00(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_01(cell, dir):
	cell.call("remove_door_"+dir)
func handle_02(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_10(cell, dir):
	cell.call("remove_door_"+dir)
func handle_11(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_12(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_20(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_21(cell, dir):
	cell.call("remove_wall_"+dir)
func handle_22(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
	
func set_start(val):
	if Engine.is_editor_hint():
		create_dungeon()

func create_dungeon():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	var t : int = 0
	
	#this is to offset the instances position to allign with the cells in 
	#the grid map, since they are centered, but our objects are not.
	for c in grid_map.get_used_cells(): 
		var cell_index = grid_map.get_cell_item(c)
		if cell_index <= 2 && cell_index >= 0:
			var dungeon_cell = dungeon_cell_scene.instantiate()
			dungeon_cell.position = Vector3(c) + Vector3(0.5, 0, 0.5)
			add_child(dungeon_cell)
			t += 1
			
			for i in 4: #each side of the wall
				var cell_n = c + directions.values()[i]
				var cell_n_index = grid_map.get_cell_item(cell_n)
				if cell_n_index == -1 || cell_n_index == 3:
					handle_none(dungeon_cell, directions.keys()[i])
				else:
					var key = str(cell_index) + str(cell_n_index)
					call("handle_"+key, dungeon_cell, directions.keys()[i])
					
		if t%10 == 9: await get_tree().create_timer(0).timeout
