extends Area2D

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

func _on_body_entered(_body):
	PlayerData.has_weed = true
	$weed_grab.play()
	anim_player.play("destroy") ## queues free in animation
