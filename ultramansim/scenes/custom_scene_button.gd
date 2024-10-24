extends Button

signal button_hovered(action) 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	self.mouse_entered.connect(_on_button_mouse_entered)
	pass # Replace with function body.

func _on_button_mouse_entered() -> void:
	button_hovered.emit("scene_entered")
	
func _on_button_mouse_exited() -> void:
	button_hovered.emit("scene_exited")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
