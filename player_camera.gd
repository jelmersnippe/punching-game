extends Camera2D

var player: CharacterBody2D

func _ready():
	player = get_parent().get_node("Player")

func _physics_process(delta):
	if player != null:
		global_position = player.global_position
