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
		for pos1 in range(-1, border_size+1): # border size has to be 1 grid cell bigger because of inner contents
			grid_map.set_cell_item(Vector3i(pos1, 0, -1), 5)
			grid_map.set_cell_item(Vector3i(pos1, 0, border_size), 5)
			grid_map.set_cell_item(Vector3i(border_size, 0, pos1), 5)
			grid_map.set_cell_item(Vector3i(-1, 0, pos1), 5)
	
func generate():
	room_tiles.clear() #need to clear
	room_positions.clear() #need to clear 
	visualize_border()
	for i in room_number: # for every room number
		generate_room(room_recursion)
	print(room_positions) #debugger to see position values
	
	var room_pv2 : PackedVector2Array = []
	var delaunay_graph : AStar2D = AStar2D.new() #AStar2D requires and ID and a position for each point
	var min_span_tree_graph : AStar2D = AStar2D.new()
	
	#turn room positions into Vector2's, this only places the points
	for p in room_positions:
		room_pv2.append(Vector2(p.x,p.z))
		delaunay_graph.add_point(delaunay_graph.get_available_point_id(), Vector2(p.x,p.z))
		min_span_tree_graph.add_point(min_span_tree_graph.get_available_point_id(), Vector2(p.x,p.z))
	
	# Doing the actual triangulation
	# triangulate_delaunay() function here takes in a packed Vector2 array
	# and returns an array of integers in a form of a packed int32 array
	# we need to conver this into a regular array first
	var delaunay_triangulation = Array(Geometry2D.triangulate_delaunay(room_pv2))
	
	# explained more in depth in the report
	for i in delaunay_triangulation.size()/3: # 3 for number of triangles
		var p1 = delaunay_triangulation.pop_front()
		var p2 = delaunay_triangulation.pop_front()
		var p3 = delaunay_triangulation.pop_front()
		delaunay_graph.connect_points(p1, p2)
		delaunay_graph.connect_points(p2, p3)
		delaunay_graph.connect_points(p1, p3)
		
	var visited_points = []
	visited_points.append(randi() % room_positions.size())
	while visited_points.size() != min_span_tree_graph.get_point_count():
		var possible_connections = []
		for vp in visited_points:
			for c in delaunay_graph.get_point_connections(vp):
				if !visited_points.has(c):
					var con = [vp,c]
					possible_connections.append(con)
		
		var connection = possible_connections.pick_random()
	
func generate_room(rec: int):
	if !rec > 0: #don't run if recursion limit is reached
		return
	# get random width and heights
	var width : int = (randi() % (room_size_maximum - room_size_minimum)) + room_size_minimum
	var height : int = (randi() % (room_size_maximum - room_size_minimum)) + room_size_minimum
	
	#pick starting position
	var start_pos : Vector3i
	start_pos.x = randi() % (border_size - width + 1) # need to have +1 there at the end because of how the mod operator works
	start_pos.z = randi() % (border_size - height + 1)
	
	# Minimum distance checker that rooms should keep away form each other (margin)
	for r in range(-room_margin, height + room_margin): #for every row in height
		for c in range(-room_margin, width + room_margin):	#for every column in width
			var pos : Vector3i = start_pos + Vector3i(c, 0 , r) # variable for the position
			if grid_map.get_cell_item(pos) == 4: #check if the cell is a previously defined texture (hardcoded number fix later)
				generate_room(rec-1) #gererate rooms until recursion checker is triggered
				return
	
	#we fill in the columns from left to right 
	var room : PackedVector3Array = []
	for r in height: #for every row in height
		for c in width:	#for every column in width
			var pos : Vector3i = start_pos + Vector3i(c, 0 , r) # variable for the position
			grid_map.set_cell_item(pos, 4) #set texture for dungeon walls
			room.append(pos) 	#add to room array for each iteration
	room_tiles.append(room) #append whole room to the tiles
	
	#calculating x an z positions separately
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)
