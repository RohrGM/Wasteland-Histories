extends KinematicBody2D

onready var fork = preload("res://Farm/farm_fork.png")
onready var s12 = preload("res://Farm/farm_12.png")
onready var none = preload("res://Farm/farm.png")
onready var bullet : PackedScene = preload("res://PackedScene/Bullet.tscn")

const ACCELERATION : int = 550
const MAX_SPEED : int = 50
const FRICTION : int = 20000

var velocity : Vector2 = Vector2.ZERO
var weapons : Array = [0]
var enemys = []

var items : Dictionary = {
	"fork" : false,
	"s12" : false,
	"12a" : 0,
}

func _physics_process(delta) -> void:
	var input_vector : Vector2 = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	$Range.look_at(get_global_mouse_position())
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		update_anim_tree(input_vector)
		travel_anim("Run")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		travel_anim("Idle")
	
	velocity = move_and_slide(velocity)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("attack") and weapons[0] != 0:
		attack()
	if Input.is_action_just_pressed("change_weapon"):
		weapons.push_back(weapons.pop_front())
		update_weapon()
				
func update_weapon() -> void:
	match weapons[0]:
		0:
			$Sprite.texture = none
		1: 
			$Sprite.texture = fork
		2: 
			$Sprite.texture = s12
		
func update_anim_tree(vector : Vector2) -> void:
	$AnimationTree.set("parameters/Idle/blend_position", vector)
	$AnimationTree.set("parameters/Run/blend_position", vector)
	$AnimationTree.set("parameters/Attack/blend_position", vector)
	$AnimationTree.set("parameters/Shoot/blend_position", vector)

func travel_anim(anim : String) -> void:
	$AnimationTree.get("parameters/playback").travel(anim)
	
func attack_hit() -> void:
	if enemys.size() > 0:
		enemys[0].dead()

func attack() -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = get_global_mouse_position().x - position.x
	input_vector.y = get_global_mouse_position().y - position.y
	
	update_anim_tree(input_vector.normalized())
	
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	if weapons[0] == 1:
		travel_anim("Attack")
	else:
		travel_anim("Shoot")
		
func shoot() -> void:
	if weapons[0] == 2:
		$Range/Particles2D.emitting = true
		spaw_b(100)
		spaw_b(50)
		spaw_b(0)
		spaw_b(-50)
		spaw_b(-100)		
		
func spaw_b( value : int = 0) -> void:
	var bullet_inst : RigidBody2D = bullet.instance()
	bullet_inst.position = $Range/BSpaw.global_position
	bullet_inst.rotation_degrees = $Range.rotation_degrees 
	bullet_inst.apply_impulse(Vector2(), Vector2(300, 0).rotated($Range.rotation + value))
	get_parent().add_child(bullet_inst)
		
func for_idle() -> void:
	travel_anim("Idle")
	set_physics_process(true)

func add_item(value : String) -> void:
	items[value] = true
	
	match value:
		"fork":
			weapons.push_front(1)
			update_weapon()
			$CanvasLayer/Ballon.ballon_text("Vem pro pai!")
		"s12":
			weapons.push_front(2)
			update_weapon()
			$CanvasLayer/Ballon.ballon_text("Agora sim!")

func player(value : bool) -> void:
	set_physics_process(value)
	set_process_unhandled_input(value)
	travel_anim("Idle")

func set_cam(zoom : Vector2) -> void:
	$Tween.interpolate_property($Camera2D, "zoom", $Camera2D.zoom, zoom , .5,Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()

func _on_RangeMelee_area_entered(area):
	enemys.append(area.get_parent())

func _on_RangeMelee_area_exited(area):
	if area.get_parent() in enemys:
		enemys.erase(area.get_parent())