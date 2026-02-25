extends CharacterBody3D


@export var speed := 6.0
@export var jump_velocity := 5.5
@export var mouse_sens := 0.002

var active := true
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float

@onready var cam: Camera3D = $Camera3D
@onready var ray: RayCast3D = $RayCast3D

var yaw := 0.0
var pitch := 0.0

func _ready():
	cam.current = true
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_active(v: bool) -> void:
	active = v
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if not active:
		return

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, deg_to_rad(-75), deg_to_rad(75))
		rotation.y = yaw
		cam.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not active:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	# Movement input 
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("move_fwd"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var basis := global_transform.basis
	var move_dir := (basis.x * input_dir.x) + (basis.z * input_dir.z)
	move_dir.y = 0
	move_dir = move_dir.normalized()

	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	move_and_slide()

	# Interact
	if Input.is_action_just_pressed("interact"):
		try_interact()

func try_interact():
	if not ray.is_colliding():
		print("RayCast: not colliding")
		return

	var collider := ray.get_collider()
	if collider == null:
		print("RayCast: collider is null")
		return

	var n := collider as Node
	print("RayCast hit:", n.name)

	# Look for a child node literally named "togglescript"
	var marker := n.get_node_or_null("togglescript")
	if marker == null:
		print("No child named 'togglescript' under:", n.name)
		return

	if marker.has_method("interact"):
		marker.call("interact")
		print("called interact() on togglescript")
	else:
		print("'togglescript' has no interact()")
