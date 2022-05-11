extends CPUParticles2D
"""
Toggles emitting of SMOKE particles if PLAYER has LIGHTER + ROACH or LIGHTER + WEED and BONG
Positions GLOW and PARTICLES relative JOINT/ROACH
"""
onready var glow = get_node("Light2D")
onready var player = get_node("../..")

func _process(_delta):
	
	#emit and glow if blowsmoke skill conditions are satisfied
	self.emitting = true if PlayerData.has_lighter and (PlayerData.roaches != 0 or (PlayerData.has_weed and PlayerData.has_bong)) else false
	glow.enabled = true if PlayerData.has_lighter and (PlayerData.roaches != 0 or (PlayerData.has_weed and PlayerData.has_bong)) else false
	
	#center the glow to self
	glow.position = self.position.normalized()
	
	#particles positioning relative to player motion
	if player.current_speed == 0:
		self.position = Vector2(0,-25)
	if player.current_speed > 0:
		self.position = Vector2(20,-23)
	if player.current_speed < 0:
		self.position = Vector2(-20,-23) #particle position on top of joint
