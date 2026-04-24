extends Node3D
class_name Level

var player_group:int = 1
var player_all:int = 0
var player_king:int = 0
var enemy_all:int = 0
var enemy_king:int = 0

var engine:ChessEngine = null	# 有可能会出现多线作战，共用同一个引擎显然不好
@export var engine_standard_think_time = 2
@export var engine_standard_think_depth = 20
@export var engine_relax_think_time = INF
@export var engine_relax_think_depth = 2
var chessboard:Chessboard = null
var in_battle:bool = false
var teleport:Dictionary = {}
var history_state:PackedInt64Array = []
@onready var history_document:Document = load("res://scene/doc/history.tscn").instantiate()
var interact_list:Dictionary[int, Dictionary] = {}
var title:Dictionary[int, String] = {}
var state_machine:StateMachine = null
var premove_state_machine:StateMachine = null

func _ready() -> void:
	player_all = ord("A") if player_group == 0 else ord("a")
	player_king = ord("K") if player_group == 0 else ord("k")
	enemy_all = ord("a") if player_group == 0 else ord("A")
	enemy_king = ord("k") if player_group == 0 else ord("K")
	engine = PastorEngine.new()
	state_machine = StateMachine.new()
	premove_state_machine = StateMachine.new()
	
	history_document.set_filename("history." + name + ".json")
	history_document.load_file()

	var state = State.new()
	chessboard = $chessboard
	$player.add_inspectable_item(chessboard)
	for node:Node in get_children():
		if node is MarkerActor:
			var by:int = chessboard.vector3_to_x88(node.position)
			state.add_piece(by, node.piece)
		if node is MarkerMultiActor:
			var bit:int = node.bit
			while bit:
				var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
				state.add_piece(by, node.piece)
				bit = Chess.next_bit(bit)
		if node is MarkerBit:
			state.set_bit(node.piece, state.get_bit(node.piece) | node.bit)
		if node is MarkerEvent:
			state.set_bit(ord("Z"), state.get_bit(ord("Z")) | node.bit)
			var bit:int = node.bit
			while bit:
				var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
				if !interact_list.has(by):
					interact_list[by] = {}
				interact_list[by][""] = node.event
				bit = Chess.next_bit(bit)
		if node is MarkerSelection:
			state.set_bit(ord("z"), state.get_bit(ord("z")) | node.bit)
			var bit:int = node.bit
			while bit:
				var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
				if !interact_list.has(by):
					interact_list[by] = {}
				interact_list[by][node.selection] = node.event
				bit = Chess.next_bit(bit)
		if node is MarkerTitle:
			var by:int = chessboard.vector3_to_x88(node.position)
			title[by] = node.text

	chessboard.set_state(state)
	for node:Node in get_children():
		if node is MarkerActor:
			var by:int = chessboard.vector3_to_x88(node.position)
			var instance:Actor = node.instantiate()
			instance.transform = node.transform
			if is_instance_valid(instance):
				chessboard.add_piece_instance(instance, by)
	Progress.create_if_not_exist("obtains", 0)
	Progress.create_if_not_exist("wins", 0)
	state_machine.add_state("start", state_ready_start)
	state_machine.add_state("enemy", state_ready_enemy)
	state_machine.add_state("waiting", state_ready_waiting)
	state_machine.add_state("move", state_ready_move)
	state_machine.add_state("player", state_ready_player, state_exit_player)
	state_machine.add_state("ready_to_move", state_ready_ready_to_move, state_exit_ready_to_move)
	state_machine.add_state("travel", state_ready_travel, state_exit_travel)
	state_machine.add_state("check_move", state_ready_check_move)
	state_machine.add_state("extra_move", state_ready_extra_move)
	state_machine.add_state("player_win", state_ready_player_win)
	state_machine.add_state("enemy_win", state_ready_enemy_win)
	state_machine.add_state("draw", state_ready_draw)
	state_machine.add_state("interact", state_ready_interact)
	state_machine.name = "level"
	premove_state_machine.add_state("start", state_premove_start_ready)
	premove_state_machine.add_state("from", state_premove_from_ready, state_premove_from_exit)
	premove_state_machine.add_state("to", state_premove_to_ready)
	premove_state_machine.add_state("travel", state_premove_travel_ready)
	premove_state_machine.add_state("extra", state_premove_extra_ready, state_premove_extra_exit)
	premove_state_machine.add_state("confirm", state_premove_confirm_ready)
	premove_state_machine.add_state("stop", state_premove_stop_ready)
	premove_state_machine.name = "premove"
	state_machine.change_state.call_deferred("start")

