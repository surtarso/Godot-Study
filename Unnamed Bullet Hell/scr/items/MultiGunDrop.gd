extends Item


func _ready():
	value = true

func _physics_process(_delta):
	self.rotate(0.15)
