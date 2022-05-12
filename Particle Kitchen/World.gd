extends Node2D


onready var children: = $Particles

export(Array,PackedScene) var particles

const MAX_PARTICLE_COUNT:int = 700

var choice:int = 0
var count:int = 0

func _ready():
	$Label/LineEdit.text = str(MAX_PARTICLE_COUNT)
	$Label/LineEdit.grab_focus()

func _physics_process(_delta):
	
	if Input.is_action_pressed("mouse_1"): # and $Particles.get_child_count() < int($Label/LineEdit.text):
		var p = particles[choice].instance()
		p.set_deferred("position", get_global_mouse_position())
		children.call_deferred("add_child", p) #add_child(p)
		count += 1
	
	if children.get_child_count() > int($Label/LineEdit.text): #MAX_PARTICLE_COUNT:
		children.call_deferred("remove_child", children.get_children()[0])
		count -= 1
	
	$Label.text = "Particles: %s of" % count

func _unhandled_input(_event):
	
	if Input.is_action_just_released("mouse_2"): #change particles
		if choice < particles.size() - 1:
			self.set_deferred("choice", choice + 1) #choice += 1
		else: self.set_deferred("choice", 0)
	
	if Input.is_action_just_pressed("mouse_3"): #remove all particles
		for child in children.get_children():
			children.call_deferred("remove_child", child) #remove_child(child)
		count = 0
	
	if Input.is_action_just_pressed("ui_cancel"): #quit
		get_tree().quit()
