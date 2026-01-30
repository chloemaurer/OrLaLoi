extends Node3D

@onready var faces: Node3D = $faces

var finalnumber := 0

func get_number():
	var lowest_y :=  INF
	var number
	
	for node in faces.get_children():
		var y_value = node.global_position.y
		
		if not lowest_y || y_value < lowest_y:
			lowest_y = y_value
			number = int(node.name)
		
	return number
	
	
