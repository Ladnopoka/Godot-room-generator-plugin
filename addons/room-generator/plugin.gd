@tool
extends EditorPlugin

#const dungeon_menu_script = preload("res://addons/room-generator/dungeon/DungeonMenu.gd")
const panel = preload("res://addons/room-generator/panel.tscn")
const RoomTemplate = preload("res://addons/room-generator/room_template/room_template.tscn")
const dungeon_corner_in = preload("res://addons/room-generator/dungeon_tiles/dungeon_corner_in.tscn")
const dungeon_corner_out = preload("res://addons/room-generator/dungeon_tiles/dungeon_corner_out.tscn")
const dungeon_floor = preload("res://addons/room-generator/dungeon_tiles/dungeon_floor.tscn")
const dungeon_wall = preload("res://addons/room-generator/dungeon_tiles/dungeon_wall.tscn")
const dungeon_menu = preload("res://addons/room-generator/dungeon/dungeon_menu.tscn")

var dockedScene
#var toggle_button: Button
var tab_container: TabContainer
var is_content_visible: bool = false  # Tracks whether the content is currently visible

var wall_button: Button
var button2: Button
var button3: Button
var hideout_button: Button
var dungeon_menu_button: MenuButton
var dungeon_layout_button: Button
var dungeon_popup_menu
var wooden_cabins_popup_menu
var stored_gridmaps: Array[GridMap] = []
var wooden_cabin_menu_button

# Get the undo/redo object
var undo_redo = get_undo_redo()

func _enter_tree():
	dockedScene = panel.instantiate()
	print("RoomGenerator panel scene instantiated!")
	
	tab_container = dockedScene.get_node("TabContainer")
	tab_container.visible = true
	
	setup_button_connections()
	setup_menu_button()
		
	# Initial setup when the plugin is enabled
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dockedScene)

func setup_button_connections():
	# Connect the toggle button signal
	wall_button = dockedScene.get_node("TabContainer/Models/Wall")
	button2 = dockedScene.get_node("TabContainer/Models/Cube")
	button3 = dockedScene.get_node("TabContainer/Layouts/Room")
	hideout_button = dockedScene.get_node("TabContainer/Layouts/Hideout")
	dungeon_menu_button = dockedScene.get_node("TabContainer/Models/DungeonGeneratorMenu")
	wooden_cabin_menu_button = dockedScene.get_node("TabContainer/Models/DungeonGeneratorMenu")
	dungeon_layout_button = dockedScene.get_node("TabContainer/Layouts/Dungeon")
	wooden_cabin_menu_button = dockedScene.get_node("TabContainer/Models/WoodenCabinGeneratorMenu")	
	
	wall_button.connect("pressed", create_wall)
	button2.connect("pressed", create_box)
	button3.connect("pressed", create_room)
	#menu_button.connect("pressed", menu_button_pressed)
	wooden_cabin_menu_button.connect("pressed", wooden_cabin_menu_button_pressed)
	
func wooden_cabin_menu_button_pressed():
	if wooden_cabins_popup_menu:
		wooden_cabins_popup_menu.clear()
	wooden_cabins_popup_menu = wooden_cabin_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.408, 0.241, 0.007) # Example brown color

	var popup_font = FontFile.new()
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file
	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.0, 0.0, 0.0))  
	popup_theme.set_font_size("font_size", "PopupMenu", 30)

	wooden_cabins_popup_menu.theme = popup_theme
	wooden_cabins_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	wooden_cabins_popup_menu.add_item("Wall")
	wooden_cabins_popup_menu.add_item("Door")
	wooden_cabins_popup_menu.add_item("Roof")
	wooden_cabins_popup_menu.add_item("Floor")
	wooden_cabins_popup_menu.add_item("GridMap Generator")
	#wooden_cabins_popup_menu.connect("id_pressed", _on_model_selected)
	
