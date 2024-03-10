@tool
extends EditorPlugin

#const dungeon_menu_script = preload("res://addons/room-generator/dungeon/DungeonMenu.gd")
const panel = preload("res://addons/room-generator/panel.tscn")
const RoomTemplate = preload("res://addons/room-generator/room_template/room_template.tscn")
#dungeon textures
const dungeon_corner_in = preload("res://addons/room-generator/dungeon_tiles/dungeon_corner_in.tscn")
const dungeon_corner_out = preload("res://addons/room-generator/dungeon_tiles/dungeon_corner_out.tscn")
const dungeon_floor = preload("res://addons/room-generator/dungeon_tiles/dungeon_floor.tscn")
const dungeon_wall = preload("res://addons/room-generator/dungeon_tiles/dungeon_wall.tscn")
#wooden cabin textures
const WOODEN_CABIN_CEILING = preload("res://addons/room-generator/texture_tiles/wooden_cabin_ceiling.tscn")
const WOODEN_CABIN_DOOR = preload("res://addons/room-generator/texture_tiles/wooden_cabin_door.tscn")
const WOODEN_CABIN_FLOOR = preload("res://addons/room-generator/texture_tiles/wooden_cabin_floor.tscn")
const WOODEN_CABIN_WALL = preload("res://addons/room-generator/texture_tiles/wooden_cabin_wall.tscn")
#frozen caves textures
const FROZEN_CAVES_CEILING = preload("res://addons/room-generator/texture_tiles/frozen_caves_ceiling.tscn")
const FROZEN_CAVES_DOOR = preload("res://addons/room-generator/texture_tiles/frozen_caves_door.tscn")
const FROZEN_CAVES_FLOOR = preload("res://addons/room-generator/texture_tiles/frozen_caves_floor.tscn")
const FROZEN_CAVES_WALL = preload("res://addons/room-generator/texture_tiles/frozen_caves_wall.tscn")
#player controllers
const THIRD_PERSON_PLAYER = preload("res://addons/room-generator/player/third_person_player.tscn")
#images
const DUNGEON_BACKGROUND = preload("res://addons/room-generator/icons/dungeon_background.png")
const WOODEN_CABIN_BACKGROUND = preload("res://addons/room-generator/icons/wooden_cabin_background.png")
const FROZEN_CAVES_BACKGROUND = preload("res://addons/room-generator/icons/frozen_caves_background.png")
#this is the dungeon generator
const dungeon_menu = preload("res://addons/room-generator/dungeon/dungeon_menu.tscn")
const GODOT_ICON = preload("res://addons/room-generator/icons/godot_icon.svg")
const DUNGEON_GENERATOR_ICON = preload("res://addons/room-generator/icons/dungeon_generator_icon.png")

var dockedScene
#var toggle_button: Button
var tab_container: TabContainer
var is_content_visible: bool = false  # Tracks whether the content is currently visible

#var stored_gridmaps: Array[GridMap] = []
#var stored_meshes: Array[Node3D] = []
var stored_layouts = []

var wall_button: Button
var first_person_controller: Button
var isometric_controller: Button
var use_layout_button: Button
var delete_layout_button: Button
var dungeon_menu_button: MenuButton
var dungeon_layout_button: Button
var dungeon_popup_menu
var wooden_cabins_popup_menu
var wooden_cabin_menu_button
var frozen_caves_menu_button
var frozen_caves_popup_menu

var item_list : ItemList
var item_list_counter = 0

var confirmation_dialog: ConfirmationDialog

# Get the undo/redo object
var undo_redo = get_undo_redo()

func _enter_tree():
	dockedScene = panel.instantiate()
	print("RoomGenerator panel scene instantiated!")
	
	tab_container = dockedScene.get_node("TabContainer")
	tab_container.visible = true
	
	setup_button_connections()
	setup_dungeon_menu_button()
	confirmation_dialog_setup()
	setup_preview()
		
	# Initial setup when the plugin is enabled
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dockedScene)

