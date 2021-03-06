# jvgd/AI/Enemy/EnemyAbility
extends "res://jvgd/Engine/AI/Enemy/EnemyAbility.gd"

enum Move_Direction { LEFT, RIGHT }

# EXPORT ==============================
export var gravity = 900
export var run_speed = 250 # pixels/sec
export var slope_slide_stop = 25.0
export(NodePath) var movement_sound_manager
export(int) var damage_target_on_contact = 0
export(bool) var change_direction_when_colliding = true
export(int) var number_of_collision_raycasts = 1
export(int) var collision_distance = 50


# CONSTANT ============================
const TargetGroup = preload("res://jvgd/Engine/Common/TargetGroup.gd")
const RaycastsGenerator = preload("res://jvgd/Engine/Helper/RaycastsGenerator.gd")
const FLOOR_NORMAL = Vector2(0, -1)
const SIDING_CHANGE_SPEED = 10
const MIN_ON_AIR_TIME = 0.05
const COLLISION_RAY_GAP = 10
const COLLISION_RAY_Y = 0



# CACHING =============================
onready var a_torso = get_controller().get_agent_torso()


# VARIABLES ===========================
var linear_vel = Vector2()
var on_air_time = 0
var on_floor = false
var max_jump = false
var current_jump_count = 0
var has_jumped = false
var gravity_vel = Vector2(0, gravity)
var current_animation
var raycast_generator
var is_turning_around = false
var moving_direction


func _ready():
	moving_direction = get_controller().get_agent_initial_facing_direction()
	
	if damage_target_on_contact < 0:
		damage_target_on_contact = 0
	
	if movement_sound_manager:
		sound_manager = get_agent().get_node(movement_sound_manager)

	if change_direction_when_colliding:
		var ray_x = abs(collision_distance)
		
		if get_controller().get_agent_initial_facing_direction() == "left":
			ray_x *= -1

		raycast_generator = RaycastsGenerator.new()
		raycast_generator.set_target_instance(get_agent())
		raycast_generator.generate(number_of_collision_raycasts, ray_x, COLLISION_RAY_Y, COLLISION_RAY_GAP)


func _physics_process(delta):
	var agent = get_agent()

	#increment counters
	on_air_time += delta
	
	
	### MOVEMENT ###
	
	# Apply Gravity
	linear_vel += delta * gravity_vel
	
	# Move
	linear_vel = agent.move_and_slide(linear_vel, FLOOR_NORMAL, slope_slide_stop)
	
	# Detect floor
	if agent.is_on_floor():
		on_air_time = 0
		
	on_floor = on_air_time < MIN_ON_AIR_TIME

	
	# Horizontal movement
	var target_speed = 0
	if moving_direction == "left":
		target_speed += -1
	elif moving_direction == "right":
		target_speed += 1


	target_speed *= run_speed
	linear_vel.x = lerp(linear_vel.x, target_speed, 0.1)



	### ANIMATION ###
	var new_animation = "idle"
	
	if on_floor:
		if linear_vel.x < -SIDING_CHANGE_SPEED or linear_vel.x > SIDING_CHANGE_SPEED:
			new_animation = "run"

		# TODO: make this block of code nicer
		if get_controller().get_agent_initial_facing_direction() == "right":
			if linear_vel.x < -SIDING_CHANGE_SPEED:
				a_torso.scale.x = -1
				controller.set_agent_data("flip_horizontal", true)
				
			if linear_vel.x > SIDING_CHANGE_SPEED:
				a_torso.scale.x = 1
				controller.set_agent_data("flip_horizontal", false)

		elif get_controller().get_agent_initial_facing_direction() == "left":
			if linear_vel.x < -SIDING_CHANGE_SPEED:
				a_torso.scale.x = 1
				controller.set_agent_data("flip_horizontal", false)
			if linear_vel.x > SIDING_CHANGE_SPEED:
				a_torso.scale.x = -1
				controller.set_agent_data("flip_horizontal", true)

	else:
		if linear_vel.y < 0:
			new_animation = "jump"
		else:
			new_animation = "fall"

	if new_animation != current_animation:
		current_animation = new_animation
		controller.play_agent_animation(new_animation)
		
	
	### COLLISION DETECTION ###
	if change_direction_when_colliding and detect_collision():
		turn_around()


func detect_collision():
	for ray in raycast_generator.rays:
		if ray.is_colliding():
			var collider = ray.get_collider()
			var has_hit_damagable_target = TargetGroup.is_target_in_groups(collider, get_target_groups())

			if has_hit_damagable_target:
				if damage_target_on_contact > 0:
					TargetGroup.damage_target(collider, damage_target_on_contact)
				return null
			else:
				if collider and (TargetGroup.is_in_platform_group(collider) or TargetGroup.is_in_destructible_group(collider)):
					return collider
	return null


func turn_around():
	if moving_direction == "left":
		moving_direction = "right"
	elif moving_direction == "right":
		moving_direction = "left"
	raycast_generator.flip_rays()
	get_controller().set_agent_data("moving_direction", moving_direction)
	get_controller().broadcast_status("flip_horizontal")


# DEBUG ===================================
func _draw():
	if get_debug():
		if change_direction_when_colliding:
			var ray_x = abs(collision_distance)
	
			if get_controller().get_agent_initial_facing_direction() == "left":
				ray_x *= -1
			raycast_generator.draw_debug_lines(self, number_of_collision_raycasts, ray_x, COLLISION_RAY_Y, COLLISION_RAY_GAP)