func setup_menu_button():
	dungeon_popup_menu = dungeon_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0)  # Example brown color

	var popup_font = FontFile.new()
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file
	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.5, 0.2, 0.2))  # Set to black
	popup_theme.set_font_size("font_size", "PopupMenu", 30)
	dungeon_popup_menu.theme = popup_theme
	
	dungeon_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	dungeon_popup_menu.add_item("Wall")
	dungeon_popup_menu.add_item("Corner IN")
	dungeon_popup_menu.add_item("Floor")
	dungeon_popup_menu.add_item("Corner OUT")
	dungeon_popup_menu.add_item("GridMap Generator")
	dungeon_popup_menu.connect("id_pressed", _on_dungeon_model_selected)
		
func _on_dungeon_model_selected(id):
	print("Dungeon Model ID: ", id)
	dungeon_menu_button.get_popup().popup()  # Show the popup again
	match id:
		0:
			instantiate_dungeon_wall()
		1:
			instantiate_dungeon_corner_in()
		2:
			instantiate_dungeon_floor()
		3:
			instantiate_dungeon_corner_out()
		4:
			instantiate_dungeon_gridmap()
		_:
			print("Unknown model selected")

#DISABLED FOR NOW, WORKING ON NEW FUNCTIONALITY	
#func dungeon_layout_button_pressed():
#	var dungeon_layout = DungeonTemplate.instantiate()
#	var current_scene = get_editor_interface().get_edited_scene_root()
#
#	if current_scene:
#		dungeon_layout.name = "Dungeon_" + str(current_scene.get_child_count())
#
#		# For undo/redo functionality:
#		undo_redo.create_action("Create Hideout")
#		undo_redo.add_do_method(current_scene, "add_child", dungeon_layout)
#		undo_redo.add_do_reference(dungeon_layout)
#		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_layout)
#		undo_redo.commit_action(true)
#		dungeon_layout.owner = current_scene
#	else:
#		print("No active scene!")

func _exit_tree():
	# Clean up when the plugin is disabled
	remove_control_from_docks(dockedScene)
	dockedScene.free()

func get_plugin_name():
	return "RoomGenerator"

func get_plugin_description():
	return "An editor for creating 3D rooms, tunnels, gridmaps and more."
	
func create_wall():
	print("Inside create wall")

	# Create a new MeshInstance node
	var wall = MeshInstance3D.new()

	# Create a CubeMesh for our wall
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(4, 2, 0.2) # adjust size as per your requirements
	wall.mesh = cube_mesh

	var current_scene = get_editor_interface().get_edited_scene_root()
	if current_scene:
				# Name the box instance with counting already existing boxes
		wall.name = "Wall_" + str(current_scene.get_child_count())
		# Begin a new action called "Create Box"
		undo_redo.create_action("Create Wall")
		
		# For the "do" operation: Add the box to the scene
		undo_redo.add_do_method(current_scene, "add_child", wall)
		undo_redo.add_do_reference(wall)  # Ensure box is kept in memory
		
		# For the "undo" operation: Remove the box from the scene
		undo_redo.add_undo_method(current_scene, "remove_child", wall)
		undo_redo.add_undo_reference(wall)  # Ensure box is kept in memory
		
		# Commit the action with execution
		undo_redo.commit_action(true)
		wall.owner = current_scene
	else:
		print("No active scene!")
				
func create_box():
	print("Inside create box")

	# Create a new MeshInstance node
	var box = MeshInstance3D.new()

	# Create a CubeMesh for our box
	var cube_mesh = BoxMesh.new()
	box.mesh = cube_mesh

	var current_scene = get_editor_interface().get_edited_scene_root()
	if current_scene:
		# Name the box instance with counting already existing boxes
		box.name = "Box_" + str(current_scene.get_child_count())
		# Begin a new action called "Create Box"
		undo_redo.create_action("Create Box")
		
		# For the "do" operation: Add the box to the scene
		undo_redo.add_do_method(current_scene, "add_child", box)
		undo_redo.add_do_reference(box)  # Ensure box is kept in memory
		
		# For the "undo" operation: Remove the box from the scene
		undo_redo.add_undo_method(current_scene, "remove_child", box)
		undo_redo.add_undo_reference(box)  # Ensure box is kept in memory
		
		# Commit the action with execution
		undo_redo.commit_action(true)
		box.owner = current_scene
	else:
		print("No active scene!")	
	
