extends CanvasLayer
class_name UI

signal start_game_requested()

func _ready():
	_disabled_screenflash()
	$StartButton.show()
	$GameOverLabel.hide()

func set_health(current: int, max: int):
	$Healthbar.set_health(current, max)
		
func screen_flash(intensity: float, time: float):
	var shader_material = $ScreenFlash.material as ShaderMaterial
	shader_material.set_shader_parameter("intensity", intensity)
	
	var timer = get_tree().create_timer(time)
	timer.timeout.connect(_disabled_screenflash)
	
func _disabled_screenflash():
	var shader_material = $ScreenFlash.material as ShaderMaterial
	shader_material.set_shader_parameter("intensity", 0)

func screen_flash_on_damage(_damage: int):
	screen_flash(0.8, 0.1)

func _on_main_player_spawned(player: Player):
	player.damage_received.connect(screen_flash_on_damage)
	player.health_changed.connect(set_health)
	
func _on_start_button_pressed():
	start_game_requested.emit()
	$StartButton.hide()
	$GameOverLabel.hide()

func show_game_over():
	$GameOverLabel.show()
	$StartButton.text = "Restart"
	$StartButton.show()
