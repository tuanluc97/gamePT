extends CharacterBody2D

enum Job { NONE, GOLD_MINER, WOOD_CHOPPER, BUILDER, SCOUT }
enum State { IDLE, MOVING_TO_TARGET, WORKING, RETURNING_TO_BASE, MOVING_TO_BASE_FOR_WOOD }

@export var current_job: Job = Job.SCOUT
var current_state: State = State.IDLE

@export var speed: float = 120.0
@export var build_speed: float = 12.5 
var vision_radius: float = 150.0 

var agent_radius: float = 4.0 
@export var agent_color: Color = Color.PINK 

var carried_gold: int = 0
var carried_wood: int = 0
var has_wood_for_build: bool = false

var target_gold_node: Area2D = null
var target_wood_node: Area2D = null
var target_foundation: Area2D = null
var main_base: Node2D = null

var grid_manager: Node2D = null
var current_path: Array[Vector2] = []

@onready var harvest_timer: Timer = $HarvestTimer

func _ready() -> void:
	add_to_group("workers")
	harvest_timer.timeout.connect(_on_harvest_finished)
	queue_redraw()
	
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0: main_base = bases[0]
		
	await get_tree().physics_frame
	var grids = get_tree().get_nodes_in_group("grid_manager")
	if grids.size() > 0: grid_manager = grids[0]
		
	if grid_manager and grid_manager.has_method("get_cell_center"):
		global_position = grid_manager.get_cell_center(global_position)
		
	evaluate_job()

func _draw() -> void:
	draw_circle(Vector2.ZERO, agent_radius, agent_color)

func _physics_process(delta: float) -> void:
	match current_job:
		Job.NONE: velocity = Vector2.ZERO
		Job.GOLD_MINER: _process_gold_miner_job(delta)
		Job.WOOD_CHOPPER: _process_wood_chopper_job(delta)
		Job.BUILDER: _process_builder_job(delta)
		Job.SCOUT: _process_scout_job(delta)

func request_path(target_pos: Vector2) -> void:
	if grid_manager:
		current_path = grid_manager.get_path_for_ant(global_position, target_pos)
		if current_path.size() == 0:
			print("[CẢNH BÁO] Kiến không thể tìm đường tới: ", target_pos)

func move_along_path() -> void:
	if current_path.size() == 0:
		velocity = Vector2.ZERO
		return
		
	var target_point = current_path[0]
	var dist = global_position.distance_to(target_point)
	
	if dist < 4.0:
		global_position = target_point 
		current_path.pop_front()
		velocity = Vector2.ZERO
	else:
		velocity = global_position.direction_to(target_point) * speed
		move_and_slide()
		
		# Báo lỗi nếu Kiến cạ bụng vào tường
		if get_slide_collision_count() > 0:
			var col = get_slide_collision(0).get_collider()
			if col: print("[CẢNH BÁO] Kiến đang bị kẹt vật lý vào: ", col.name)

func _process_scout_job(_delta: float) -> void:
	match current_state:
		State.IDLE:
			var random_target = global_position + Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000))
			request_path(random_target)
			if current_path.size() > 0: current_state = State.MOVING_TO_TARGET
		State.MOVING_TO_TARGET:
			move_along_path()
			_scan_for_resources()
			if current_path.size() == 0: current_state = State.IDLE
		_:
			current_state = State.IDLE

func _scan_for_resources() -> void:
	var hidden_nodes = get_tree().get_nodes_in_group("hidden_resources")
	for node in hidden_nodes:
		if is_instance_valid(node) and global_position.distance_to(node.global_position) < vision_radius:
			if node.has_method("discover"): node.discover()

func _process_gold_miner_job(_delta: float) -> void:
	match current_state:
		State.IDLE: find_gold_node()
		State.MOVING_TO_TARGET:
			if is_instance_valid(target_gold_node) and global_position.distance_to(target_gold_node.global_position) < 35.0:
				current_path.clear()
				start_harvesting()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
		State.WORKING: velocity = Vector2.ZERO
		State.RETURNING_TO_BASE:
			if main_base and global_position.distance_to(main_base.global_position) < 60.0:
				current_path.clear()
				deposit_resources()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE

func find_gold_node() -> void:
	var nodes = get_tree().get_nodes_in_group("gold_nodes")
	if nodes.size() > 0:
		target_gold_node = nodes[0] as Area2D
		if target_gold_node:
			request_path(target_gold_node.global_position)
			current_state = State.MOVING_TO_TARGET
	else:
		current_state = State.IDLE

