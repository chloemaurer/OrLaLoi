extends Sprite2D

var icons = [preload("uid://bh2fl2jexuv11"),preload("uid://bigj6xlc0devs"),preload("uid://b01lqf5jf531"),
preload("uid://cm7m7l86ey38f"),preload("uid://dmhx8f5xybayy"),preload("uid://dromh00wukg7r"),
preload("uid://by34fmmkfdae3"),preload("uid://civ1gsrq8j33m"),preload("uid://du742y314x7w0")]
@onready var screen: Node2D = $"../Screen"
@onready var code: Node2D = $"../Code"
@onready var back: Button = $"../Actions/Back"


var current_index := 0

func _ready():
	for node in code.get_children():
		if node is Button:
			node.pressed.connect(_on_key_pressed.bind(node))
	back.pressed.connect(_on_back_pressed)

func _on_key_pressed(button: Button):
	var keypressed = int(button.name)
	var keyicon = icons[keypressed - 1]
	var key := screen.get_child(current_index)
	if current_index <= 3:
		key.texture = keyicon
		current_index += 1
	
func _on_back_pressed():
	if current_index <= 0:
		return
	current_index -= 1
	var key: Sprite2D = screen.get_child(current_index)
	key.texture = null
	
