extends Node

var pitch_randomness = 0.15

func play_sound(sound: AudioStream, volume: float) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.stream = sound
	player.pitch_scale = 1 + randf_range(-pitch_randomness, pitch_randomness)
	player.finished.connect(func(): player.queue_free())
	player.volume_db = volume
	add_child(player)
	player.play()
	
	return player
	

