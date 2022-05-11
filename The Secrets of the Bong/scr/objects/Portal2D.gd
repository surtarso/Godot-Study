extends Area2D
"""
Controls PORTAL to be VISIBLE when PLAYER has WEED + LIGHTER + BONG
Teleports PLAYER to PACKEDSCENE(inspector)
"""
onready var player = get_parent().get_node("Player")
onready var anim_player: AnimationPlayer = $AnimationPlayer
export var next_scene: PackedScene


func _process(_delta):
	if PlayerData.has_lighter and PlayerData.has_weed and PlayerData.has_bong:
		self.visible = true

	else:
		self.visible = false
		
	if not anim_player.is_playing():
		anim_player.play("bounce")

func _on_body_entered(_body: KinematicBody2D):
	teleport()

func teleport():
	if self.visible:
		player.set_physics_process(false)
		anim_player.play("fade_out")
		yield(anim_player, "animation_finished")
		
		var error_code = get_tree().change_scene_to(next_scene)
		if error_code != 0:
			print("ERROR: ", error_code)
