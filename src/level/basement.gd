extends Level

var light_switch:bool = false

func _ready() -> void:
	super._ready()
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.x88_to_vector3(cheshire_by)
	$chessboard.state.add_piece(cheshire_by, player_king)
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	chessboard.button_input_pointer = cheshire_by
	get_tree().call_group("lights", "set_visible", light_switch)

func change_light() -> void:
	$reflection_probe.position = $reflection_probe.position + (Vector3(0, 0.0001, 0) if light_switch else Vector3(0, -0.0001, 0))
	light_switch = !light_switch
	get_tree().call_group("lights", "set_visible", light_switch)
	show_selection.call_deferred()
