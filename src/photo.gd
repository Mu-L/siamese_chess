extends CanvasLayer

@onready var head:Node3D = $texture_rect/margin_container/sub_viewport_container/sub_viewport/head

func _ready() -> void:
	$button_close.connect("pressed", close)
	$button_shot.connect("pressed", save_photo)
	$texture_rect/margin_container/sub_viewport_container.connect("gui_input", sub_viewport_container_gui_input)
	head.get_node("camera_3d").fov = 100.0

func _physics_process(_delta:float) -> void:
	var vision_look_at:Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	head.global_rotation.y -= vision_look_at.x / 1000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].x
	head.global_rotation.x -= vision_look_at.y / 2000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].y

func sub_viewport_container_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		if !(event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		head.global_rotation.y -= event.relative.x / 20000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].x
		head.global_rotation.x += event.relative.y / 10000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].y
	elif event is InputEventScreenPinch:
		head.get_node("camera_3d").fov -= event.relative / 1000 * Setting.get_value("camera_move_speed")
		head.get_node("camera_3d").fov = clamp(head.get_node("camera_3d").fov, 30, 120)

func open() -> void:
	set_physics_process(true)
	visible = true

func close() -> void:
	set_physics_process(false)
	visible = false

func move_camera(_position:Vector3, _rotation:Vector3) -> void:
	head.global_position = _position
	head.global_rotation = _rotation

func save_photo() -> void:
	DirAccess.make_dir_absolute("user://photo/")
	DirAccess.make_dir_absolute("user://archive/")
	var texture:ViewportTexture = $texture_rect/margin_container/sub_viewport_container/sub_viewport.get_texture()
	var image:Image = texture.get_image()
	var timestamp:String = String.num_int64(Time.get_unix_time_from_system())
	image.save_png("user://photo/" + timestamp + ".png")
	var file:FileAccess = FileAccess.open("user://archive/photo." + timestamp + ".json", FileAccess.WRITE)
	var dict:Dictionary = {
		"lines": [],
		"path": "user://photo/" + timestamp + ".png"
	}
	file.store_string(JSON.stringify(dict))
	file.close()
