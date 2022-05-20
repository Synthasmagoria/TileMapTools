tool
extends EditorPlugin

var tools

func _enter_tree() -> void:
	tools = preload("tools.gd").new(get_editor_interface().get_selection())
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, tools)


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, tools)
	tools.free()
