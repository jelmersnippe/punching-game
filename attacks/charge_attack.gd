extends Attack

@export var velocity_component: VelocityComponent
@export var flash_component: HitFlashComponent

@export var charge_time: float = 1.5
@export var speed: float = 250
@export var distance: float = 75

var original_position: Vector2

var charge_timer: SceneTreeTimer
var flash_timer: SceneTreeTimer

func _process(_delta):
	if not attacking:
		return
	
	if global_position.distance_to(original_position) >= distance:
		_complete_attack()

func execute(target: Node2D):
	if not can_attack:
		return
	
	original_position = global_position
	attacking = true
	can_attack = false
	charge_timer = get_tree().create_timer(charge_time)
	charge_timer.timeout.connect(func(): _charge(target))
	_flash(0.3)
	
func _flash(time: float):
	if not attacking:
		return
		
	flash_component.flash()
	
	var next_flash_time = max(time - 0.1, flash_component.flash_time / 2)
	if charge_timer.time_left > (flash_component.flash_time * 2) + next_flash_time:
		flash_timer = get_tree().create_timer(flash_component.flash_time + next_flash_time)
		flash_timer.timeout.connect(func(): _flash(next_flash_time))
	
func _charge(target: Node2D):
	if not attacking or target == null:
		return
		
	var direction = global_position.direction_to(target.global_position)
	velocity_component.velocity = direction * speed