class PremoveBranch extends RefCounted:
	var move_order:PackedInt32Array = []
	var future_state:State = null

var premove_branch:PremoveBranch = PremoveBranch.new()
var premove_from:int = -1
var premove_to:int = -1

func state_premove_start_ready(_arg:Dictionary) -> void:
	if !premove_branch:
		premove_branch = PremoveBranch.new()
	if !premove_branch.move_order.size():
		premove_branch.future_state = chessboard.state.duplicate()
	premove_state_machine.change_state.call_deferred("from")

func state_premove_from_ready(_arg:Dictionary) -> void:
	premove_from = -1
	premove_to = -1
	var start_from:int = 0
	var move_list:PackedInt32Array = Chess.generate_premove(premove_branch.future_state, player_group)
	for iter:int in move_list:
		start_from |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))

	premove_state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		premove_from = _selected
		premove_state_machine.change_state.call_deferred("to", {"from": _selected})
	)
	premove_state_machine.state_signal_connect(Dialog.on_select, func(_selected:String) -> void:
		premove_branch.future_state = chessboard.state.duplicate()
		premove_branch.move_order = []
	)
	if premove_branch.move_order.size():
		Dialog.push_selection(["SELECTION_CANCEL"], "", false, false)
	chessboard.set_square_selection(start_from)

func state_premove_from_exit() -> void:
	Dialog.clear()

func state_premove_to_ready(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_premove(premove_branch.future_state, player_group)
	var selection:int = 0
	for iter:int in move_list:
		if Chess.from(iter) == _arg["from"]:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	premove_state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		premove_to = _selected
		var cnt:int = 0
		for iter:int in move_list:
			if Chess.from(iter) == _arg["from"] && Chess.to(iter) == _selected:
				cnt += 1
		if cnt == 1:
			premove_state_machine.change_state.call_deferred("confirm", {"move": Chess.create(_arg["from"], _selected, 0)})
		elif cnt > 1:
			premove_state_machine.change_state.call_deferred("extra", {"from": _arg["from"], "to": _selected})
	)
	premove_state_machine.state_signal_connect(chessboard.selection_hold, func (_selected:int) -> void:
		premove_state_machine.change_state.call_deferred("travel", {"from": _selected})
	)
	premove_state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		premove_state_machine.change_state.call_deferred("from")
	)
	chessboard.set_square_selection(selection)

func state_premove_travel_ready(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var path:PackedInt32Array = Chess.generate_path(premove_branch.future_state, from)
	var bit:int = 0
	for i:int in path.size():
		if path[i] != -1:
			bit |= Chess.mask(i)
	premove_state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		premove_state_machine.change_state("from")
	)
	premove_state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		var to:int = _selected
		var iter:int = to
		var path_to:PackedInt32Array = []
		while (iter != from):
			path_to.push_back(Chess.create(path[Chess.x88_to_c64(iter)], iter, 0))
			iter = path[Chess.x88_to_c64(iter)]
			chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), iter)
			if iter == -1:
				premove_state_machine.change_state.call_deferred("from")
				chessboard.clear_pointer("premove")
				return
		path_to.reverse()
		premove_branch.move_order.append_array(path_to)
		for move:int in path_to:
			Chess.apply_move(premove_branch.future_state, move)
		premove_state_machine.change_state.call_deferred("from")
	)
	premove_state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		premove_state_machine.change_state.call_deferred("from")
	)

	Dialog.push_selection(["SELECTION_CANCEL"], "", false, false)
	chessboard.set_square_selection(bit)

