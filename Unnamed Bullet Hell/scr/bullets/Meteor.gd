extends Node2D

export var damage:int = 2

func _ready():
	$AnimationPlayer.play("default")

## - follows player position
func _process(_delta):
	if Globals.player != null:
		$Tween.interpolate_property(
			self,"position",
			self.position,Globals.player.global_position,
			1.8,Tween.TRANS_LINEAR,Tween.EASE_OUT
		)
		$Tween.start()

## - friendly fire
func _on_Meteor_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("enemies"):
		body._got_hit(damage)


## - destroys/clear bullets in area
func _on_Meteor_area_entered(area):
	if not area.is_in_group("item"):
		area.queue_free()