func _process_wood_chopper_job(_delta: float) -> void:
	match current_state:
		State.IDLE: find_wood_node()
		State.MOVING_TO_TARGET:
			if is_instance_valid(target_wood_node) and global_position.distance_to(target_wood_node.global_position) < 35.0:
				current_path.clear()
				start_harvesting()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
		State.WORKING: velocity = Vector2.ZERO
		State.RETURNING_TO_BASE:
			if main_base and global_position.distance_to(main_base.global_position) < 60.0:
				current_path.clear()
				deposit_resources()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE

func find_wood_node() -> void:
	var nodes = get_tree().get_nodes_in_group("wood_nodes")
	if nodes.size() > 0:
		target_wood_node = nodes[0] as Area2D
		if target_wood_node:
			request_path(target_wood_node.global_position)
			current_state = State.MOVING_TO_TARGET
	else:
		current_state = State.IDLE

func _process_builder_job(delta: float) -> void:
	match current_state:
		State.IDLE: find_nearest_foundation()
		State.MOVING_TO_BASE_FOR_WOOD:
			if main_base and global_position.distance_to(main_base.global_position) < 60.0:
				current_path.clear()
				if main_base.has_method("use_resource") and main_base.use_resource("wood", 10):
					has_wood_for_build = true
					current_state = State.IDLE 
				else: velocity = Vector2.ZERO
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
		State.MOVING_TO_TARGET:
			if is_instance_valid(target_foundation) and global_position.distance_to(target_foundation.global_position) < 35.0:
				current_path.clear()
				current_state = State.WORKING
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
		State.WORKING:
			velocity = Vector2.ZERO
			if is_instance_valid(target_foundation): target_foundation.build(build_speed * delta)
			else:
				has_wood_for_build = false
				current_state = State.IDLE

func find_nearest_foundation() -> void:
	var nodes = get_tree().get_nodes_in_group("foundations")
	var valid_foundations: Array[Area2D] = []
	for n in nodes:
		if n is Area2D: valid_foundations.append(n as Area2D)
		elif n.get_parent() is Area2D: valid_foundations.append(n.get_parent() as Area2D)
			
	if valid_foundations.size() > 0:
		var nearest = valid_foundations[0]
		var min_dist = global_position.distance_to(nearest.global_position)
		for f in valid_foundations:
			var dist = global_position.distance_to(f.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = f
		target_foundation = nearest
		
		if not has_wood_for_build and not target_foundation.is_wood_assigned:
			target_foundation.is_wood_assigned = true
			if main_base:
				var spawn_pt = main_base.get_node_or_null("SpawnPoint")
				var target_pt = spawn_pt.global_position if spawn_pt else main_base.global_position
				request_path(target_pt)
				current_state = State.MOVING_TO_BASE_FOR_WOOD
		else:
			request_path(target_foundation.global_position)
			current_state = State.MOVING_TO_TARGET
	else:
		current_state = State.IDLE

func start_harvesting() -> void:
	current_state = State.WORKING
	velocity = Vector2.ZERO
	harvest_timer.start()

func _on_harvest_finished() -> void:
	if current_job == Job.GOLD_MINER and is_instance_valid(target_gold_node):
		if target_gold_node.has_method("harvest"): carried_gold = target_gold_node.harvest(10)
		_return_to_base()
	elif current_job == Job.WOOD_CHOPPER and is_instance_valid(target_wood_node):
		if target_wood_node.has_method("harvest"): carried_wood = target_wood_node.harvest(10)
		_return_to_base()
	else:
		current_state = State.IDLE

func _return_to_base() -> void:
	if main_base:
		var target_pt = main_base.global_position
		request_path(target_pt)
		current_state = State.RETURNING_TO_BASE
	else:
		current_state = State.IDLE

func deposit_resources() -> void:
	if main_base and main_base.has_method("add_resource"):
		if carried_gold > 0:
			main_base.add_resource("gold", carried_gold)
			carried_gold = 0
		if carried_wood > 0:
			main_base.add_resource("wood", carried_wood)
			carried_wood = 0
	current_state = State.IDLE

func set_job(new_job: Job) -> void:
	current_job = new_job
	match new_job:
		Job.WOOD_CHOPPER: agent_color = Color.CYAN
		Job.BUILDER: agent_color = Color.YELLOW
		Job.SCOUT: agent_color = Color.PINK
		Job.NONE: agent_color = Color.GRAY
		_: agent_color = Color.GREEN
	queue_redraw() 
	current_state = State.IDLE
	evaluate_job()

func evaluate_job() -> void:
	current_state = State.IDLE
	match current_job:
		Job.GOLD_MINER: find_gold_node()
		Job.WOOD_CHOPPER: find_wood_node()
		Job.BUILDER: find_nearest_foundation()
		Job.SCOUT: current_state = State.IDLE
