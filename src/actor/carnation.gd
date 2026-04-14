extends Actor

func _ready() -> void:
	$animation_tree.get("parameters/playback").start("sit_and_play")

func set_direction(_rotation:float) -> Actor:
	global_rotation.y = _rotation
	return self
