extends Area2D

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

func _on_body_entered(_body):
	PlayerData.has_bong = true
	$bong_sound.play() #no sound yet
	anim_player.play("destroy")
