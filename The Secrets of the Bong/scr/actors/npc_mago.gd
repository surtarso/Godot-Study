extends Area2D

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

func _on_body_entered(_body: KinematicBody2D):
	mago_start_dialog()
func _on_body_exited(_body: KinematicBody2D):
	mago_end_dialog()

func mago_start_dialog():
	print("body entered")
	
func mago_end_dialog():
	print("body exited")
	anim_player.play("despawn")

