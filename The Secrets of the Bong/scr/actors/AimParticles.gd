extends CPUParticles2D

onready var glow = get_node("AimLight")

func _process(_delta):
	self.emitting = true if PlayerData.has_lighter and (PlayerData.roaches != 0 or (PlayerData.has_weed and PlayerData.has_bong)) else false
	glow.enabled = true if PlayerData.has_lighter and (PlayerData.roaches != 0 or (PlayerData.has_weed and PlayerData.has_bong)) else false