func setup_button_connections():
	# Connect the toggle button signal
	first_person_controller = dockedScene.get_node("TabContainer/Player Controller/First Person Player Controller")
	isometric_controller = dockedScene.get_node("TabContainer/Player Controller/Isometric Player Controller")
	use_layout_button = dockedScene.get_node("TabContainer/Layouts/UseLayoutButton")
	delete_layout_button = dockedScene.get_node("TabContainer/Layouts/DeleteLayoutButton")
	dungeon_menu_button = dockedScene.get_node("TabContainer/Models/DungeonGeneratorMenu")
	wooden_cabin_menu_button = dockedScene.get_node("TabContainer/Models/DungeonGeneratorMenu")
	wooden_cabin_menu_button = dockedScene.get_node("TabContainer/Models/WoodenCabinGeneratorMenu")	
	frozen_caves_menu_button = dockedScene.get_node("TabContainer/Models/FrozenCaveGeneratorMenu")	

	first_person_controller.connect("pressed", create_first_person_controller)
	isometric_controller.connect("pressed", create_isometric_controller)
	wooden_cabin_menu_button.connect("pressed", wooden_cabin_menu_button_pressed)
	frozen_caves_menu_button.connect("pressed", frozen_caves_menu_button_pressed)
	use_layout_button.connect("pressed", use_layout_button_pressed)
	delete_layout_button.connect("pressed", delete_layout_button_pressed)
	
func use_layout_button_pressed():
	print("Use Layout Button Pressed: ")
	print("Item selected: ", item_list.get_selected_items())
	var selected_items = item_list.get_selected_items()
	
	if selected_items.size() == 0:
		print("No item selected")
		return
	
	var selected_index = selected_items[0]
	print("Item selected: ", selected_index)
	
	if selected_index >= 0 and selected_index < stored_layouts.size():
		confirmation_dialog.popup_centered()  # Show the dialog to let the user decide
	else:
		print("Selected index out of bounds")
	
	#for i in range(item_list.item_count):  # Iterate backwards
		#print("Gridmap ", item_list.get_selected_items(), " spawned")
		#gridmap_from_layouts = stored_gridmaps[i]
	#
	#for i in stored_gridmaps:
		#print(i)
	#
	#instantiate_gridmap_from_layouts(gridmap_from_layouts)
	##item_list.get_item_at_position(item_list.get_selected_items())
	
func instantiate_gridmap_from_layouts(gridmap):
	var current_scene = get_editor_interface().get_edited_scene_root()
	var gridmap_from_layouts = gridmap.duplicate(true)
	
	if current_scene:
		gridmap_from_layouts.name = "GridMap_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Adding gridmap from layouts")
		undo_redo.add_do_method(current_scene, "add_child", gridmap_from_layouts)
		undo_redo.add_do_reference(gridmap_from_layouts)
		undo_redo.add_undo_method(current_scene, "remove_child", gridmap_from_layouts)
		undo_redo.commit_action(true)
		gridmap_from_layouts.owner = current_scene
	else:
		print("No active scene!")
		
func instantiate_mesh_from_layouts(mesh):
	var current_scene = get_editor_interface().get_edited_scene_root()
	var mesh_from_layouts = mesh.duplicate(true)
	
	if current_scene:
		mesh_from_layouts.name = "GridMap_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Adding gridmap from layouts")
		undo_redo.add_do_method(current_scene, "add_child", mesh_from_layouts)
		undo_redo.add_do_reference(mesh_from_layouts)
		undo_redo.add_undo_method(current_scene, "remove_child", mesh_from_layouts)
		undo_redo.commit_action(true)
		mesh_from_layouts.owner = current_scene
	else:
		print("No active scene!")
	
	
