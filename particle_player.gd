extends Node
class_name ParticlePlayer

func play_particle(particle: PackedScene, position: Vector2, direction: Vector2 = Vector2.ZERO):
	var created = particle.instantiate() as CPUParticles2D
	created.global_position = position
	created.direction = direction
	get_tree().get_root().add_child(created)
	created.emitting = true
	
	created.finished.connect(func(): created.queue_free())
	
