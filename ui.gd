extends CanvasLayer
class_name UI

signal start_game_requested()

func _ready():
	_disabled_screenflash()
	$StartButton.show()
	$GameOverLabel.hide()
	
func set_wave(wave: int):
	$WaveLabel.text = "Wave " + str(wave)
	
func screen_flash(intensity: float, time: float):
	var shader_material = $ScreenFlash.material as ShaderMaterial
	shader_material.set_shader_parameter("intensity", intensity)
	
	var timer = get_tree().create_timer(time)
	timer.timeout.connect(_disabled_screenflash)
	
func _disabled_screenflash():
	var shader_material = $ScreenFlash.material as ShaderMaterial
	shader_material.set_shader_parameter("intensity", 0)

func screen_flash_on_damage(health_change: int, _current_health: int, _max_health: int):
	if health_change < 0:
		screen_flash(0.8, 0.1)

func _on_main_player_spawned(player: Player):
	player.health_component.health_changed.connect($Healthbar.set_health)
	player.health_component.health_changed.connect(screen_flash_on_damage)
	
func _on_start_button_pressed():
	start_game_requested.emit()
	$StartButton.hide()
	$GameOverLabel.hide()

func show_game_over():
	$GameOverLabel.show()
	$StartButton.text = "Restart"
	$StartButton.show()
