extends Control

func _ready() -> void:
	Progress.load_file()
	var current_level:String = Progress.get_value("current_level", "res://scene/level/entrance.tscn")
	var current_level_meta:Dictionary = Progress.get_value("current_level", {})
	if current_level == "res://scene/startup.tscn":
		current_level = "res://scene/level/entrance.tscn"
	Loading.change_scene(current_level, current_level_meta)