func delete_layout_button_pressed():
	print("Delete Layout Button Pressed: ")
	
	var selected_items = item_list.get_selected_items()
	for i in range(selected_items.size() - 1, -1, -1):  # Iterate backwards
		print("Item ", item_list.get_selected_items(), " deleted")
		item_list.remove_item(selected_items[i])
		stored_layouts.remove_at(selected_items[i])

func wooden_cabin_menu_button_pressed():
	if wooden_cabins_popup_menu:
		wooden_cabins_popup_menu.clear()
		if wooden_cabins_popup_menu.is_connected("id_pressed", instantiate_wooden_cabin_texture):
			wooden_cabins_popup_menu.disconnect("id_pressed", instantiate_wooden_cabin_texture)
			
	wooden_cabins_popup_menu = wooden_cabin_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	
	var style_box = StyleBoxTexture.new()
	var bg_image = WOODEN_CABIN_BACKGROUND
	style_box.texture = bg_image

	var popup_font = FontFile.new()
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file
	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.663, 0.91, 0))  
	popup_theme.set_font_size("font_size", "PopupMenu", 30)

	wooden_cabins_popup_menu.theme = popup_theme
	wooden_cabins_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	wooden_cabins_popup_menu.add_item("Wall")
	wooden_cabins_popup_menu.add_item("Entrance")
	wooden_cabins_popup_menu.add_item("Ceiling")
	wooden_cabins_popup_menu.add_item("Floor")
	wooden_cabins_popup_menu.add_item("GridMap Generator")
	wooden_cabins_popup_menu.connect("id_pressed", instantiate_wooden_cabin_texture)
	
func instantiate_frozen_caves_texture(id):
	var current_scene = get_editor_interface().get_edited_scene_root()
	var frozen_caves_texture
	
	match id:
		0:
			frozen_caves_texture = FROZEN_CAVES_WALL.instantiate()
		1:
			frozen_caves_texture = FROZEN_CAVES_DOOR.instantiate()
		2:
			frozen_caves_texture = FROZEN_CAVES_CEILING.instantiate()
		3:
			frozen_caves_texture = FROZEN_CAVES_FLOOR.instantiate()
		4:
			instantiate_dungeon_gridmap()
			return
		_:
			print("Unknown model selected")
		
	if current_scene:
		frozen_caves_texture.name = "frozen_caves_texture_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Frozen Texture")
		undo_redo.add_do_method(current_scene, "add_child", frozen_caves_texture)
		undo_redo.add_do_reference(frozen_caves_texture)
		undo_redo.add_undo_method(current_scene, "remove_child", frozen_caves_texture)
		undo_redo.commit_action(true)
		frozen_caves_texture.owner = current_scene
	else:
		print("No active scene!")	

func instantiate_wooden_cabin_texture(id):
	var current_scene = get_editor_interface().get_edited_scene_root()
	var wooden_cabin_texture
	
	match id:
		0:
			wooden_cabin_texture = WOODEN_CABIN_WALL.instantiate()
		1:
			wooden_cabin_texture = WOODEN_CABIN_DOOR.instantiate()
		2:
			wooden_cabin_texture = WOODEN_CABIN_CEILING.instantiate()
		3:
			wooden_cabin_texture = WOODEN_CABIN_FLOOR.instantiate()
		4:
			instantiate_dungeon_gridmap()
			return
		_:
			print("Unknown model selected")

	if current_scene:
		wooden_cabin_texture.name = "wooden_cabin_texture_" + str(current_scene.get_child_count())

		# For undo/redo functionality:
		undo_redo.create_action("Create Wooden Cabin Texture")
		undo_redo.add_do_method(current_scene, "add_child", wooden_cabin_texture)
		undo_redo.add_do_reference(wooden_cabin_texture)
		undo_redo.add_undo_method(current_scene, "remove_child", wooden_cabin_texture)
		undo_redo.commit_action(true)
		wooden_cabin_texture.owner = current_scene
	else:
		print("No active scene!")	

