class_name Item
extends Area2D

onready var tween = $Area2D/Tween

var value
var is_sucking:bool = false

func _process(_delta):
	self.position.y += 1
	self.position.x += lerp(rand_range(-3,-1),rand_range(1,3),0.5)
	
	if is_sucking and tween != null: #follow player position
		tween.interpolate_property(
			self,"position",
			self.position,Globals.player.global_position,
			0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
	
	if self.position.y > Globals.stage.stage_height + 32: #remove on screen end
		set_process(false)
		call_deferred("queue_free")

func _on_SuckArea_body_entered(body): #player gets close enought
	if body.is_in_group("player"):
		is_sucking = true

func _on_ItemDrop_body_entered(body): #item reaches player
	set_process(false)
	if body.is_in_group("player"):
		body._picked_item(name,value)
		call_deferred("queue_free")
