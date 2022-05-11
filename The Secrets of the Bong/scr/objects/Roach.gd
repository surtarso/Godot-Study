extends Area2D

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

var score: = 420 # "value" of a roach

func _on_body_entered(_body):
	PlayerData.roaches += 1
	PlayerData.score += score
	$roach_grab.play()
	anim_player.play("destroy")