func frozen_caves_menu_button_pressed():
	if frozen_caves_popup_menu:
		frozen_caves_popup_menu.clear()
		if frozen_caves_popup_menu.is_connected("id_pressed", instantiate_frozen_caves_texture):
			frozen_caves_popup_menu.disconnect("id_pressed", instantiate_frozen_caves_texture)
			
	frozen_caves_popup_menu = frozen_caves_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	
	var style_box = StyleBoxTexture.new()
	var bg_image = FROZEN_CAVES_BACKGROUND
	style_box.texture = bg_image

	var popup_font = FontFile.new()
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file
	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.902, 0.686, 1))  
	popup_theme.set_font_size("font_size", "PopupMenu", 30)

	frozen_caves_popup_menu.theme = popup_theme
	frozen_caves_popup_menu.add_theme_stylebox_override("panel", style_box)
	
	frozen_caves_popup_menu.add_item("Wall")
	frozen_caves_popup_menu.add_item("Tunnel")
	frozen_caves_popup_menu.add_item("Roof")
	frozen_caves_popup_menu.add_item("Floor")
	frozen_caves_popup_menu.add_item("GridMap Generator")
	frozen_caves_popup_menu.connect("id_pressed", instantiate_frozen_caves_texture)

func setup_dungeon_menu_button():
	dungeon_popup_menu = dungeon_menu_button.get_popup()
	var popup_theme = Theme.new()  # Create a new theme
	var style_box = StyleBoxTexture.new()
	var bg_image = DUNGEON_BACKGROUND
	style_box.texture = bg_image

	var popup_font = FontFile.new()
	#"theme_override_constants/outline_size"
	popup_font.font_data = load("res://addons/room-generator/fonts/Diablo Heavy.ttf")  # Replace with the path to your font file

	popup_theme.set_font("font", "PopupMenu", popup_font)
	popup_theme.set_color("font_color", "PopupMenu", Color(0.922, 0.675, 0.514))  # Set to black
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

func _exit_tree():
	# Clean up when the plugin is disabled
	remove_control_from_docks(dockedScene)
	dockedScene.free()

func get_plugin_name():
	return "RoomGenerator"

func get_plugin_description():
	return "An editor for creating 3D rooms, tunnels, gridmaps and more."
	
func create_isometric_controller():
	print("Isometric player controller functionality to be added here")

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
	
	dungeon_menu_inst.connect("dungeon_generated", plugin_connection)
	dungeon_menu_inst.connect("save_to_layouts_signal", save_to_layouts_function)

	if current_scene:
		dungeon_menu_inst.name = "Dungeon Generator " + str(current_scene.get_child_count())
		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Gridmap")
		undo_redo.add_do_method(current_scene, "add_child", dungeon_menu_inst)
		undo_redo.add_do_reference(dungeon_menu_inst)
		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_menu_inst)
		undo_redo.commit_action(true)
		dungeon_menu_inst.owner = current_scene
		for n in dungeon_menu_inst.get_children():
			n.owner = current_scene
	else:
		print("No active scene!")	
		
		
func instantiate_frozen_caves_gridmap():
	var dungeon_menu_inst = dungeon_menu.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()
	
	dungeon_menu_inst.connect("dungeon_generated", plugin_connection)
	dungeon_menu_inst.connect("save_to_layouts_signal", save_to_layouts_function)

	if current_scene:
		dungeon_menu_inst.name = "Dungeon Generator " + str(current_scene.get_child_count())
		# For undo/redo functionality:
		undo_redo.create_action("Create Dungeon Gridmap")
		undo_redo.add_do_method(current_scene, "add_child", dungeon_menu_inst)
		undo_redo.add_do_reference(dungeon_menu_inst)
		undo_redo.add_undo_method(current_scene, "remove_child", dungeon_menu_inst)
		undo_redo.commit_action(true)
		dungeon_menu_inst.owner = current_scene
		for n in dungeon_menu_inst.get_children():
			n.owner = current_scene
	else:
		print("No active scene!")			
		
		
		
		
		
		
		