func state_premove_extra_ready(_arg:Dictionary) -> void:
	var map:Dictionary = {
		ord("Q"): "PIECE_QUEEN",
		ord("R"): "PIECE_ROOK",
		ord("B"): "PIECE_BISHOP",
		ord("N"): "PIECE_KNIGHT",
		ord("q"): "PIECE_QUEEN",
		ord("r"): "PIECE_ROOK",
		ord("b"): "PIECE_BISHOP",
		ord("n"): "PIECE_KNIGHT",
	}
	var move_list:PackedInt32Array = Chess.generate_premove(premove_branch.future_state, player_group)
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in move_list:
		if Chess.from(iter) == _arg["from"] && Chess.to(iter) == _arg["to"]:
			decision_list.push_back(map[Chess.extra(iter)])
			decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("SELECTION_CANCEL")
	premove_state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		if _selected == "SELECTION_CANCEL":
			premove_state_machine.change_state.call_deferred("from")
		else:
			premove_state_machine.change_state.call_deferred("confirm", {"move": decision_to_move[_selected]})
	)
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, false)

func state_premove_extra_exit() -> void:
	Dialog.clear()

func state_premove_confirm_ready(_arg:Dictionary) -> void:
	premove_from = -1
	premove_to = -1
	premove_branch.move_order.push_back(_arg["move"])
	Chess.apply_move(premove_branch.future_state, _arg["move"])
	chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), Chess.from(_arg["move"]))
	chessboard.draw_pointer("premove", Color(0.639, 0.051, 0.196, 1.0), Chess.to(_arg["move"]))
	premove_state_machine.change_state.call_deferred("from")

func state_premove_stop_ready(_arg:Dictionary) -> void:
	pass

func state_ready_start(_arg:Dictionary) -> void:
	Clock.set_time(Progress.get_value("time_left", 60 * 15), 5)
	chessboard.state.set_turn(0)
	chessboard.state.set_castle(0xF)
	chessboard.state.set_step_to_draw(0)
	chessboard.state.set_round(1)
	history_document.new_page()
	history_document.set_state(chessboard.state)
	if Chess.get_end_type(chessboard.state) == "checkmate_black":
		state_machine.change_state.call_deferred("player_win")
	elif Chess.get_end_type(chessboard.state) == "checkmate_white":
		state_machine.change_state.call_deferred("enemy_win")
	elif chessboard.state.get_bit(ord("Z")) & chessboard.state.get_bit(player_king):
		state_machine.change_state.call_deferred("interact", {"callback": interact_list[Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))][""]})
	else:
		back_to_game()

func state_ready_enemy(_arg:Dictionary) -> void:
	if !chessboard.state.get_bit(enemy_all):
		state_machine.change_state.call_deferred("move", {"move": -1})
		return
	state_machine.state_signal_connect(engine.search_finished, func() -> void:
		assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(engine.get_search_result()))))
		state_machine.change_state.call_deferred("move", {"move": engine.get_search_result()})
	)
	if !Setting.get_value("relax"):
		engine.set_max_depth(engine_standard_think_depth)
		engine.set_think_time(engine_standard_think_time)
		engine.set_quies(false)
	else:
		engine.set_max_depth(engine_relax_think_depth)
		engine.set_think_time(engine_relax_think_time)
		engine.set_quies(true)
	engine.start_search(chessboard.state, 1 - player_group, history_state, Callable())
	if premove_state_machine.current_state == "stop":
		premove_state_machine.change_state.call_deferred("start")

func state_ready_waiting() -> void:
	state_machine.state_signal_connect(engine.search_finished, state_machine.change_state.call_deferred.bind("enemy"))
	engine.stop_search()

func state_ready_move(_arg:Dictionary) -> void:
	Clock.pause()
	history_document.push_move(_arg["move"])
	history_state.push_back(chessboard.state.get_zobrist())
	if premove_state_machine.current_state == "stop":
		premove_state_machine.change_state.call_deferred("start")
	state_machine.state_signal_connect(chessboard.animation_finished, func() -> void:
		if Chess.get_end_type(chessboard.state) == ("checkmate_white" if player_group == 1 else "checkmate_black"):
			state_machine.change_state.call_deferred("enemy_win")
		elif _arg["move"] != -1 && (chessboard.state.get_bit(ord("Z")) & Chess.mask(Chess.x88_to_c64(Chess.to(_arg["move"])))):
			state_machine.change_state.call_deferred("interact", {"callback": interact_list[Chess.to(_arg["move"])][""]})
		else:
			back_to_game()
	)
	
	assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(_arg["move"]))) 
	|| Chess.from(_arg["move"]) == Chess.to(_arg["move"]) && !chessboard.state.has_piece(Chess.from(_arg["move"])))
	chessboard.execute_move(_arg["move"])