func create_room():
	var room = RoomTemplate.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		room.name = "Room_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Room")
		undo_redo.add_do_method(current_scene, "add_child", room)
		undo_redo.add_do_reference(room)
		undo_redo.add_undo_method(current_scene, "remove_child", room)
		undo_redo.commit_action(true)
		room.owner = current_scene
	else:
		print("No active scene!")
	
#TURNED OFF FOR NOW TO NOT LOAD ASSETS		
#func create_hideout():
#	var hideout = HideoutTemplate.instantiate()
#	var current_scene = get_editor_interface().get_edited_scene_root()
#
#	if current_scene:
#		hideout.name = "Hideout_" + str(current_scene.get_child_count())
#
#		# For undo/redo functionality:
#		undo_redo.create_action("Create Hideout")
#		undo_redo.add_do_method(current_scene, "add_child", hideout)
#		undo_redo.add_do_reference(hideout)
#		undo_redo.add_undo_method(current_scene, "remove_child", hideout)
#		undo_redo.commit_action(true)
#		hideout.owner = current_scene
#	else:
#		print("No active scene!")

func instantiate_dungeon_wall():
	var _dungeon_wall = dungeon_wall.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_wall.name = "dungeon_wall_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_wall)
		undo_redo.add_do_reference(_dungeon_wall)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_wall)
		undo_redo.commit_action(true)
		_dungeon_wall.owner = current_scene
	else:
		print("No active scene!")
		
func instantiate_dungeon_corner_in():
	var _dungeon_corner_in = dungeon_corner_in.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_corner_in.name = "dungeon_corner_in_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_corner_in)
		undo_redo.add_do_reference(_dungeon_corner_in)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_corner_in)
		undo_redo.commit_action(true)
		_dungeon_corner_in.owner = current_scene
	else:
		print("No active scene!")

func instantiate_dungeon_floor():
	var _dungeon_floor = dungeon_floor.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_floor.name = "dungeon_floor_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_floor)
		undo_redo.add_do_reference(_dungeon_floor)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_floor)
		undo_redo.commit_action(true)
		_dungeon_floor.owner = current_scene
	else:
		print("No active scene!")	
		
func instantiate_dungeon_corner_out():
	var _dungeon_corner_out = dungeon_corner_out.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()

	if current_scene:
		_dungeon_corner_out.name = "dungeon_corner_out_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Wall")
		undo_redo.add_do_method(current_scene, "add_child", _dungeon_corner_out)
		undo_redo.add_do_reference(_dungeon_corner_out)
		undo_redo.add_undo_method(current_scene, "remove_child", _dungeon_corner_out)
		undo_redo.commit_action(true)
		_dungeon_corner_out.owner = current_scene
	else:
		print("No active scene!")	
		
func instantiate_dungeon_gridmap():
	var dungeon_menu_inst = dungeon_menu.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()
	
	dungeon_menu_inst.connect("dungeon_generated", plugin_connection)#

	if current_scene:
		dungeon_menu_inst.name = "dungeon_grid_" + str(current_scene.get_child_count())
		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Gridmap")
		undo_redo.add_do_method(current_scene, "add_child", dungeon_menu_inst)
		undo_redo.add_do_reference(dungeon_menu_inst)
		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_menu_inst)
		undo_redo.commit_action(true)
		dungeon_menu_inst.owner = current_scene
	else:
		print("No active scene!")	

func plugin_connection(gridmap):
	print("Plugin connected to the dungeon menu")
	stored_gridmaps.append(gridmap)
	
	print("My gridmaps: ", stored_gridmaps.size())
