extends Area2D

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

func _on_body_entered(_body):
	if not PlayerData.got_suit:
		PlayerData.got_suit = true
		anim_player.play("destroy") # queue free in animation
