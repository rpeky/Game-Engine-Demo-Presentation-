extends CharacterBody2D

@export var speed := 180.0
var active := false

func set_active(v: bool) -> void:
	active = v

func _physics_process(delta):
	if not active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if Input.is_action_pressed("move_fwd"):
		dir.y -= 1
	if Input.is_action_pressed("move_back"):
		dir.y += 1
	dir = dir.normalized()

	velocity = dir * speed
	move_and_slide()
