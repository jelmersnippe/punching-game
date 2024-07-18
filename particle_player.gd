extends Node
class_name ParticlePlayer

func play_particle(particle: PackedScene, position: Vector2, direction: Vector2 = Vector2.ZERO):
	var created = particle.instantiate() as CPUParticles2D
	created.global_position = position
	created.direction = direction
	get_tree().get_root().add_child(created)
	created.emitting = true
	
	created.finished.connect(func(): created.queue_free())
	
func play_repeating_particle(particle: PackedScene) -> CPUParticles2D:
	var created = particle.instantiate() as CPUParticles2D
	created.emitting = true
	return created
	
func stop_playing(particles: CPUParticles2D):
	particles.emitting = false
	particles.queue_free()
	
