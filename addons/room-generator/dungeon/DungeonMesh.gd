@tool
extends Node3D

@export var generate_mesh : bool = false : set = set_start
@export var gridmap_path : NodePath
@onready var gridmap : GridMap = get_node(gridmap_path)

var directions = {
	"up": Vector3i.FORWARD,
	"down": Vector3i.BACK,
	"left": Vector3i.LEFT,
	"right": Vector3i.RIGHT
}

var dungeon_cell_scene = preload("res://addons/room-generator/dungeon_tiles/wooden_walls.tscn")

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
	
func handle_44(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_45(cell, dir):
	cell.call("remove_door_"+dir)
func handle_46(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_54(cell, dir):
	cell.call("remove_door_"+dir)
func handle_55(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_56(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_64(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_65(cell, dir):
	cell.call("remove_wall_"+dir)
func handle_66(cell, dir):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)

func _ready():
	if Engine.is_editor_hint():
		pass
	else:
		create_dungeon()
		gridmap.hide()

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
	for c in gridmap.get_used_cells(): #for each cell in grid map
		var cell_index = gridmap.get_cell_item(c) #get the index of an item used
		
		#if the item selected are the ones being used (0-3, 3 excluded because its border cells)
		if cell_index <= 2 && cell_index >= 0: 
			var dungeon_cell = dungeon_cell_scene.instantiate()
			dungeon_cell.position = Vector3(c) + Vector3(0.5, 0, 0.5) #this position because cells are not perfectly alligned
			add_child(dungeon_cell)
			t += 1
			
			for i in 4: #each side of the wall
				var cell_n = c + directions.values()[i]
				var cell_n_index = gridmap.get_cell_item(cell_n)
				if cell_n_index == -1 || cell_n_index == 3:
					handle_none(dungeon_cell, directions.keys()[i])
				else:
					var key = str(cell_index) + str(cell_n_index)
					call("handle_"+key, dungeon_cell, directions.keys()[i])
		
			if Engine.is_editor_hint():
				var current_scene = EditorInterface.get_edited_scene_root()		
				dungeon_cell.owner = current_scene #this allows you to work with spawned cells in your scene
					
		if t%10 == 9: await get_tree().create_timer(0).timeout #I've added this timer to load textures slowly, 
		#because my laptop freezes for too long if dungeon is big, and I don't like frozen laptops.
