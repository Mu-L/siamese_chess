extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/405135__mjeno__autumn-forest-leaves-falling-close-to-pond-iii-loopable.wav"))
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.x88_to_vector3(cheshire_by)
	$chessboard.state.add_piece(cheshire_by, player_king)
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	chessboard.button_input_pointer = cheshire_by
	$player.force_set_camera($camera)

func interact_carnation() -> void:
	Dialog.push_dialog("CARNATION_TALK_0_0", "", true, true)
	$player.force_set_camera($camera_carnation_dialog)
	await Dialog.on_next
	Dialog.push_dialog("CARNATION_TALK_0_1", "", false, true)
	await Dialog.on_next
	$player.force_set_camera($camera)
