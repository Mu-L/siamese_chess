extends Actor

@export var direction:Vector3 = Vector3(0, 0, 0)
var state_machine:StateMachine = null

func _ready() -> void:
	state_machine = StateMachine.new()
	add_child(state_machine)

func _physics_process(_delta:float) -> void:
	state_machine.process(_delta)	# 由于生命周期限制，最好在这里调用状态的process方法
	move_and_slide()

func state_ready_idle(_arg:Dictionary) -> void:
	pass

func state_process_idle(_delta:float) -> void:
	velocity = Vector3(0, 0, 0)

func state_ready_move(_arg:Dictionary) -> void:
	pass

func state_process_move(_delta:float) -> void:
	velocity = direction
	if get_last_slide_collision():
		state_machine.change_state("evade")

func state_ready_evade(_arg:Dictionary) -> void:
	pass

func state_process_evade(_delta:float) -> void:
	pass
