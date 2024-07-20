extends Attack

@export var flash_component: HitFlashComponent

@export var stomp_sound: AudioStream

@export var charge_time: float = 2
@export var radius: float = 50
@export var knockback_force: int = 100
@export var damage: int = 4
@export var duration: float = 0.1

var charge_timer: SceneTreeTimer
var flash_timer: SceneTreeTimer

func _ready():
	var timer = get_tree().create_timer(3)
	timer.timeout.connect(_finish_cooldown)
	$HitboxComponent.contact_damage = damage
	$KnockbackComponent.knockback_force = knockback_force
	
	var shape = CircleShape2D.new()
	shape.radius = radius
	$HitboxComponent/CollisionShape2D.shape = shape
	$KnockbackComponent/CollisionShape2D.shape = shape
	set_collision_disabled(true)
	
	attack_completed.connect(func(): set_collision_disabled(true))
	
func _process(_delta):
	if not attacking:
		return

func execute(target: Node2D):
	if not can_attack:
		return
	
	attacking = true
	can_attack = false
	charge_timer = get_tree().create_timer(charge_time)
	charge_timer.timeout.connect(_shockwave)
	_flash(0.4)
	
func _flash(time: float):
	if not attacking:
		return
		
	flash_component.flash()
	
	var next_flash_time = (time * 0.8)
	if charge_timer.time_left > (flash_component.flash_time * 2) + next_flash_time:
		flash_timer = get_tree().create_timer(flash_component.flash_time + next_flash_time)
		flash_timer.timeout.connect(func(): _flash(next_flash_time))
	
func _shockwave():
	if not attacking:
		return
		
	$SoundPlayer.play_sound(stomp_sound, 0)
	$ShockwaveParticles.emitting = true
	set_collision_disabled(false)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(_complete_attack)
	
func set_collision_disabled(disabled: bool):
	$HitboxComponent/CollisionShape2D.set_deferred("disabled", disabled)
	$KnockbackComponent/CollisionShape2D.set_deferred("disabled", disabled)
	
