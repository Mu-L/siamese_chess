extends Actor

@export var direction:Vector3 = Vector3(0, 0, 0)

func _ready() -> void:
	pass

func _physics_process(_delta:float) -> void:
	# 如果碰到的是玩家控制的角色，而且在跑步过程中，那么这些角色会自动闪开
	# 如果碰到的是同类角色，那么它会往前进方向避让
	velocity = direction
	move_and_slide()