func state_ready_player(_arg:Dictionary) -> void:
	premove_state_machine.change_state("stop")
	var start_from:int = 0
	var by:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, player_group)
	for iter:int in move_list:
		start_from |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))

	state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		state_machine.change_state.call_deferred("ready_to_move", {"from": _selected})
	)
	state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		state_machine.change_state.call_deferred("interact", {"callback": interact_list[by][_selected]})
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.call_deferred.bind("enemy_win"))
	if chessboard.state.get_bit(enemy_all):
		Clock.resume()
	var selection:PackedStringArray = []
	if chessboard.state.get_bit(ord("z")) & Chess.mask(Chess.x88_to_c64(by)):
		selection = interact_list[by].keys()
		Dialog.push_selection(selection, title.get(by, ""), false, false)
	chessboard.set_square_selection(start_from)

func state_exit_player() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_ready_to_move(_arg:Dictionary) -> void:
	premove_state_machine.change_state.call_deferred("stop")
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, player_group)
	var square_selection:int = 0
	var from:int = _arg["from"]
	if !chessboard.state.has_piece(from):
		state_machine.change_state("player")
		return
	var actor:Actor = chessboard.chessboard_piece[from]
	for iter:int in move_list:
		if Chess.from(iter) == from:
			square_selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	if square_selection == 0:
		state_machine.change_state.call_deferred("player")
		return
	state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		state_machine.change_state.call_deferred("check_move", {"from": from, "to": _selected})
	)
	state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		actor.idle()
		state_machine.change_state.call_deferred("player", {"from_last": from})
	)
	state_machine.state_signal_connect(chessboard.selection_hold, func (_selected:int) -> void:
		state_machine.change_state.call_deferred("travel", {"from": _selected})
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.call_deferred.bind("enemy_win"))
	state_machine.state_signal_connect(Dialog.on_select, func(selected) -> void:
		actor.idle()
		state_machine.change_state.call_deferred("interact", {"callback": interact_list[from][selected]})
	)
	var interact_selection:PackedStringArray = []
	if chessboard.state.get_bit(ord("z")) & Chess.mask(Chess.x88_to_c64(from)):
		interact_selection = interact_list[from].keys()
	Dialog.push_selection(interact_selection, "", false, false)
	actor.ready_to_move()
	chessboard.set_square_selection(square_selection)

func state_exit_ready_to_move() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_travel(_arg:Dictionary) -> void:
	premove_state_machine.change_state.call_deferred("stop")
	var from:int = _arg["from"]
	var actor:Actor = chessboard.chessboard_piece[from]
	var path:PackedInt32Array = Chess.generate_path(chessboard.state, from)
	var bit:int = 0
	for i:int in path.size():
		if path[i] != -1:
			bit |= Chess.mask(i)
	state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		actor.idle()
		state_machine.change_state("player")
	)
	state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		var to:int = _selected
		var iter:int = to
		var path_to:PackedInt32Array = []
		while (iter != from):
			path_to.push_back(Chess.create(path[Chess.x88_to_c64(iter)], iter, 0))
			iter = path[Chess.x88_to_c64(iter)]
			chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), iter)
			if iter == -1:
				actor.idle()
				state_machine.change_state.call_deferred("player")
				chessboard.clear_pointer("premove")
				return
		if !path_to.size():
			actor.idle()
			state_machine.change_state.call_deferred("player")
			chessboard.clear_pointer("premove")
			return
		var first_move:int = path_to[-1]
		path_to.resize(path_to.size() - 1)
		path_to.reverse()
		premove_branch.move_order = path_to
		premove_branch.future_state = chessboard.state.duplicate()
		Chess.apply_move(premove_branch.future_state, first_move)
		for move:int in path_to:
			Chess.apply_move(premove_branch.future_state, move)
		state_machine.change_state.call_deferred("check_move", {"from": Chess.from(first_move), "to": Chess.to(first_move)})
	)
	state_machine.state_signal_connect(Dialog.on_select, func(_selected:String) -> void:
		actor.idle()
		state_machine.change_state.call_deferred("player")
	)

	Dialog.push_selection(["SELECTION_CANCEL"], "", false, false)
	chessboard.set_square_selection(bit)

