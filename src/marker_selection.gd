@abstract
extends Node3D
class_name MarkerSelection

@onready var level:Level = get_parent()
@export var selection:String = ""
@export var bit:int = 0

@abstract func event() -> void
