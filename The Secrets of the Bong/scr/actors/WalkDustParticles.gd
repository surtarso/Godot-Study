extends CPUParticles2D
"""
Toggles emitting of DUST particles if PLAYER WALKS
"""
onready var player = get_node("../..")

func _process(_delta):
	self.emitting = true if player.current_speed != 0 and not player.is_jumping else false
