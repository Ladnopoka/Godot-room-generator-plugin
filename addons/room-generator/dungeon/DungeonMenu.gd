@tool
extends Node3D

@onready var grid_map : GridMap = $GridMap

@export var start : bool = false : set = set_start
@export var border_size : int = 20 : set = set_border_size
@export var room_size_minimum : int = 2
@export var room_size_maximum : int = 4
@export var room_number : int = 3
@export var room_margin : int = 1 #minimum distance the rooms must keep from each other
@export var room_recursion : int = 15

var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array

func set_start(val:bool):
	generate() #eventually generate a whole dungeon

func set_border_size(val : int):
	border_size = val
	if Engine.is_editor_hint():
		visualize_border()
	
func visualize_border():
	if grid_map:
		grid_map.clear() # need to clear every time because the textures stay
		for pos1 in range(-1, border_size+1):
			grid_map.set_cell_item(Vector3i(pos1, 0, -1), 5)
			grid_map.set_cell_item(Vector3i(pos1, 0, border_size), 5)
			grid_map.set_cell_item(Vector3i(border_size, 0, pos1), 5)
			grid_map.set_cell_item(Vector3i(-1, 0, pos1), 5)
	
func generate():
	room_tiles.clear()
	room_positions.clear()
	visualize_border()
	for i in room_number:
		generate_room(room_recursion)
	print(room_positions)
	
func generate_room(rec: int):
	if !rec > 0:
		return
	# get random width and heights
	var width : int = (randi() % (room_size_maximum - room_size_minimum)) + room_size_minimum
	var height : int = (randi() % (room_size_maximum - room_size_minimum)) + room_size_minimum
	
	#pick starting position
	var start_pos : Vector3i
	start_pos.x = randi() % (border_size - width + 1) # need to have +1 there at the end because of how the mod operator works in godot
	start_pos.z = randi() % (border_size - height + 1)
	
	for r in range(-room_margin, height + room_margin): 
		for c in range(-room_margin, width + room_margin):	
			var pos : Vector3i = start_pos + Vector3i(c, 0 , r)
			if grid_map.get_cell_item(pos) == 0:
				generate_room(rec-1)
				return
	
	#we fill in the columns from left to right 
	var room : PackedVector3Array = []
	for r in height: #for every row in height
		for c in width:	#for every row in width
			var pos : Vector3i = start_pos + Vector3i(c, 0 , r)
			grid_map.set_cell_item(pos, 2)
			room.append(pos)
	room_tiles.append(room)
	
	#calculating x an z positions separately
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)
