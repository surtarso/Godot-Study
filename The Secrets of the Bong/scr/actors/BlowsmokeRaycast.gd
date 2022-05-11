extends RayCast2D
"""
SMOKE BLOW RADIUS (AREA OF EFFECT):
controls the RAYCAST relative to MOUSE POSITION
LIMITS raycast to MAX DISTANCE
""" 
#reference to player
onready var player = get_node("../..")
onready var blow_particles = get_node("../../Particles/BlowSmoke")
onready var aim_icon = get_node("../../Particles/AimParticles")
##desired radius
var max_blow_distance = 80

func _process(_delta):
	##player position
	var player_position: Vector2 = (player.global_position - global_position).normalized()
	##vector from player to cursor
	var player_to_cursor: Vector2 = get_local_mouse_position() - player_position
	##normalize to get direction
	var blow_direction: Vector2 = player_to_cursor.normalized()
	##multiply direction by radius
	var cursor_vector: Vector2 = blow_direction * max_blow_distance
	##add cursor_vector to player position for final position
	var final_position: Vector2 = player_position + cursor_vector

	self.position = blow_particles.position #position the raycast relative to the blow smoke particles
	self.cast_to = final_position #cast raycast to mouse position
	blow_particles.rotation = self.cast_to.angle() #rotate blow particles relative to raycast angle
	aim_icon.position = self.position + cursor_vector #places aim icon position relative to raycast
