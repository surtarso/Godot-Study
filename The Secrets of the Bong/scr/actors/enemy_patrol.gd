extends AudioStreamPlayer2D


func _process(_delta):
	if not self.playing: self.play()
