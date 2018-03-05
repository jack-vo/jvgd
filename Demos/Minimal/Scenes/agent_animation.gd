extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("face").play("idle")
	get_node("body").play("idle")
	get_node("arms-right").play("idle")
	get_node("arms-left").play("idle")
	get_node("legs-left").play("idle")
	get_node("legs-right").play("idle")