func create_first_person_controller():
	print("Inside first person controller creator")
	var third_person_controller = THIRD_PERSON_PLAYER.instantiate()
	var current_scene = get_editor_interface().get_edited_scene_root()
	
	if current_scene:
		third_person_controller.name = "Player_" + str(current_scene.get_child_count())
		third_person_controller.scale = Vector3(0.6, 0.6, 0.6)
		third_person_controller.position = Vector3(4.206, 0.63, 6.766)

		undo_redo.create_action("Create First Person Player")
		undo_redo.add_do_method(current_scene, "add_child", third_person_controller)
		undo_redo.add_do_reference(third_person_controller)  # Ensure box is kept in memory
		undo_redo.add_undo_method(current_scene, "remove_child", third_person_controller)
		undo_redo.add_undo_reference(third_person_controller)  # Ensure box is kept in memory
		undo_redo.commit_action(true)
		
		third_person_controller.owner = current_scene
	else:
		print("No active scene!")	

func plugin_connection(gridmap):
	print("Plugin connected to the dungeon menu")
	
#func save_to_layouts_function(gridmap, mesh):
	#if !item_list:
		#item_list = dockedScene.get_node("TabContainer/Layouts/ItemList")
		#
	#stored_gridmaps.append(gridmap)
	#stored_meshes.append(mesh)
	#
	#item_list.add_item("Generated Layout " + str(item_list_counter), DUNGEON_GENERATOR_ICON, true)
	#item_list_counter+=1
	
func save_to_layouts_function(gridmap, mesh):
	if !item_list:
		item_list = dockedScene.get_node("TabContainer/Layouts/ItemList")
	
	# Create a dictionary for the current dungeon layout and its mesh, then append it
	var dungeon_dict = {
		"gridmap": gridmap,
		"mesh": mesh}
	stored_layouts.append(dungeon_dict)
	
	# Add an item to the ItemList for this dungeon layout
	item_list.add_item("Generated Layout " + str(item_list.get_item_count() + 1), DUNGEON_GENERATOR_ICON, true)
	print("Layouts: ", stored_layouts)
	
	#check what I have in the dictionary
	for layout_dict in stored_layouts:
		print("Layout Key: ", layout_dict)
		for key in layout_dict:
			print("   ", key, ": ", layout_dict[key])
			
			
func confirmation_dialog_setup():
	# Create the ConfirmationDialog dynamically
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Do you want to spawn the Gridmap, Mesh, or Both?"
	add_child(confirmation_dialog)

	# Add buttons for choices
	confirmation_dialog.add_button("Gridmap", true, "gridmap")
	confirmation_dialog.add_button("Mesh", true, "mesh")
	confirmation_dialog.add_button("Both", true, "both")

	# Connect signals for the buttons
	confirmation_dialog.connect("custom_action", _on_confirmation_dialog_custom_action)
	
func _on_confirmation_dialog_custom_action(action: String):
	var selected_index = item_list.get_selected_items()[0]
	var layout_dict = stored_layouts[selected_index]  # Extract the selected layout
	var spawning_gridmap = layout_dict["gridmap"]
	var spawning_mesh = layout_dict["mesh"]

	match action:
		"gridmap":
			instantiate_gridmap_from_layouts(spawning_gridmap)
		"mesh":
			instantiate_mesh_from_layouts(spawning_mesh)
		"both":
			instantiate_gridmap_from_layouts(spawning_gridmap)
			instantiate_mesh_from_layouts(spawning_mesh)


func setup_preview():
	var viewport = dockedScene.get_node("TabContainer/Preview/SubViewportContainer/SubViewport")
	viewport.size = Vector2(410, 370)  # Set the size of the viewport
	
	#var character = THIRD_PERSON_PLAYER.instantiate()
	#viewport.add_child(character)
	#viewport.size = Vector2(500, 400)  # Set the size of the viewport
	#
	#var camera = character.get_node("Head/Camera3D")
	#viewport.Camera3D