func state_exit_travel() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, player_group)
	if _arg.has("from"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["from"] == Chess.from(move))
	if _arg.has("to"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["to"] == Chess.to(move))
	if _arg.has("extra"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["extra"] == Chess.extra(move))
	if move_list.size() == 0:
		if premove_branch.move_order:
			premove_branch.move_order.clear()
			premove_branch.future_state = chessboard.state.duplicate()
		state_machine.change_state.call_deferred("player", {})
		return
	elif move_list.size() > 1:
		state_machine.change_state.call_deferred("extra_move", {"from": from, "to": to, "move_list": move_list})
	else:
		state_machine.change_state.call_deferred("move", {"move": move_list[0]})

func state_ready_extra_move(_arg:Dictionary) -> void:
	premove_state_machine.change_state.call_deferred("stop")
	var map:Dictionary = {
		ord("Q"): "PIECE_QUEEN",
		ord("R"): "PIECE_ROOK",
		ord("B"): "PIECE_BISHOP",
		ord("N"): "PIECE_KNIGHT",
		ord("q"): "PIECE_QUEEN",
		ord("r"): "PIECE_ROOK",
		ord("b"): "PIECE_BISHOP",
		ord("n"): "PIECE_KNIGHT",
	}
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	var from:int = _arg["from"]
	var actor:Actor = chessboard.chessboard_piece[from]
	for iter:int in _arg["move_list"]:
		decision_list.push_back(map[Chess.extra(iter)])
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("SELECTION_CANCEL")
	state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		if _selected == "SELECTION_CANCEL":
			actor.idle()
			state_machine.change_state.call_deferred("player")
		else:
			state_machine.change_state.call_deferred("move", {"move": decision_to_move[_selected]})
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.call_deferred.bind("enemy_win"))
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, false)

func state_ready_player_win(_arg:Dictionary) -> void:
	history_document.save_file()
	Progress.set_value("time_left", Clock.get_time_left())
	var bit:int = chessboard.state.get_bit(enemy_all)
	while bit:
		chessboard.state.capture_piece(Chess.c64_to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.c64_to_x88(Chess.first_bit(bit))].captured()
		bit = Chess.next_bit(bit)
	state_machine.state_signal_connect(Dialog.on_next, state_machine.change_state.call_deferred.bind("player"))
	Progress.accumulate("wins", 1)
	Dialog.push_dialog("HINT_YOU_WIN", "", true, true)

func state_ready_enemy_win(_arg:Dictionary) -> void:
	history_document.save_file()
	var by:int = Chess.c64_to_x88(Chess.first_bit($chessboard.state.get_bit(player_king)))
	chessboard.state.capture_piece(Chess.c64_to_x88(by))
	#chessboard.chessboard_piece[Chess.c64_to_x88(by)].captured()
	state_machine.state_signal_connect(Dialog.on_next, Loading.reset_scene)
	Dialog.push_dialog("HINT_YOU_LOSE", "", true, true)

func state_ready_draw(_arg:Dictionary) -> void:
	history_document.save_file()
	var bit:int = chessboard.state.get_bit(enemy_all)
	while bit:
		chessboard.state.capture_piece(Chess.c64_to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.c64_to_x88(Chess.first_bit(bit))].leave()
		bit = Chess.next_bit(bit)
	state_machine.state_signal_connect(Dialog.on_next, back_to_game)
	Dialog.push_dialog("平局", "", true, true)

func state_ready_interact(_arg:Dictionary) -> void:
	await _arg["callback"].call()
	back_to_game.call_deferred()

func back_to_game() -> void:
	if is_queued_for_deletion():
		return
	if chessboard.state.get_turn() != player_group:
		state_machine.change_state.call_deferred("enemy")
	elif premove_branch && premove_branch.move_order.size():
		var next_premove:int = premove_branch.move_order[0]
		premove_branch.move_order.remove_at(0)
		if premove_branch.move_order.size() == 0:
			chessboard.clear_pointer("premove")
		state_machine.change_state.call_deferred("check_move", {"from": Chess.from(next_premove), "to": Chess.to(next_premove), "extra": Chess.extra(next_premove)})
	elif premove_state_machine.current_state == "to":
		state_machine.change_state.call_deferred("ready_to_move", {"from": premove_from})
	elif premove_state_machine.current_state == "travel":
		state_machine.change_state.call_deferred("travel", {"from": premove_from})
	else:
		state_machine.change_state.call_deferred("player")
