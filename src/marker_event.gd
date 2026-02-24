@abstract
extends Node3D
class_name MarkerEvent

@onready var level:Level = get_parent()
@export var bit:int = 0

@abstract func event() -> void
