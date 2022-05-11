extends Area2D

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

func _on_body_entered(_body): #if player hits coffee
	anim_player.play("destroy") #remove coffee
	
	if PlayerData.coffee < 3: #and if player has less than 3
		PlayerData.coffee += 1 #receive one
		$coffee_grab.play()
		
	else: #if player has 3
		PlayerData.has_coffee_overdose = true  #overdose
		$coffee_sip.play()
	
