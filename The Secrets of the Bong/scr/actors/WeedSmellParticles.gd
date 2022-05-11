extends CPUParticles2D
"""
Toggles emitting of WEED LEAF particles if PLAYER has WEED
"""

func _process(_delta):
	self.emitting = true if PlayerData.has_weed else false
